//! Compliance proofs on **BLS12-381** — membership / exclusion arguments (Merkle, accumulators) replace
//! [`crate::circuit::MulCircuit`] in production.

// [ ] https://docs.rs/ark-groth16/
// [ ] policy compliance proof; threshold RICE_ZK_THRESHOLD; set membership; aggregate proofs

pub use ark_bls12_381::Bls12_381;
pub use ark_groth16::{Proof, ProvingKey, VerifyingKey};

pub type ComplianceProof = Proof<Bls12_381>;
