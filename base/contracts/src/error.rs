//! Typed contract errors — used by Sylvia `#[sv::error(...)]` and `?` in handlers.

use cosmwasm_std::StdError;
use thiserror::Error;

// [ ] https://docs.cosmwasm.com/ — StdError wrapping
// [ ] InsufficientFunds, InvalidAmount, PolicyViolation, ProofInvalid, ContractPaused, MigrationError, EncryptionError, SerializationError
// [ ] Unauthorized — PASETO / role mapping from env

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized,

    #[error("Migration already applied: current {current}, requested {requested}")]
    MigrationAlreadyApplied { current: u64, requested: u64 },
}
