use cosmwasm_schema::{cw_serde, QueryResponses};
use cosmwasm_std::{Uint128, Expiration, Binary};
use cw20::{AllowanceResponse, BalanceResponse, TokenInfoResponse, MinterResponse, 
           AllAccountsResponse, AllAllowancesResponse};

use crate::state::{MinterConfig, GameConfig};

#[cw_serde]
pub struct InstantiateMsg {
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub mint_cap: Option<Uint128>,
    
    // Meowtopia-specific game configuration
    pub max_mint_per_tx: Option<Uint128>,
    pub breeding_cost: Option<Uint128>,
    pub feeding_cost: Option<Uint128>,
    pub staking_reward_rate: Option<Uint128>,
    pub tournament_entry_fee: Option<Uint128>,
}

#[cw_serde]
pub enum ExecuteMsg {
    // Standard CW20 messages
    Transfer {
        recipient: String,
        amount: Uint128,
    },
    Burn {
        amount: Uint128,
    },
    Send {
        contract: String,
        amount: Uint128,
        msg: Binary,
    },
    IncreaseAllowance {
        spender: String,
        amount: Uint128,
        expires: Option<Expiration>,
    },
    DecreaseAllowance {
        spender: String,
        amount: Uint128,
        expires: Option<Expiration>,
    },
    TransferFrom {
        owner: String,
        recipient: String,
        amount: Uint128,
    },
    BurnFrom {
        owner: String,
        amount: Uint128,
    },
    SendFrom {
        owner: String,
        contract: String,
        amount: Uint128,
        msg: Binary,
    },
    
    // Custom Meowtopia messages
    MintForGame {
        recipient: String,
        amount: Uint128,
        reason: String,
    },
    MintForBreeding {
        recipient: String,
        amount: Uint128,
        cat_id: String,
    },
    BurnForActivity {
        amount: Uint128,
        activity: String,
    },
    UpdateGameConfig {
        breeding_cost: Option<Uint128>,
        feeding_cost: Option<Uint128>,
        staking_reward_rate: Option<Uint128>,
        tournament_entry_fee: Option<Uint128>,
    },
    UpdateMinterConfig {
        can_mint_for_gameplay: Option<bool>,
        can_mint_for_breeding: Option<bool>,
        can_mint_for_staking: Option<bool>,
        max_mint_per_transaction: Option<Uint128>,
    },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {
    // Standard CW20 queries
    #[returns(BalanceResponse)]
    Balance { address: String },
    
    #[returns(TokenInfoResponse)]
    TokenInfo {},
    
    #[returns(MinterResponse)]
    Minter {},
    
    #[returns(AllowanceResponse)]
    Allowance { owner: String, spender: String },
    
    #[returns(AllAllowancesResponse)]
    AllAllowances {
        owner: String,
        start_after: Option<String>,
        limit: Option<u32>,
    },
    
    #[returns(AllAccountsResponse)]
    AllAccounts {
        start_after: Option<String>,
        limit: Option<u32>,
    },
    
    // Custom Meowtopia queries
    #[returns(GameConfig)]
    GameConfig {},
    
    #[returns(MinterConfig)]
    MinterConfig {},
}

// Custom message types for Meowtopia functionality
#[cw_serde]
pub struct MeowtopiaMintMsg {
    pub recipient: String,
    pub amount: Uint128,
    pub mint_type: MintType,
}

#[cw_serde]
pub enum MintType {
    Gameplay { reason: String },
    Breeding { cat_id: String },
    Staking { duration: u64 },
    Tournament { tournament_id: String },
}

#[cw_serde]
pub struct GameActivityMsg {
    pub activity_type: ActivityType,
    pub cost: Uint128,
    pub metadata: Option<String>,
}

#[cw_serde]
pub enum ActivityType {
    CatFeeding { cat_id: String },
    CatBreeding { parent1: String, parent2: String },
    TournamentEntry { tournament_id: String },
    StakingReward { duration: u64 },
    TrainingSession { cat_id: String, skill: String },
}

// Response types for custom queries
#[cw_serde]
pub struct GameStatsResponse {
    pub total_cats_bred: u64,
    pub total_tokens_spent_on_feeding: Uint128,
    pub total_tournament_entries: u64,
    pub total_staking_rewards: Uint128,
}