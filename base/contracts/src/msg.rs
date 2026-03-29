//! Public contract API — Sylvia generates `InstantiateMsg`, `ExecMsg`, `QueryMsg`, `MigrateMsg`
//! under `contract::sv` (see Sylvia book). This module re-exports them and adds response DTOs.

pub use crate::contract::sv::{ExecMsg, InstantiateMsg, MigrateMsg, QueryMsg};

/// Alias matching common CosmWasm naming (`ExecuteMsg` vs Sylvia's `ExecMsg`).
pub type ExecuteMsg = ExecMsg;

use cosmwasm_schema::cw_serde;

// [ ] https://docs.cosmwasm.com/ — cw_serde, JsonSchema, schema export
// [ ] InstantiateMsg — serde + JsonSchema; admin, config fields from types; addresses from validation, not literals
// [ ] ExecuteMsg enum — Transfer, Burn, Mint, UpdateConfig, Freeze, Unfreeze, SetPolicy, EvaluatePolicy, VerifyProof, Migrate
// [ ] QueryMsg — Balance, Config, Policy, ProofStatus, ContractInfo
// [ ] MigrateMsg — version from RICE_* / contract version constant via env!("CARGO_PKG_VERSION")
// [ ] cw_serde on all message types; JSON schema dir from RICE_SCHEMA_OUTPUT_DIR

/// Query response for `config` — referenced from `#[sv::msg(query, resp = ...)]` in `contract.rs`.
#[cw_serde]
pub struct ConfigResponse {
    pub admin: Option<String>,
    pub version: crate::types::ContractVersion,
}
