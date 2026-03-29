//! Typed errors for circuits, setup, proving, and verification.

use thiserror::Error;

// [ ] https://docs.rs/ark-groth16/
// [ ] SetupNotFound, SetupCorrupted, ProofGenerationFailed, VerificationFailed, CircuitError, SerializationError, CurveNotSupported, NullifierAlreadyUsed, CacheError

/// Constraint synthesis or malformed circuit description.
#[derive(Error, Debug)]
pub enum CircuitError {
    #[error(transparent)]
    Synthesis(#[from] ark_relations::r1cs::SynthesisError),
}

/// Trusted setup and key generation.
#[derive(Error, Debug)]
pub enum SetupError {
    #[error(transparent)]
    Synthesis(#[from] ark_relations::r1cs::SynthesisError),
}

/// Proof generation (witness + prover).
#[derive(Error, Debug)]
pub enum ProofError {
    #[error(transparent)]
    Synthesis(#[from] ark_relations::r1cs::SynthesisError),
}

/// Proof verification.
#[derive(Error, Debug)]
pub enum VerifyError {
    #[error(transparent)]
    Synthesis(#[from] ark_relations::r1cs::SynthesisError),
}

/// Serialization of proofs or keys for transport.
#[derive(Error, Debug)]
pub enum SerialError {
    #[error(transparent)]
    Serialize(#[from] ark_serialize::SerializationError),
}
