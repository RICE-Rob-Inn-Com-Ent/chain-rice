//! Typed contract errors — used by Sylvia `#[sv::error(...)]` and `?` in handlers.

use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized,

    #[error("Migration already applied: current {current}, requested {requested}")]
    MigrationAlreadyApplied { current: u64, requested: u64 },
}
