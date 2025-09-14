use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("Max supply reached")]
    MaxSupplyReached {},

    #[error("Token not found")]
    TokenNotFound {},

    #[error("Not owner")]
    NotOwner {},
}
