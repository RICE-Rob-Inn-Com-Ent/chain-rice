//! [`proptest`] strategies shared by domain tests in `base/`.
use proptest::collection::vec as vec_strategy;
use proptest::prelude::*;
use proptest::sample::select;

// [ ] https://docs.rs/proptest/ — arb_decimal, arb_addr, arb_proof_id; RICE_PROP_CASES; prop_clerk!

/// Arbitrary byte vectors up to `max_len` elements.
pub fn vec_bytes(max_len: usize) -> impl Strategy<Value = Vec<u8>> {
    vec_strategy(any::<u8>(), 0..=max_len)
}

/// Fixed-size byte array strategy (e.g. 32-byte digests).
pub fn byte_array<const N: usize>() -> impl Strategy<Value = [u8; N]> {
    vec_strategy(any::<u8>(), N).prop_map(|v| {
        let mut out = [0u8; N];
        out.copy_from_slice(&v);
        out
    })
}

/// Printable ASCII strings for labels and test identifiers.
pub fn ascii_string(max_len: usize) -> impl Strategy<Value = String> {
    const CHARSET: &[u8] = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
    vec_strategy(select(CHARSET.to_vec()), 0..=max_len).prop_map(|v| {
        String::from_utf8(v).expect("charset is ascii")
    })
}
