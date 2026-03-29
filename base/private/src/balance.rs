//! Balance and range-style proofs on **BN254** — amount-hiding gadgets replace [`crate::circuit::MulCircuit`]
//! in production.

// [ ] https://docs.rs/ark-groth16/
// [ ] Pedersen RICE_ZK_PEDERSEN_PARAMS; range bits RICE_ZK_BALANCE_BITS; multi-asset proofs

pub use ark_bn254::Bn254;
pub use ark_groth16::{Proof, ProvingKey, VerifyingKey};

pub type BalanceProof = Proof<Bn254>;
