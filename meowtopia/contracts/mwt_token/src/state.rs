use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, Uint128};
use cw_storage_plus::{Item, Map};

// Minter configuration for Meowtopia-specific features
#[cw_serde]
pub struct MinterConfig {
    pub owner: Addr,
    pub can_mint_for_gameplay: bool,
    pub can_mint_for_breeding: bool,
    pub can_mint_for_staking: bool,
    pub max_mint_per_transaction: Uint128,
}

// Game configuration for various activities
#[cw_serde]
pub struct GameConfig {
    pub breeding_cost: Uint128,
    pub feeding_cost: Uint128,
    pub staking_reward_rate: Uint128, // Percentage reward per staking period
    pub tournament_entry_fee: Uint128,
}

// Game statistics tracking
#[cw_serde]
pub struct GameStats {
    pub total_cats_bred: u64,
    pub total_tokens_spent_on_feeding: Uint128,
    pub total_tournament_entries: u64,
    pub total_staking_rewards: Uint128,
    pub total_training_sessions: u64,
}

// User-specific game data
#[cw_serde]
pub struct UserGameData {
    pub cats_owned: Vec<String>,
    pub cats_bred: u64,
    pub tokens_earned_from_gameplay: Uint128,
    pub tokens_spent_on_activities: Uint128,
    pub tournament_wins: u64,
    pub total_staking_time: u64, // in blocks
}

// Activity log for tracking token usage
#[cw_serde]
pub struct ActivityLog {
    pub user: Addr,
    pub activity_type: String,
    pub token_amount: Uint128,
    pub timestamp: u64,
    pub metadata: Option<String>,
}

// Storage items
pub const MINTER_CONFIG: Item<MinterConfig> = Item::new("minter_config");
pub const GAME_CONFIG: Item<GameConfig> = Item::new("game_config");
pub const GAME_STATS: Item<GameStats> = Item::new("game_stats");

// Storage maps
pub const USER_GAME_DATA: Map<&Addr, UserGameData> = Map::new("user_game_data");
pub const ACTIVITY_LOGS: Map<u64, ActivityLog> = Map::new("activity_logs");
pub const STAKING_INFO: Map<&Addr, StakingInfo> = Map::new("staking_info");

// Staking information
#[cw_serde]
pub struct StakingInfo {
    pub staked_amount: Uint128,
    pub stake_start_time: u64,
    pub last_reward_claim: u64,
    pub total_rewards_earned: Uint128,
}

// Cat breeding pairs tracking
#[cw_serde]
pub struct BreedingPair {
    pub parent1_id: String,
    pub parent2_id: String,
    pub owner: Addr,
    pub breeding_fee_paid: Uint128,
    pub breeding_timestamp: u64,
    pub offspring_id: Option<String>,
}

pub const BREEDING_PAIRS: Map<u64, BreedingPair> = Map::new("breeding_pairs");
pub const BREEDING_COUNTER: Item<u64> = Item::new("breeding_counter");

// Tournament information
#[cw_serde]
pub struct Tournament {
    pub id: String,
    pub name: String,
    pub entry_fee: Uint128,
    pub prize_pool: Uint128,
    pub participants: Vec<Addr>,
    pub winner: Option<Addr>,
    pub start_time: u64,
    pub end_time: u64,
    pub status: TournamentStatus,
}

#[cw_serde]
pub enum TournamentStatus {
    Upcoming,
    Active,
    Completed,
    Cancelled,
}

pub const TOURNAMENTS: Map<&str, Tournament> = Map::new("tournaments");
pub const TOURNAMENT_PARTICIPANTS: Map<(&str, &Addr), bool> = Map::new("tournament_participants");