//! [`prost::Message`] encode/decode helpers for wire types produced under `gen/` (MASON).
use bytes::{Buf, BytesMut};
use prost::Message;

use crate::error::{RiceError, RiceResult};

/// Encode a message to a fresh [`Vec<u8>`].
#[inline]
pub fn encode_to_vec<M: Message>(msg: &M) -> RiceResult<Vec<u8>> {
    let mut buf = Vec::new();
    msg.encode(&mut buf)
        .map_err(|e| RiceError::ProtoEncode(e.to_string()))?;
    Ok(buf)
}

/// Decode a message from a byte slice.
#[inline]
pub fn decode_from_slice<M: Message + Default>(buf: &[u8]) -> RiceResult<M> {
    Ok(M::decode(buf)?)
}

/// Encode with a length prefix (varint length) into a [`BytesMut`].
#[inline]
pub fn encode_length_delimited_to_buf<M: Message>(msg: &M, dst: &mut BytesMut) -> RiceResult<()> {
    msg.encode_length_delimited(dst)
        .map_err(|e| RiceError::ProtoEncode(e.to_string()))
}

/// Decode one length-delimited message, advancing `src`.
#[inline]
pub fn decode_length_delimited<M: Message + Default, B: Buf>(src: &mut B) -> RiceResult<M> {
    Ok(M::decode_length_delimited(src)?)
}
