//! Buffer and transport utilities for `.rice` CLERK-layer code.
//!
//! This module centralizes byte-oriented operations used by protobuf framing, hashing, and
//! zero-knowledge layouts. Routines favor predictable allocation (explicit capacities), contiguous
//! storage ([`Bytes`], [`BytesMut`]), and constant-time comparisons where secrets are involved.

use bytes::{Buf, BufMut, Bytes, BytesMut};
use constant_time_eq::constant_time_eq;

use crate::error::{RiceError, RiceResult};

// ---------------------------------------------------------------------------
// Hex encoding and decoding
// ---------------------------------------------------------------------------

/// Decode a hexadecimal string into owned bytes.
///
/// **Why:** External systems (CLI, RPC, genesis files) often supply digests and keys as hex text.
/// **How:** Delegates to [`hex::decode`], which rejects odd lengths and invalid symbols; failures
/// surface as [`RiceError::Hex`] for uniform `?` handling across `base/`.
#[inline]
pub fn decode_hex(s: &str) -> RiceResult<Vec<u8>> {
    Ok(hex::decode(s)?)
}

/// Encode bytes as lowercase hexadecimal into a [`String`].
///
/// **Why:** Lowercase hex is the de-facto standard for stable, human-readable fingerprints.
/// **How:** Uses [`hex::encode`], which allocates exactly `2 * data.len()` UTF-8 code units.
#[inline]
pub fn encode_hex_lower(data: &[u8]) -> String {
    hex::encode(data)
}

/// Encode bytes as lowercase hexadecimal into a refcounted, contiguous [`Bytes`] buffer.
///
/// **Why:** When the next hop is I/O or protobuf length-delimited fields, [`Bytes`] avoids an
/// extra `String`→bytes conversion and matches the `bytes` ecosystem's buffer type.
/// **How:** Sizing `BytesMut` to `2 * len` avoids reallocations; [`hex::encode_to_slice`] fills
/// the reserved region in one pass, then the buffer is frozen into an immutable [`Bytes`].
#[inline]
pub fn encode_hex_lower_bytes(data: &[u8]) -> Bytes {
    let n = data.len().saturating_mul(2);
    let mut out = BytesMut::with_capacity(n);
    out.resize(n, 0);
    hex::encode_to_slice(data, &mut out).expect("encode_to_slice length checked");
    out.freeze()
}

/// Append lowercase hexadecimal encoding of `data` to `out`.
///
/// **Why:** Lets callers reuse a shared [`BytesMut`] arena (for example, when batching records)
/// instead of allocating a fresh buffer per value.
/// **How:** Reserves `2 * data.len()` bytes past the current length, grows the vector with zeros to
/// establish a valid slice window, encodes in place, and leaves `out.len()` advanced by the encoded
/// width.
#[inline]
pub fn encode_hex_lower_append(data: &[u8], out: &mut BytesMut) {
    let n = data.len().saturating_mul(2);
    let start = out.len();
    out.reserve(n);
    out.resize(start + n, 0);
    hex::encode_to_slice(data, &mut out[start..]).expect("encode_to_slice length checked");
}

/// Decode hex into a [`Bytes`] value backed by a single contiguous allocation.
///
/// **Why:** Downstream codecs expect [`Bytes`] for cheap cloning on the hot path.
/// **How:** Parses via [`decode_hex`], then moves the [`Vec`] into [`Bytes::from`], which takes
/// ownership without an additional copy of the payload.
#[inline]
pub fn bytes_from_hex(s: &str) -> RiceResult<Bytes> {
    Ok(Bytes::from(decode_hex(s)?))
}

// ---------------------------------------------------------------------------
// Bytes / BytesMut integration and views
// ---------------------------------------------------------------------------

/// Copy `data` into a refcounted [`Bytes`] buffer.
///
/// **Why:** Prost and tower codecs commonly consume [`Bytes`]; this is the safe bridge from any
/// borrowed slice whose lifetime does not outlive the message.
/// **How:** [`Bytes::copy_from_slice`] performs one memcpy into a fresh shared buffer.
#[inline]
pub fn bytes_from_slice(data: &[u8]) -> Bytes {
    Bytes::copy_from_slice(data)
}

/// Borrow static data as [`Bytes`] without copying.
///
/// **Why:** Compile-time constants (default parameters, embedded tables) can be exposed on the wire
/// with no allocation and no memcpy.
/// **How:** [`Bytes::from_static`] requires `'static` to guarantee the slice outlives any clone of
/// the [`Bytes`] handle.
#[inline]
pub fn bytes_from_static(data: &'static [u8]) -> Bytes {
    Bytes::from_static(data)
}

/// Return a sub-range of `buf` as a new [`Bytes`] handle sharing the same underlying allocation.
///
/// **Why:** Length-prefixed protobuf payloads and ZK witness chunks often need to alias a segment
/// without cloning bytes.
/// **How:** [`Bytes::slice`] increments the shared refcount and adjusts start/end offsets only.
#[inline]
pub fn bytes_slice(buf: &Bytes, start: usize, end: usize) -> RiceResult<Bytes> {
    if start > end || end > buf.len() {
        return Err(RiceError::invalid_argument(format!(
            "slice range {}..{} invalid for buffer length {}",
            start,
            end,
            buf.len()
        )));
    }
    Ok(buf.slice(start..end))
}

/// Freeze a mutable buffer into an immutable [`Bytes`] value.
///
/// **Why:** Encoder stages often build in [`BytesMut`] then hand off an immutable view to async
/// write paths or hashers.
/// **How:** [`BytesMut::freeze`] consumes the mutable view cheaply when no further writes occur.
#[inline]
pub fn bytes_freeze(buf: BytesMut) -> Bytes {
    buf.freeze()
}

/// Ensure `buf` can absorb at least `additional` more bytes without reallocating, when possible.
///
/// **Why:** Reserving before a tight loop of `put_slice` avoids repeated growth copies.
/// **How:** Forwards to [`BufMut::reserve`]; behavior for custom [`BufMut`] types depends on their
/// allocator strategy.
#[inline]
pub fn bytes_mut_reserve(buf: &mut BytesMut, additional: usize) {
    buf.reserve(additional);
}

// ---------------------------------------------------------------------------
// Fixed-size arrays for crypto primitives
// ---------------------------------------------------------------------------

/// Copy `data` into a stack-fixed array of length `N`.
///
/// **Why:** Many crates expose APIs taking `[u8; N]` (curve scalars, symmetric keys). Centralizing
/// the length check avoids ad-hoc `assert!`s scattered through contracts and private modules.
/// **How:** Verifies `data.len() == N`, then [`copy_from_slice`] into a zeroed array. The compiler
/// monomorphizes per `N`, so each call site pays only for the size it needs.
#[inline]
pub fn fixed_size_array<const N: usize>(data: &[u8]) -> RiceResult<[u8; N]> {
    if data.len() != N {
        return Err(RiceError::invalid_argument(format!(
            "expected exactly {} bytes for fixed array, got {}",
            N,
            data.len()
        )));
    }
    let mut out = [0u8; N];
    out.copy_from_slice(data);
    Ok(out)
}

// ---------------------------------------------------------------------------
// Constant-time comparison
// ---------------------------------------------------------------------------

/// Compare two slices for equality in constant time.
///
/// **Why:** Plain `==` on byte slices short-circuits and can leak timing information about where
/// digests or signatures first differ—useful to attackers forging MACs or padding oracles.
/// **How:** Delegates to [`constant_time_eq`], which runs in time independent of the location of
/// differing bytes when lengths match. If lengths differ, the comparison still avoids leaking the
/// common prefix of secrets by returning `false` without branching on secret content.
#[inline]
pub fn secure_compare(a: &[u8], b: &[u8]) -> bool {
    constant_time_eq(a, b)
}

// ---------------------------------------------------------------------------
// Chunking and padding (ZK / alignment)
// ---------------------------------------------------------------------------

/// Where to insert padding bytes when growing a buffer to a target length.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PadSide {
    /// Pad before the payload (`|pad|payload|`).
    Left,
    /// Pad after the payload (`|payload|pad|`).
    Right,
}

fn reject_zero_width(name: &str, width: usize) -> RiceResult<()> {
    if width == 0 {
        return Err(RiceError::invalid_argument(format!(
            "{name} must be non-zero"
        )));
    }
    Ok(())
}

/// Split `data` into consecutive chunks of `chunk_size` bytes.
///
/// **Why:** Merkle trees, lattice gadgets, and batched ZK witnesses process fixed-width rows.
/// **How:** Validates `chunk_size > 0`, then uses the standard library's [`slice::chunks`], which
/// yields all full chunks and optionally a shorter tail.
#[inline]
pub fn chunks_with_size<'a>(
    data: &'a [u8],
    chunk_size: usize,
) -> RiceResult<std::slice::Chunks<'a, u8>> {
    reject_zero_width("chunk_size", chunk_size)?;
    Ok(data.chunks(chunk_size))
}

/// Split `data` into consecutive chunks of `chunk_size`, erroring if the tail is non-empty.
///
/// **Why:** Some circuits require the input length to be an exact multiple of the lane width.
/// **How:** After validating `chunk_size`, checks `data.len() % chunk_size == 0` before returning
/// [`slice::chunks_exact`].
#[inline]
pub fn chunks_exact_or_err<'a>(
    data: &'a [u8],
    chunk_size: usize,
) -> RiceResult<std::slice::ChunksExact<'a, u8>> {
    reject_zero_width("chunk_size", chunk_size)?;
    if data.len() % chunk_size != 0 {
        return Err(RiceError::invalid_argument(format!(
            "length {} is not a multiple of chunk_size {}",
            data.len(),
            chunk_size
        )));
    }
    Ok(data.chunks_exact(chunk_size))
}

/// Pad `data` so the result has exactly `target_len` bytes.
///
/// **Why:** Field elements in ZK systems and aligned binary frames often require exact widths.
/// **How:** If `data.len() == target_len`, copies once. If shorter, allocates `target_len` bytes and
/// places `pad_byte` on the chosen [`PadSide`]. If longer, returns [`RiceError::InvalidArgument`]
/// so callers do not silently drop witness material.
#[inline]
pub fn pad_to_exact_length(
    data: &[u8],
    target_len: usize,
    pad_byte: u8,
    side: PadSide,
) -> RiceResult<Bytes> {
    match data.len().cmp(&target_len) {
        std::cmp::Ordering::Equal => Ok(Bytes::copy_from_slice(data)),
        std::cmp::Ordering::Greater => Err(RiceError::invalid_argument(format!(
            "payload length {} exceeds target_len {}",
            data.len(),
            target_len
        ))),
        std::cmp::Ordering::Less => {
            let pad_len = target_len - data.len();
            let mut out = BytesMut::with_capacity(target_len);
            out.resize(target_len, 0);
            match side {
                PadSide::Left => {
                    out[..pad_len].fill(pad_byte);
                    out[pad_len..].copy_from_slice(data);
                }
                PadSide::Right => {
                    out[..data.len()].copy_from_slice(data);
                    out[data.len()..].fill(pad_byte);
                }
            }
            Ok(out.freeze())
        }
    }
}

/// Pad `data` so its length is the smallest multiple of `multiple` that is not less than `data.len()`.
///
/// **Why:** Block-aligned witnesses and SIMD-friendly layouts often round lengths up to a stride.
/// **How:** Computes `((len + multiple - 1) / multiple) * multiple` using checked integer ops; if
/// the rounded length equals `len`, returns a copy; otherwise extends with `pad_byte` on `side`.
#[inline]
pub fn pad_to_multiple_of(
    data: &[u8],
    multiple: usize,
    pad_byte: u8,
    side: PadSide,
) -> RiceResult<Bytes> {
    reject_zero_width("multiple", multiple)?;
    let len = data.len();
    let rem = len % multiple;
    if rem == 0 {
        return Ok(Bytes::copy_from_slice(data));
    }
    let pad_len = multiple - rem;
    let target_len = len
        .checked_add(pad_len)
        .ok_or_else(|| RiceError::invalid_argument("padding length overflow"))?;
    pad_to_exact_length(data, target_len, pad_byte, side)
}

// ---------------------------------------------------------------------------
// Buf / BufMut helpers (streaming and framing)
// ---------------------------------------------------------------------------

/// Copy exactly `n` bytes from `buf` into a new [`Bytes`] value.
///
/// **Why:** Length-prefixed protobuf or CLERK framing needs to peel a payload from a stream while
/// keeping the remainder of `buf` intact.
/// **How:** Uses [`Buf::remaining`] / [`Buf::copy_to_slice`] so any [`Buf`] implementation works;
/// this performs one memcpy into a freshly allocated [`BytesMut`] of length `n`.
#[inline]
pub fn take_from_buf<B: Buf>(buf: &mut B, n: usize) -> RiceResult<Bytes> {
    if buf.remaining() < n {
        return Err(RiceError::invalid_argument(format!(
            "need {} bytes from buffer, {} available",
            n,
            buf.remaining()
        )));
    }
    let mut out = BytesMut::with_capacity(n);
    out.resize(n, 0);
    buf.copy_to_slice(&mut out);
    Ok(out.freeze())
}

/// Remove exactly `n` bytes from the front of `buf` and return them without copying the payload.
///
/// **Why:** When the source is already [`Bytes`], splitting shares the underlying arc and is the
/// lowest-latency way to hand a frame to prost.
/// **How:** [`Bytes::split_to`] adjusts internal offsets; the returned [`Bytes`] aliases the same
/// storage as `buf`.
#[inline]
pub fn bytes_split_to_front(buf: &mut Bytes, n: usize) -> RiceResult<Bytes> {
    if buf.len() < n {
        return Err(RiceError::invalid_argument(format!(
            "need {} bytes from Bytes, {} available",
            n,
            buf.len()
        )));
    }
    Ok(buf.split_to(n))
}

/// Write `data` into `buf` only if reported spare capacity can absorb it **without** reallocating.
///
/// **Why:** [`BytesMut::remaining_mut`] describes slack in the current allocation, not a hard cap;
/// this helper is meant for bounded [`BufMut`] implementations (for example wrappers that enforce
/// a maximum frame size). It returns [`Err`] when the trait reports insufficient spare bytes so
/// callers can distinguish “would grow” from “fits in the current slab”.
/// **How:** Compares [`BufMut::remaining_mut`] to `data.len()`, then [`BufMut::put_slice`].
///
/// For a [`BytesMut`] that should grow as needed, use [`put_bytes_mut`] instead.
#[inline]
pub fn try_put_slice_without_realloc<B: BufMut>(buf: &mut B, data: &[u8]) -> RiceResult<()> {
    let need = data.len();
    let cap = buf.remaining_mut();
    if cap < need {
        return Err(RiceError::invalid_argument(format!(
            "BufMut spare capacity {} is less than required {}",
            cap, need
        )));
    }
    buf.put_slice(data);
    Ok(())
}

/// Reserve at least `data.len()` bytes of capacity and append `data` to `buf`.
///
/// **Why:** Encoder hot paths should make a single explicit [`BytesMut::reserve`] decision before
/// `put_slice`, which reduces repeated growth copies under bursty protobuf serialization.
/// **How:** [`BytesMut::reserve`] then [`BufMut::put_slice`].
#[inline]
pub fn put_bytes_mut(buf: &mut BytesMut, data: &[u8]) {
    buf.reserve(data.len());
    buf.put_slice(data);
}

/// Advance `buf` by `n` bytes, mapping underflow to [`RiceError`].
///
/// **Why:** Skipping padding or reserved regions after a peek should not panic in production paths.
/// **How:** [`Buf::advance`] requires `n <= remaining`; we validate first.
#[inline]
pub fn advance_buf<B: Buf>(buf: &mut B, n: usize) -> RiceResult<()> {
    if buf.remaining() < n {
        return Err(RiceError::invalid_argument(format!(
            "cannot advance {} bytes, {} remaining",
            n,
            buf.remaining()
        )));
    }
    buf.advance(n);
    Ok(())
}
