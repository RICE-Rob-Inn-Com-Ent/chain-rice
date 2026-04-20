//! **Sovereign memory** — storage **namespaces** and **types** for `cw-storage-plus` (`Item`, `Map`, `SnapshotMap`).
//!
//! Handlers construct `Item::new(CONFIG_KEY)`, `Map::new(BALANCES_KEY)`, etc., so keys stay centralized
//! and migrations can audit the keyspace. No storage I/O in this module.

use cw_storage_plus::{Item, Map, SnapshotMap};

use crate::r#type::{Balance, ContractConfig, ContractVersion, ProofStatus};

// --- Namespace constants (stable for migrations) --------------------------------

/// Global VM configuration — `Item::new(CONFIG_KEY)` holds [`ContractConfig`](crate::r#type::ContractConfig).
pub const CONFIG_KEY: &str = "config";
/// Schema / migration version — `Item::new(VERSION_KEY)` holds [`VersionState`].
pub const VERSION_KEY: &str = "version";
/// cw2 [`cw2::ContractVersion::contract`] string — single source for [`crate::execute`] and [`crate::migration`].
pub const CW2_CONTRACT_NAME: &str = "rice.rice-runtime";
/// Principal holdings — `Map::new(BALANCES_KEY)` → `Map<Addr, Balance>`.
pub const BALANCES_KEY: &str = "balances";
/// Cryptographic audit traces by id — `Map::new(PROOFS_KEY)` → `Map<String, ProofStatus>`.
pub const PROOFS_KEY: &str = "proofs";

/// Snapshot primary namespace for per-block governance / app weights (separate from live `balances`).
pub const GOV_WEIGHTS_PK: &str = "gov_weights";
pub const GOV_WEIGHTS_CHECK: &str = "gov_weights__check";
pub const GOV_WEIGHTS_CHANGE: &str = "gov_weights__change";

// --- Version metadata -----------------------------------------------------------

/// Contract schema version persisted for [`crate::migration`].
#[cosmwasm_schema::cw_serde]
pub struct VersionState {
    pub current: ContractVersion,
}

// --- Type aliases (documentation + handler signatures) ------------------------

use cosmwasm_std::Addr;

/// VM configuration singleton.
pub type ConfigItem = Item<ContractConfig>;
/// Migration counter singleton.
pub type VersionItem = Item<VersionState>;
/// Live balance per principal.
pub type BalancesMap = Map<Addr, Balance>;
/// Proof / audit status keyed by trace id string.
pub type ProofsMap = Map<String, ProofStatus>;
/// Checkpointed weights (`Strategy::EveryBlock`) for historical queries.
pub type GovernanceWeightsSnapshot = SnapshotMap<Addr, Balance>;

/// Build the governance snapshot map with the canonical namespaces from this module.
#[must_use]
pub const fn governance_weights_snapshot() -> GovernanceWeightsSnapshot {
    use cw_storage_plus::Strategy;
    SnapshotMap::new(GOV_WEIGHTS_PK, GOV_WEIGHTS_CHECK, GOV_WEIGHTS_CHANGE, Strategy::EveryBlock)
}
