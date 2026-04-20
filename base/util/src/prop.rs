//! [`proptest`] strategies for the CLERK / `base/` layer — reusable random generators and property
//! tests that stress [`crate::bytes`], [`crate::proto`], and [`crate::error`] invariants.
//!
//! **Why:** The “organism” should fail loudly when a transcription invariant breaks; property tests
//! turn that into repeatable evidence instead of one-off manual vectors.
//! **How:** Strategies live at module scope (not behind `cfg(test)`) so sibling crates can
//! `use util::prop::…` in their own `#[cfg(test)]` modules.

use proptest::collection::vec as vec_strategy;
use proptest::prelude::*;
use proptest::sample::select;

use bytes::{Bytes, BytesMut};

// ---------------------------------------------------------------------------
// Core byte strategies (reusable across workspace)
// ---------------------------------------------------------------------------

/// Arbitrary byte vectors with length in `0..=max_len`.
///
/// **Why:** Most CLERK property tests start from unstructured octets (digests, wire blobs).
/// **How:** Uniform `u8` over a capped length range to keep cases bounded in CI.
pub fn vec_bytes(max_len: usize) -> impl Strategy<Value = Vec<u8>> {
    vec_strategy(any::<u8>(), 0..=max_len)
}

/// Fixed-size byte array (e.g. 32-byte keys).
///
/// **Why:** Cryptographic APIs often require `[u8; N]`; this avoids manual `try_into` noise in tests.
/// **How:** Generate exactly `N` bytes and copy into a stack array.
pub fn byte_array<const N: usize>() -> impl Strategy<Value = [u8; N]> {
    vec_strategy(any::<u8>(), N).prop_map(|v| {
        let mut out = [0u8; N];
        out.copy_from_slice(&v);
        out
    })
}

/// Printable ASCII labels for human-readable test diagnostics.
///
/// **Why:** Failure messages should name what broke without binary noise.
/// **How:** Restrict to a safe charset so `String::from_utf8` is infallible.
pub fn ascii_string(max_len: usize) -> impl Strategy<Value = String> {
    const CHARSET: &[u8] = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
    vec_strategy(select(CHARSET.to_vec()), 0..=max_len).prop_map(|v| {
        String::from_utf8(v).expect("charset is ascii")
    })
}

/// Refcounted [`Bytes`] with payload length sampled from `len_range`.
///
/// **Why:** Production code paths use [`Bytes`], not only `Vec<u8>`; strategies should match.
/// **How:** Flat-map a length, then fill with arbitrary octets and freeze into [`Bytes`].
pub fn arb_bytes(len_range: impl Strategy<Value = usize>) -> impl Strategy<Value = Bytes> {
    len_range.prop_flat_map(|n| vec_strategy(any::<u8>(), n).prop_map(Bytes::from))
}

/// [`BytesMut`] containing `len` arbitrary bytes, with `capacity == len` (no implicit slack).
///
/// **Why:** Exercises append/split code that cares about cursor vs capacity.
/// **How:** `extend_from_slice` into a right-sized [`BytesMut`].
pub fn arb_bytes_mut(len_range: impl Strategy<Value = usize>) -> impl Strategy<Value = BytesMut> {
    len_range.prop_flat_map(|n| {
        vec_strategy(any::<u8>(), n).prop_map(|v| {
            let mut m = BytesMut::with_capacity(v.len());
            m.extend_from_slice(&v);
            m
        })
    })
}

/// Hex-like strings that **`hex::decode`** should reject — odd length, bad symbols, or whitespace.
///
/// **Why:** Adversarial and sloppy inputs must surface as [`crate::error::RiceError::Hex`], not panic.
/// **How:** `prop_oneof!` mixes structural violations (odd count of valid nybbles) with illegal
/// alphabets and separators.
pub fn corrupt_hex_string() -> impl Strategy<Value = String> {
    prop_oneof![
        // Strictly **odd** count of valid hex digits — `hex::decode` requires pairs.
        (0usize..=15).prop_flat_map(|k| {
            let n = 2 * k + 1;
            vec_strategy(select(b"0123456789abcdefABCDEF".to_vec()), n).prop_map(|v| {
                String::from_utf8(v).expect("hex charset is ascii")
            })
        }),
        // Even length but contains an illegal character.
        (2usize..=32).prop_flat_map(|n| {
            (
                vec_strategy(select(b"0123456789abcdefABCDEF".to_vec()), n.saturating_sub(1)),
                select(b"gGzZ \t?".to_vec()),
            )
                .prop_map(|(mut v, bad)| {
                    v.push(bad);
                    String::from_utf8(v).expect("ascii")
                })
        }),
    ]
}

// ---------------------------------------------------------------------------
// Property tests — invariants of the CLERK “organism”
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bytes::{
        bytes_slice, decode_hex, encode_hex_lower, pad_to_exact_length, secure_compare, PadSide,
    };
    use crate::error::RiceError;
    use crate::proto::{decode_length_delimited, encode_length_delimited, length_delimited_frame_byte_count};

    /// Minimal prost message carrying arbitrary bytes — stands in for MASON `gen/` types until
    /// they are linked here.
    ///
    /// **Why:** [`crate::proto`] needs a [`prost::Message`] implementation to exercise length
    /// delimiters without importing generated crates.
    /// **How:** Single `bytes` field with tag `1`; [`Default`] comes from the derive.
    #[derive(Clone, PartialEq, prost::Message)]
    struct MockWireBlob {
        #[prost(bytes = "vec", tag = "1")]
        payload: Vec<u8>,
    }

    proptest! {
        /// **Organism invariant — hex transcription:** valid lowercase hex round-trips losslessly.
        ///
        /// **Pain if broken:** Any tool that displays bytes and reads them back would silently
        /// corrupt state — the DNA sequencer lied about the sequence.
        #[test]
        fn hex_roundtrip_lowercase(data in vec_bytes(512)) {
            let hex = encode_hex_lower(&data);
            let round = decode_hex(&hex).expect(
                "CLERK hex invariant: encode_hex_lower must emit decodable hex — organism transcription failed",
            );
            prop_assert_eq!(
                round, data,
                "CLERK hex invariant: decode_hex(encode_hex_lower(x)) must equal x — payload DNA mismatch",
            );
        }

        /// **Organism invariant — padding anatomy:** when the payload fits, output is *exactly*
        /// `target_len` octets.
        ///
        /// **Pain if broken:** ZK alignment or fixed-width frames would desynchronize circuit inputs.
        #[test]
        fn pad_to_exact_length_ok_paths_are_exact(
            data in vec_bytes(128),
            target_len in 0usize..256,
            pad_byte in any::<u8>(),
            side in prop::sample::select(vec![PadSide::Left, PadSide::Right]),
        ) {
            prop_assume!(data.len() <= target_len);
            let out = pad_to_exact_length(&data, target_len, pad_byte, side).expect(
                "CLERK padding invariant: pad_to_exact_length must succeed when len(data) <= target_len",
            );
            prop_assert_eq!(
                out.len(),
                target_len,
                "CLERK padding organism: output length must equal target_len — cell grew to wrong size",
            );
        }

        /// **Organism invariant — slice boundaries:** [`bytes_slice`] never panics; it either
        /// returns the correct sub-range or [`RiceError::InvalidArgument`].
        ///
        /// **Pain if broken:** Framing code would abort the process instead of returning a typed error.
        #[test]
        fn bytes_slice_total_function(
            buf in arb_bytes(0usize..=64),
            start in 0usize..=64,
            end in 0usize..=64,
        ) {
            let len = buf.len();
            let start = start.min(len);
            let end = end.min(len);
            let res = bytes_slice(&buf, start, end);
            if start <= end && end <= len {
                let got = res.expect(
                    "CLERK slice invariant: valid ranges must succeed — organism refused valid view",
                );
                prop_assert_eq!(&got[..], &buf[start..end], "slice content must match source window");
            } else {
                let err = res.expect_err(
                    "CLERK slice invariant: invalid ranges must be RiceError, not panic",
                );
                prop_assert!(
                    matches!(err, RiceError::InvalidArgument(_)),
                    "invalid slice range must map to InvalidArgument — wrong pain channel: {err:?}",
                );
            }
        }

        /// **SMITH framing — length delimiter:** encoded frame size matches peek helper, and decode
        /// recovers the payload bytes.
        ///
        /// **Pain if broken:** NATS / multiplexed streams would mis-frame organism signals.
        #[test]
        fn length_delimited_peek_matches_encode(payload in vec_bytes(192)) {
            let msg = MockWireBlob { payload: payload.clone() };
            let frame = encode_length_delimited(&msg).expect(
                "CLERK proto stress: encode_length_delimited must succeed for MockWireBlob",
            );
            let total = length_delimited_frame_byte_count(&frame)
                .expect("peek must not error on a frame we just encoded")
                .expect(
                    "CLERK proto stress: full frame must be peekable — SMITH organism sees incomplete cell",
                );
            prop_assert_eq!(
                total,
                frame.len(),
                "length_delimited_frame_byte_count must equal encoded frame length — framing DNA broken",
            );
            let mut cursor: &[u8] = frame.as_ref();
            let decoded: MockWireBlob = decode_length_delimited(&mut cursor).expect(
                "decode_length_delimited must recover MockWireBlob — sequencer could not read cell",
            );
            prop_assert_eq!(
                decoded.payload, payload,
                "round-trip payload mismatch — protobuf organism corrupted binary field",
            );
            prop_assert_eq!(
                cursor.len(),
                0,
                "decoder must consume entire frame — trailing garbage after organism signal",
            );
        }

        /// **Constant-time compare — logical equivalence:** [`secure_compare`] agrees with slice
        /// equality for arbitrary lengths (including mismatched lengths).
        ///
        /// **Why this test exists:** This does **not** measure timing; it only guards functional
        /// correctness. The *value* of [`secure_compare`] is side-channel resistance when comparing
        /// secrets (signatures, MACs), which requires constant-time execution — something unit tests
        /// here cannot prove, only code review and specialized benchmarks can.
        #[test]
        fn secure_compare_matches_equality_bitwise((a, b) in (vec_bytes(48), vec_bytes(48))) {
            prop_assert_eq!(
                secure_compare(&a, &b),
                a == b,
                "secure_compare must match slice equality — logical organism desync",
            );
        }

        /// **Corrupt hex — error path:** strategy only emits odd-length valid nybbles or strings with
        /// illegal symbols; `decode_hex` must reject every draw.
        #[test]
        fn corrupt_hex_rejected(s in corrupt_hex_string()) {
            let res = decode_hex(&s);
            prop_assert!(
                res.is_err(),
                "CLERK hex organism: corrupt_hex_string inputs must fail decode_hex — accepted poison: {s:?}",
            );
        }
    }
}
