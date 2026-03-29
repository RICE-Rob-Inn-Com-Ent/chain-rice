//! On-chain storage layout — `cw-storage-plus` (`Item`, `Map`, indexed maps, etc.).
//!
//! Extend with `Map`, `IndexedMap`, `SnapshotMap`, `Deque` as the domain grows.

use cosmwasm_schema::cw_serde;

use crate::types::ContractVersion;

// [ ] https://docs.cosmwasm.com/ — cw-storage-plus Item, Map, SnapshotMap, IndexedMap, Deque
// [ ] ContractConfig — cw_serde; admin, paused, version; validation before persist
// [ ] Item<ContractConfig> — key from const CONFIG_KEY / env-driven prefix, no scattered string literals
// [ ] Map<Addr, Uint128> balances; SnapshotMap audit trail when RICE_SNAPSHOT_ENABLED
// [ ] IndexedMap for secondary indexes; Deque<AuditEvent> cap from RICE_AUDIT_LOG_MAX
// [ ] BALANCES, POLICIES, PROOF_STATUS, CONFIG, AUDIT_LOG, TOTAL_SUPPLY — keys as consts from single module

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
