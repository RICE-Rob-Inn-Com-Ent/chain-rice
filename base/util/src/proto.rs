//! Protobuf encode/decode helpers — the “DNA sequencer” for MASON-generated [`prost::Message`] types.
//!
//! All paths normalize failures through [`RiceError`] so contracts, private, and SMITH transport share
//! one vocabulary. Length-delimited framing matches what NATS streams and multiplexed readers expect:
//! varint size, then exactly that many payload bytes.

use core::any::type_name;

use bytes::buf::Limit as BufLimit;
use bytes::{Buf, BufMut, Bytes, BytesMut};
use prost::{decode_length_delimiter, length_delimiter_len, DecodeError, EncodeError, Message};

use crate::error::{RiceError, RiceResult};

// ---------------------------------------------------------------------------
// Error mapping (“pain model”)
// ---------------------------------------------------------------------------

#[inline]
fn map_encode<M: Message>(e: EncodeError) -> RiceError {
    RiceError::proto_encode(format!(
        "failed to encode protobuf message {}: {e}",
        type_name::<M>()
    ))
}

#[inline]
fn map_decode<M: Message>(e: DecodeError) -> RiceError {
    RiceError::ProtoDecode(e).context(format!(
        "failed to decode protobuf message {}",
        type_name::<M>()
    ))
}

#[inline]
fn map_decode_prefix(e: DecodeError) -> RiceError {
    RiceError::ProtoDecode(e).context("invalid length-delimited length prefix")
}

// ---------------------------------------------------------------------------
// Inspection
// ---------------------------------------------------------------------------

/// Returns the exact serialized size of `msg` **without** a length delimiter.
///
/// **Why:** Callers reserve buffers, size NATS frames, or validate quotas before touching I/O.
/// **How:** Forwards to [`Message::encoded_len`], which generated code implements from field layout.
#[inline]
pub fn get_encoded_len<M: Message>(msg: &M) -> usize {
    msg.encoded_len()
}

/// Returns `Some(total)` when `data` begins with a full length-delimited frame: a complete varint
/// length prefix plus `payload_len` bytes, where `total = prefix_len + payload_len`.
///
/// **Why:** SMITH and async readers need a cheap peek before committing to a decode — the organism
/// should not parse half a cell.
/// **How:** Decodes the varint prefix with [`decode_length_delimiter`] on a non-destructive view;
/// if fewer than 10 bytes are available and the prefix fails, returns `Ok(None)` (need more on the
/// wire). If 10+ bytes are present and the prefix is still invalid, returns [`Err`] with
/// [`RiceError::ProtoDecode`]. If the prefix is valid but trailing payload bytes are missing,
/// returns `Ok(None)`.
#[inline]
pub fn length_delimited_frame_byte_count(data: &[u8]) -> RiceResult<Option<usize>> {
    if data.is_empty() {
        return Ok(None);
    }
    let mut tail = data;
    let payload_len = match decode_length_delimiter(&mut tail) {
        Ok(n) => n,
        Err(e) => {
            if data.len() < 10 {
                return Ok(None);
            }
            return Err(map_decode_prefix(e));
        }
    };
    let prefix_len = data.len() - tail.len();
    let total = prefix_len.saturating_add(payload_len);
    if tail.remaining() < payload_len {
        return Ok(None);
    }
    Ok(Some(total))
}

// ---------------------------------------------------------------------------
// Encoding (exact reservation — no mid-flight growth)
// ---------------------------------------------------------------------------

/// Encodes `msg` into a [`Vec`] sized with [`Message::encoded_len`].
///
/// **Why:** Single allocation at the exact wire size keeps CLERK paths predictable under load.
/// **How:** Wraps the [`Vec`] in a [`BufMut::limit`] window so [`Message::encode`] cannot expand
/// the buffer; any spare-capacity lie from [`Vec`]'s [`BufMut`] impl cannot hide an overrun.
#[inline]
pub fn encode_to_vec<M: Message>(msg: &M) -> RiceResult<Vec<u8>> {
    let n = msg.encoded_len();
    let mut buf = Vec::with_capacity(n);
    let mut lim = (&mut buf).limit(n);
    msg.encode(&mut lim).map_err(|e| map_encode::<M>(e))?;
    debug_assert_eq!(BufLimit::limit(&lim), 0);
    drop(lim);
    Ok(buf)
}

/// Encodes `msg` into an immutable [`Bytes`] buffer of exact length.
///
/// **Why:** Downstream tower/prost code wants refcounted chunks; this avoids an extra `Vec`→`Bytes`
/// copy when the value is moved into a frame.
/// **How:** Same bounded [`limit`](BufMut::limit) pattern on a [`BytesMut`], then [`freeze`](BytesMut::freeze).
#[inline]
pub fn encode_to_bytes<M: Message>(msg: &M) -> RiceResult<Bytes> {
    let n = msg.encoded_len();
    let mut buf = BytesMut::with_capacity(n);
    let mut lim = (&mut buf).limit(n);
    msg.encode(&mut lim).map_err(|e| map_encode::<M>(e))?;
    debug_assert_eq!(BufLimit::limit(&lim), 0);
    drop(lim);
    Ok(buf.freeze())
}

/// Encodes `msg` into `buf` using exactly [`Message::encoded_len`] bytes of write budget.
///
/// **Why:** Arena-style pipelines pre-reserve one slab; this guarantees the encoder never triggers
/// implicit growth inside [`BufMut::chunk_mut`] for common backends.
/// **How:** Applies [`BufMut::limit`] around `encoded_len`; [`Message::encode`] fails fast if the
/// true spare region is smaller than prost expects.
#[inline]
pub fn encode_to_buf<M: Message, B: BufMut>(msg: &M, buf: &mut B) -> RiceResult<()> {
    let n = msg.encoded_len();
    let mut lim = (&mut *buf).limit(n);
    msg.encode(&mut lim).map_err(|e| map_encode::<M>(e))?;
    debug_assert_eq!(BufLimit::limit(&lim), 0);
    drop(lim);
    Ok(())
}

// ---------------------------------------------------------------------------
// Decoding
// ---------------------------------------------------------------------------

/// Decodes a message that occupies **all** of `data` (no length delimiter).
///
/// **Why:** `prost` build outputs map1:1 to full serialized blobs (files, single gRPC frames).
/// **How:** [`Message::decode`] merges fields into `M::default()`; errors become
/// [`RiceError::ProtoDecode`] with the Rust type name in [`RiceError::Context`].
#[inline]
pub fn decode_from_slice<M: Message + Default>(data: &[u8]) -> RiceResult<M> {
    M::decode(data).map_err(map_decode::<M>)
}

/// Decodes a message consuming the **entire** remaining view of `buf`.
///
/// **Why:** Streaming parsers keep a [`Bytes`] ring; this consumes exactly what the cursor holds.
/// **How:** Delegates to [`Message::decode`]; the buffer advances to the end on success.
#[inline]
pub fn decode_from_buf<M: Message + Default, B: Buf>(buf: &mut B) -> RiceResult<M> {
    M::decode(&mut *buf).map_err(map_decode::<M>)
}

// ---------------------------------------------------------------------------
// Length-delimited framing (NATS / multiplexed “organism signals”)
// ---------------------------------------------------------------------------

/// Encodes `msg` with a protobuf varint length prefix into a fresh [`Bytes`] value.
///
/// **Why:** SMITH multiplexes consecutive messages on one byte stream; the prefix delimits cells.
/// **How:** Reserves `length_delimiter_len(encoded_len) + encoded_len` and uses a bounded
/// [`BufMut::limit`] so [`Message::encode_length_delimited`] cannot grow the backing chunk.
#[inline]
pub fn encode_length_delimited<M: Message>(msg: &M) -> RiceResult<Bytes> {
    let len = msg.encoded_len();
    let hdr = length_delimiter_len(len);
    let total = hdr.saturating_add(len);
    let mut buf = BytesMut::with_capacity(total);
    let mut lim = (&mut buf).limit(total);
    msg.encode_length_delimited(&mut lim)
        .map_err(|e| map_encode::<M>(e))?;
    debug_assert_eq!(BufLimit::limit(&lim), 0);
    drop(lim);
    Ok(buf.freeze())
}

/// Encodes a length-delimited frame at the end of `buf`.
///
/// **Why:** Batch publishers append many frames into one [`BytesMut`] arena.
/// **How:** Same total size as [`encode_length_delimited`], applied through [`BufMut::limit`] on
/// the caller-owned mutator.
#[inline]
pub fn encode_length_delimited_to_buf<M: Message, B: BufMut>(msg: &M, buf: &mut B) -> RiceResult<()> {
    let len = msg.encoded_len();
    let hdr = length_delimiter_len(len);
    let total = hdr.saturating_add(len);
    let mut lim = (&mut *buf).limit(total);
    msg.encode_length_delimited(&mut lim)
        .map_err(|e| map_encode::<M>(e))?;
    debug_assert_eq!(BufLimit::limit(&lim), 0);
    drop(lim);
    Ok(())
}

/// Decodes one length-delimited message from `src`, advancing the cursor past the frame.
///
/// **Why:** This is the symmetric counterpart to [`encode_length_delimited`] on live streams.
/// **How:** [`Message::decode_length_delimited`] peels the varint, then merges exactly that many
/// bytes into `M::default()`.
#[inline]
pub fn decode_length_delimited<M: Message + Default, B: Buf>(src: &mut B) -> RiceResult<M> {
    M::decode_length_delimited(&mut *src).map_err(map_decode::<M>)
}
