//! Proof generation — witness synthesis + Groth16 prover.

use ark_crypto_primitives::snark::SNARK;
use ark_ec::pairing::Pairing;
use ark_groth16::{Groth16, Proof, ProvingKey};
use ark_std::rand::{CryptoRng, RngCore};

use crate::circuit::MulCircuit;
use crate::error::ProofError;

// [ ] https://docs.rs/ark-groth16/
// [ ] prove — RICE_ZK_PROVING_KEY_PATH; OsRng; rayon; batch RICE_ZK_BATCH_SIZE; CUDA RICE_ZK_CUDA; cache RICE_ZK_PROOF_CACHE_PATH; OTel

/// Prove knowledge of `a`, `b` such that `a * b` equals the public input (see `MulCircuit`).
pub fn prove_mul<E: Pairing, R: RngCore + CryptoRng>(
    pk: &ProvingKey<E>,
    a: E::ScalarField,
    b: E::ScalarField,
    rng: &mut R,
) -> Result<Proof<E>, ProofError> {
    let circuit = MulCircuit {
        a: Some(a),
        b: Some(b),
    };
    Ok(Groth16::<E>::prove(pk, circuit, rng)?)
}
