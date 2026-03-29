//! Public contract API — Sylvia generates `InstantiateMsg`, `ExecMsg`, `QueryMsg`, `MigrateMsg`
//! under `contract::sv` (see Sylvia book). This module re-exports them and adds response DTOs.

pub use crate::contract::sv::{ExecMsg, InstantiateMsg, MigrateMsg, QueryMsg};

/// Alias matching common CosmWasm naming (`ExecuteMsg` vs Sylvia's `ExecMsg`).
pub type ExecuteMsg = ExecMsg;

use cosmwasm_schema::cw_serde;

/// Query response for `config` — referenced from `#[sv::msg(query, resp = ...)]` in `contract.rs`.
#[cw_serde]
pub struct ConfigResponse {
    pub admin: Option<String>,
    pub version: crate::types::ContractVersion,
}
