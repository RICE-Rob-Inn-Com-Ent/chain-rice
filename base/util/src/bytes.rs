//! Byte buffers, hex helpers, and cheap views for protobuf transport and ZK-friendly layouts.
use bytes::Bytes;

use crate::error::RiceResult;

// [ ] https://docs.rs/hex/ https://docs.rs/bytes/ — constant_time_eq

/// Decode hex string to owned [`Vec<u8>`].
#[inline]
pub fn decode_hex(s: &str) -> RiceResult<Vec<u8>> {
    Ok(hex::decode(s)?)
}

/// Encode bytes as lowercase hex.
#[inline]
pub fn encode_hex_lower(data: &[u8]) -> String {
    hex::encode(data)
}

/// Zero-copy view over a contiguous slice as [`Bytes`].
#[inline]
pub fn bytes_from_slice(data: &[u8]) -> Bytes {
    Bytes::copy_from_slice(data)
}

/// Parse hex into [`Bytes`] (owned).
#[inline]
pub fn bytes_from_hex(s: &str) -> RiceResult<Bytes> {
    Ok(Bytes::from(decode_hex(s)?))
}
