//! Public `.rice` runtime API — Sylvia generates `ExecMsg`, `InstantiateMsg`, `QueryMsg`, and
//! `MigrateMsg` on the contract’s `#[sv::msg(...)]` impl. This module documents the wire shape and
//! holds shared DTOs referenced by those methods (re-exported from `contract::sv`).
//!
//! # JSON / Proto-JSON naming
//! Keys use **`snake_case`** to align with typical **CUE → OpenAPI/Proto** pipelines (INFRA/MASON).
//! Primitives live in **`crate::type`** (`ContractConfig`, `IdentityPrincipal`, `TokenAmount`,
//! `Balance`, `ProofStatus`).
//!
//! # Instantiate (`InstantiateMsg`)
//! Flat fields: **`admin`**, **`policy_engine_address`**, **`zk_enabled`**, **`pq_enabled`**.
//!
//! # Execute (`ExecuteMsg`)
//! - **`update_config`** — Partial VM config (admin, policy hook, pause, ZK/PQ flags); admin only.
//! - **`execute_intent`** — Primary `.rice` transaction **`payload`** plus optional **`proof`**.
//! - **`manage_balance`** — Admin **`credit`** / **`debit`** of a **`TokenAmount`** for a **`principal`**.
//!
//! # Query (`QueryMsg`)
//! - **`get_config`** — On-chain **`ContractConfig`**.
//! - **`check_balance`** — **`Balance`** for an **`IdentityPrincipal`**.
//! - **`verify_trace`** — **`ProofStatus`** for a **`trace_id`**.

pub use crate::contract::sv::{ExecMsg, InstantiateMsg, MigrateMsg, QueryMsg};

/// Alias matching common CosmWasm naming (`ExecuteMsg` vs Sylvia’s `ExecMsg`).
pub type ExecuteMsg = ExecMsg;

use cosmwasm_schema::cw_serde;

/// Credit or debit for administrative balance movement (`manage_balance` execute message).
#[cw_serde]
pub enum BalanceAdjustment {
    #[serde(rename = "credit")]
    Credit,
    #[serde(rename = "debit")]
    Debit,
}
