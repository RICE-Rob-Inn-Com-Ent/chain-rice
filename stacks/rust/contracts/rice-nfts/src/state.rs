use cosmwasm_std::Addr;
use cw_storage_plus::Item;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Config {
    pub owner: Addr,
    pub name: String,
    pub symbol: String,
    pub base_uri: String,
    pub max_supply: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct TokenInfo {
    pub total_supply: u64,
    pub minted: u64,
}

pub const CONFIG: Item<Config> = Item::new("config");
pub const TOKEN_INFO: Item<TokenInfo> = Item::new("token_info");
