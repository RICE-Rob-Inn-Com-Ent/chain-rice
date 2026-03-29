//! Canonical compressed serialization for proofs and keys (transport / proto sidecars).

use ark_ec::pairing::Pairing;
use ark_groth16::{Proof, ProvingKey, VerifyingKey};
use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};

use crate::error::SerialError;

// [ ] https://docs.rs/ark-groth16/ — ark-serialize, prost
// [ ] pk/vk I/O paths; prost envelope base/gen/; hex for CosmWasm msgs

pub fn proof_to_bytes_compressed<E: Pairing>(proof: &Proof<E>) -> Result<Vec<u8>, SerialError> {
    let mut buf = Vec::new();
    proof.serialize_compressed(&mut buf)?;
    Ok(buf)
}

pub fn proof_from_bytes_compressed<E: Pairing>(bytes: &[u8]) -> Result<Proof<E>, SerialError> {
    Ok(Proof::deserialize_compressed(bytes)?)
}

pub fn proving_key_to_bytes_compressed<E: Pairing>(pk: &ProvingKey<E>) -> Result<Vec<u8>, SerialError> {
    let mut buf = Vec::new();
    pk.serialize_compressed(&mut buf)?;
    Ok(buf)
}

pub fn proving_key_from_bytes_compressed<E: Pairing>(bytes: &[u8]) -> Result<ProvingKey<E>, SerialError> {
    Ok(ProvingKey::deserialize_compressed(bytes)?)
}

pub fn verifying_key_to_bytes_compressed<E: Pairing>(vk: &VerifyingKey<E>) -> Result<Vec<u8>, SerialError> {
    let mut buf = Vec::new();
    vk.serialize_compressed(&mut buf)?;
    Ok(buf)
}

pub fn verifying_key_from_bytes_compressed<E: Pairing>(bytes: &[u8]) -> Result<VerifyingKey<E>, SerialError> {
    Ok(VerifyingKey::deserialize_compressed(bytes)?)
}
