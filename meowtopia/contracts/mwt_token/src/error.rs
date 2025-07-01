use cosmwasm_std::StdError;
use cw20_base::ContractError as Cw20BaseError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("{0}")]
    Base(#[from] Cw20BaseError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("Insufficient funds")]
    InsufficientFunds {},

    #[error("Invalid input: {reason}")]
    InvalidInput { reason: String },

    // Meowtopia-specific errors
    #[error("Gameplay minting is currently disabled")]
    GameplayMintingDisabled {},

    #[error("Breeding minting is currently disabled")]
    BreedingMintingDisabled {},

    #[error("Staking minting is currently disabled")]
    StakingMintingDisabled {},

    #[error("Mint amount exceeds maximum allowed per transaction")]
    ExceedsMaxMint {},

    #[error("Cat not found: {cat_id}")]
    CatNotFound { cat_id: String },

    #[error("Cat not owned by sender: {cat_id}")]
    CatNotOwned { cat_id: String },

    #[error("Cat is already being used for breeding: {cat_id}")]
    CatAlreadyBreeding { cat_id: String },

    #[error("Breeding cooldown period not elapsed for cat: {cat_id}")]
    BreedingCooldownActive { cat_id: String },

    #[error("Cannot breed cats of the same lineage")]
    InvalidBreedingPair {},

    #[error("Tournament not found: {tournament_id}")]
    TournamentNotFound { tournament_id: String },

    #[error("Tournament registration is closed")]
    TournamentRegistrationClosed {},

    #[error("Already registered for tournament: {tournament_id}")]
    AlreadyRegistered { tournament_id: String },

    #[error("Tournament entry fee is insufficient")]
    InsufficientEntryFee {},

    #[error("No tokens currently staked")]
    NoStakedTokens {},

    #[error("Staking period not complete")]
    StakingPeriodActive {},

    #[error("Cannot stake zero tokens")]
    ZeroStakeAmount {},

    #[error("Minimum staking period not met")]
    MinimumStakingPeriodNotMet {},

    #[error("Activity not allowed: {activity}")]
    ActivityNotAllowed { activity: String },

    #[error("Daily activity limit exceeded")]
    DailyLimitExceeded {},

    #[error("Cat is not mature enough for breeding")]
    CatNotMature {},

    #[error("Cat energy is too low for activity")]
    InsufficientCatEnergy {},

    #[error("Game feature is currently disabled")]
    GameFeatureDisabled {},

    #[error("Invalid rarity combination for breeding")]
    InvalidRarityCombination {},

    #[error("Maximum number of cats per user exceeded")]
    MaxCatsExceeded {},

    #[error("Tournament is full")]
    TournamentFull {},

    #[error("Tournament has already started")]
    TournamentAlreadyStarted {},

    #[error("Tournament has not ended yet")]
    TournamentNotEnded {},

    #[error("User is not a tournament participant")]
    NotTournamentParticipant {},

    #[error("Rewards have already been claimed")]
    RewardsAlreadyClaimed {},

    #[error("Invalid tournament status: {status}")]
    InvalidTournamentStatus { status: String },
}