use cosmwasm_std::Addr;
use cw_storage_plus::{Item, Map};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Config {
    pub admin: Addr,
    pub name: String,
    pub description: String,
    pub voting_period: u64,
    pub quorum: u64,
    pub threshold: f64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Proposal {
    pub id: u64,
    pub title: String,
    pub description: String,
    pub proposal_type: String,
    pub proposer: Addr,
    pub status: String,
    pub votes_for: u64,
    pub votes_against: u64,
    pub created_at: cosmwasm_std::Timestamp,
    pub voting_end: cosmwasm_std::Timestamp,
}

pub const CONFIG: Item<Config> = Item::new("config");
pub const PROPOSALS: Map<u64, Proposal> = Map::new("proposals");
