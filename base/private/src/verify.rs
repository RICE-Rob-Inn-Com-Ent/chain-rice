//! Proof verification — public inputs + verifying key + Groth16 verifier.

use ark_crypto_primitives::snark::SNARK;
use ark_ec::pairing::Pairing;
use ark_groth16::{Groth16, Proof, VerifyingKey};

use crate::error::VerifyError;

// [ ] https://docs.rs/ark-groth16/
// [ ] verify — RICE_ZK_VERIFYING_KEY_PATH; batch RICE_ZK_VERIFY_BATCH_SIZE; CosmWasm bytes; NATS audit subject

/// Verify a `MulCircuit` proof against the public product `public_c`.
pub fn verify_mul<E: Pairing>(
    vk: &VerifyingKey<E>,
    public_c: E::ScalarField,
    proof: &Proof<E>,
) -> Result<bool, VerifyError> {
    Ok(Groth16::<E>::verify(vk, &[public_c], proof)?)
}
