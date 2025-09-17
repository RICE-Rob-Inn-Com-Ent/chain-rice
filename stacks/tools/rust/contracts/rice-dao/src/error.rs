use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("Voting period has ended")]
    VotingPeriodEnded {},

    #[error("Voting period is still active")]
    VotingPeriodActive {},

    #[error("Proposal is not active")]
    ProposalNotActive {},

    #[error("Invalid vote")]
    InvalidVote {},

    #[error("Quorum not met")]
    QuorumNotMet {},
}
