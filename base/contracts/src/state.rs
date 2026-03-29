//! On-chain storage layout — `cw-storage-plus` (`Item`, `Map`, indexed maps, etc.).
//!
//! Extend with `Map`, `IndexedMap`, `SnapshotMap`, `Deque` as the domain grows.

use cosmwasm_schema::cw_serde;

use crate::types::ContractVersion;

/// Storage key for global config singleton.
pub const CONFIG_KEY: &str = "cfg";
/// Storage key for schema / migration version counter.
pub const VERSION_KEY: &str = "ver";

/// Contract-wide configuration persisted as a single `Item`.
#[cw_serde]
pub struct Config {
    pub admin: Option<String>,
}

/// Contract version metadata (migration bookkeeping).
#[cw_serde]
pub struct VersionState {
    pub current: ContractVersion,
}
