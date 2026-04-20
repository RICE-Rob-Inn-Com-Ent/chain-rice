//! The ZK **pain map** for the `private` crate — every failure mode in setup, proving, verification,
//! identity, and compliance is typed here before it crosses into broader CLERK code via
//! [`PrivateError::into_rice`].
//!
//! **Why:** Privacy operations fail for subtle reasons (wrong curve, bad SRS, invalid witness).
//! Operators and upper layers must see *which* phase broke without reverse-engineering logs.
//! **How:** A single [`PrivateError`] enum groups lifecycle stages; arkworks failures use
//! `#[error(transparent)]` where appropriate. Rust’s orphan rules prevent defining
//! `impl From<PrivateError> for util::RiceError` here — use [`PrivateError::into_rice`] (and
//! [`util::RiceError::context`](util::RiceError::context) at the callsite) to attach breadcrumbs.

use std::io;

use ark_relations::r1cs::SynthesisError;
use ark_serialize::SerializationError;
use thiserror::Error;

use util::RiceError;

/// Unified failure type for the zero-knowledge lifecycle (R1CS, Groth16, identity, wire format).
#[derive(Debug, Error)]
pub enum PrivateError {
    // --- Field (scalar / base arithmetic) -----------------------------------
    /// A field element is out of the expected domain, failed strict parsing, or breaks invariants.
    ///
    /// **Pain:** R1CS and commitments live in a fixed field; wrong modulus or garbage scalars
    /// invalidate every downstream equation before you reach pairing or proof logic.
    #[error("field element invalid or out of domain: {0}")]
    FieldInvalid(String),

    // --- Circuit / R1CS ----------------------------------------------------
    /// R1CS synthesis, setup, proving, or verification raised an arkworks [`SynthesisError`].
    ///
    /// **Pain:** The constraint system could not be built, satisfied, or checked — often witness
    /// gaps, malformed circuits, or internal verifier inconsistencies. Privacy hinges on correct R1CS;
    /// this is the lowest-level technical failure.
    #[error(transparent)]
    R1cs(#[from] SynthesisError),

    /// An explicit constraint or domain rule inside the circuit description failed.
    ///
    /// **Pain:** The prover tried to encode a state the circuit forbids; continuing would prove a
    /// false statement or leak structure through side channels in buggy handlers.
    #[error("circuit constraint violated: {0}")]
    CircuitConstraint(String),

    // --- Setup / SRS ---------------------------------------------------------
    /// Expected proving or verifying parameters were not found (path, registry, or cache miss).
    ///
    /// **Pain:** Without trusted keys, no honest proof can be produced or checked; the organism
    /// cannot start the privacy pipeline.
    #[error("SRS / proving parameters missing: {0}")]
    SetupMissing(String),

    /// Stored parameters fail integrity checks or do not match the expected ceremony fingerprint.
    ///
    /// **Pain:** Using corrupted SRS breaks soundness or enables forgery — treat as cryptographic
    /// compromise until rotated.
    #[error("SRS or keys corrupted / ceremony mismatch: {0}")]
    SetupCorrupted(String),

    /// Universal or circuit-specific parameters do not match this build (degree, curve, or circuit hash).
    ///
    /// **Pain:** Mixing parameter sets is a common footgun (BN254 SRS with BLS12-381 circuit);
    /// proofs would be meaningless or reject unpredictably.
    #[error("parameters incompatible with circuit or curve: {0}")]
    SetupIncompatible(String),

    /// Environment or policy forbids the requested setup action (e.g. generating keys in production).
    ///
    /// **Pain:** Violating ceremony discipline breaks the trust model; this is a deliberate fail-closed
    /// guardrail separate from missing files or byte-level corruption.
    #[error("ZK setup policy violation: {0}")]
    SetupPolicy(String),

    // --- Proving -------------------------------------------------------------
    /// Witness assignment missing, inconsistent, or rejected before proof generation.
    ///
    /// **Pain:** The prover cannot attest to the relation without a full witness; publishing anyway
    /// would mean a dishonest or empty proof attempt.
    #[error("witness generation / proving preparation failed: {0}")]
    ProvingWitness(String),

    /// Preflight R1CS check failed: witness does not satisfy the constraint system.
    ///
    /// **Pain:** Running Groth16 on a bad witness wastes CPU; this fail-fast path aborts before the
    /// heavy prover (see [`crate::prove::generate_proof`]).
    #[error("witness inconsistent with circuit (preflight): {0}")]
    WitnessInconsistent(String),

    // --- Verification --------------------------------------------------------
    /// Groth16 (or SNARK) verification returned `false` — the proof does not validate the claim.
    ///
    /// **Pain:** Mathematically the statement is not accepted under the given verifying key and
    /// public inputs; this is normal rejection, not a transport error.
    #[error("zk proof invalid for these public inputs and verifying key")]
    ProofInvalid,

    /// Verification could not run: wrong public-input arity/order for this VK, or verifier backend error.
    ///
    /// **Pain:** Distinct from [`ProofInvalid`]: the proof was never meaningfully compared to the
    /// statement (malformed layout, constraint count mismatch). Fix inputs or encoding before retrying.
    #[error("zk verify malformed or technical failure: {0}")]
    VerifyMalformed(String),

    // --- Identity / nullifiers -----------------------------------------------
    /// A nullifier or one-time secret was reused — classic double-spend or replay signal.
    ///
    /// **Pain:** Privacy-preserving ledgers rely on spent tags; collision means the same shielded
    /// resource is being consumed twice.
    #[error("identity nullifier collision (possible double-spend): {0}")]
    IdentityNullifierCollision(String),

    /// Key material, address format, or derivation output is malformed.
    ///
    /// **Pain:** Bad keys cannot anchor proofs to the intended identity; proceeding risks linking or
    /// burning funds to wrong owners.
    #[error("malformed identity key or encoding: {0}")]
    IdentityMalformedKey(String),

    // --- Compliance (private policy) ----------------------------------------
    /// A private-side rule vetoed the operation (e.g. attestation does not match claimed status).
    ///
    /// **Pain:** The conscience of the private layer refused — distinct from R1CS bugs; often
    /// maps to [`RiceError::Policy`] when lifted to CLERK.
    #[error("private compliance veto: {0}")]
    ComplianceVeto(String),

    // --- Serialization & storage --------------------------------------------
    /// Proof, key, or artifact (de)serialization failed on the wire.
    ///
    /// **Pain:** Peers cannot interpret bytes as canonical ark types; privacy payloads are unusable
    /// until encoding is fixed.
    #[error(transparent)]
    Serialization(#[from] SerializationError),

    /// Persistent or streaming I/O around proof/key material failed.
    ///
    /// **Pain:** The organism cannot load or persist secrets/parameters; retry may help for transient
    /// faults — maps to [`RiceError::Io`] when lifted.
    #[error(transparent)]
    StorageIo(#[from] io::Error),

    // --- Cross-curve / safety -----------------------------------------------
    /// Operation assumed one pairing family but received another (e.g. BN254 vs BLS12-381).
    ///
    /// **Pain:** Curve mixups break pairing equations outright; never silently coerce across curves.
    #[error("elliptic curve mismatch: expected {expected}, got {got}")]
    CurveMismatch { expected: String, got: String },

    /// Internal invariant violated — possible mishandling of secret data; fail closed.
    ///
    /// **Pain:** Defensive trigger when code paths that must never run after witness exposure do;
    /// prefer aborting over leaking partial secrets or stale state.
    #[error("internal safety invariant violated (possible secret mishandling): {0}")]
    SecretLeak(String),
}

/// Convenient [`Result`] alias for ZK operations in this crate.
pub type PrivateResult<T> = Result<T, PrivateError>;

impl PrivateError {
    /// Map this error into [`RiceError`] for contracts, `util`, or SMITH boundaries.
    ///
    /// **Why:** CLERK uses one error surface upstream; ZK-specific detail stays in the [`Display`]
    /// string and optional [`std::error::Error::source`] chain from transparent variants.
    /// **How:** Compliance → [`RiceError::policy`]; I/O → [`RiceError::Io`]; the rest →
    /// [`RiceError::crypto`] so telemetry can bucket “cryptographic / ZK” failures together.
    #[must_use]
    pub fn into_rice(self) -> RiceError {
        match self {
            PrivateError::FieldInvalid(d) => RiceError::crypto(format!("zk field: {d}")),
            PrivateError::ComplianceVeto(msg) => RiceError::policy(msg),
            PrivateError::StorageIo(e) => RiceError::Io(e),
            PrivateError::R1cs(e) => RiceError::crypto(format!("zk R1CS: {e}")),
            PrivateError::CircuitConstraint(d) => RiceError::crypto(format!("zk circuit: {d}")),
            PrivateError::SetupMissing(d) => RiceError::crypto(format!("zk setup missing: {d}")),
            PrivateError::SetupCorrupted(d) => RiceError::crypto(format!("zk setup corrupted: {d}")),
            PrivateError::SetupIncompatible(d) => {
                RiceError::crypto(format!("zk setup incompatible: {d}"))
            }
            PrivateError::SetupPolicy(d) => RiceError::crypto(format!("zk setup policy: {d}")),
            PrivateError::ProvingWitness(d) => RiceError::crypto(format!("zk proving: {d}")),
            PrivateError::WitnessInconsistent(d) => {
                RiceError::crypto(format!("zk witness inconsistent: {d}"))
            }
            PrivateError::ProofInvalid => RiceError::crypto(String::from(
                "zk proof rejected by verifier (invalid for public inputs)",
            )),
            PrivateError::VerifyMalformed(d) => {
                RiceError::crypto(format!("zk verify malformed: {d}"))
            }
            PrivateError::IdentityNullifierCollision(d) => {
                RiceError::crypto(format!("zk identity nullifier: {d}"))
            }
            PrivateError::IdentityMalformedKey(d) => {
                RiceError::crypto(format!("zk identity key: {d}"))
            }
            PrivateError::Serialization(e) => RiceError::crypto(format!("zk serialize: {e}")),
            PrivateError::CurveMismatch { expected, got } => RiceError::crypto(format!(
                "zk curve mismatch: expected {expected}, got {got}"
            )),
            PrivateError::SecretLeak(d) => RiceError::crypto(format!("zk safety: {d}")),
        }
    }
}
