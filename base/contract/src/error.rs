//! **Semantic firewall** — typed contract errors for Sylvia `#[sv::error(ContractError)]` and `?` in handlers.
//!
//! Messages are written for **BARD / UI** and audit logs; handlers construct these variants — no logic here.

use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error(
        "Unauthorized: this sender does not have the required role, PASETO binding, or contract permission ({detail})"
    )]
    Unauthorized { detail: String },

    #[error("Policy violation (CLERK): {reason}")]
    PolicyViolation { reason: String },

    #[error("Insufficient funds: required {required}, found {found}")]
    InsufficientFunds { required: String, found: String },

    #[error("Invalid amount: value {val} is not a valid non-negative decimal for this operation")]
    InvalidAmount { val: String },

    #[error("Contract is paused: no state-changing operations until admin resumes")]
    ContractPaused,

    #[error("Invalid proof or cryptographic verification: {detail}")]
    ProofInvalid { detail: String },

    #[error("Encryption error (AES-GCM, PQ, or key handling): {detail}")]
    EncryptionError { detail: String },

    #[error("Capability not available in this build: {detail}")]
    CapabilityError { detail: String },

    #[error("Migration already applied: stored schema is {current}, but migration requested {requested}")]
    MigrationAlreadyApplied { current: u64, requested: u64 },

    #[error("Serialization or MASON/Protobuf mapping failed: {detail}")]
    SerializationError { detail: String },

    #[error("No intent or proof trace is recorded for trace_id {trace_id}")]
    TraceNotFound { trace_id: String },
}

impl PartialEq for ContractError {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Std(a), Self::Std(b)) => a.to_string() == b.to_string(),
            (Self::Unauthorized { detail: a }, Self::Unauthorized { detail: b }) => a == b,
            (Self::PolicyViolation { reason: a }, Self::PolicyViolation { reason: b }) => a == b,
            (
                Self::InsufficientFunds { required: ar, found: af },
                Self::InsufficientFunds { required: br, found: bf },
            ) => ar == br && af == bf,
            (Self::InvalidAmount { val: a }, Self::InvalidAmount { val: b }) => a == b,
            (Self::ContractPaused, Self::ContractPaused) => true,
            (Self::ProofInvalid { detail: a }, Self::ProofInvalid { detail: b }) => a == b,
            (Self::EncryptionError { detail: a }, Self::EncryptionError { detail: b }) => a == b,
            (Self::CapabilityError { detail: a }, Self::CapabilityError { detail: b }) => a == b,
            (
                Self::MigrationAlreadyApplied { current: ac, requested: ar },
                Self::MigrationAlreadyApplied { current: bc, requested: br },
            ) => ac == bc && ar == br,
            (Self::SerializationError { detail: a }, Self::SerializationError { detail: b }) => a == b,
            (Self::TraceNotFound { trace_id: a }, Self::TraceNotFound { trace_id: b }) => a == b,
            _ => false,
        }
    }
}
