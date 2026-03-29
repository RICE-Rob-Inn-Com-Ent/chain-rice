//! Identity proofs on **BN254** — commitment / nullifier circuits replace [`crate::circuit::MulCircuit`]
//! in production; this module pins the curve and types for that domain.

// [ ] https://docs.rs/ark-groth16/ — Poseidon, MerkleTree
// [ ] commitments, merkle depth RICE_ZK_TREE_DEPTH, nullifiers, Qdrant RICE_ZK_NULLIFIER_COLLECTION

pub use ark_bn254::Bn254;
pub use ark_groth16::{Proof, ProvingKey, VerifyingKey};

pub type IdentityProof = Proof<Bn254>;
