//! **Read-only witness** — `QueryCtx` carries [`cosmwasm_std::Deps`] only (no `DepsMut`); handlers never write storage.
//!
//! Storage layout and key namespaces: [`crate::state`]. Wire / Sylvia query surface: [`crate::msg`] (`QueryMsg`).
//! Domain payloads: [`crate::r#type`].

use sylvia::ctx::QueryCtx;

use crate::Contract;
use crate::error::ContractError;
use crate::r#type::{Balance, ContractConfig, IdentityPrincipal, ProofStatus};

fn principal_to_addr(principal: &IdentityPrincipal) -> Result<cosmwasm_std::Addr, ContractError> {
    match principal {
        IdentityPrincipal::Contract(addr) => Ok(addr.clone()),
        IdentityPrincipal::PublicKey { .. } => Err(ContractError::Unauthorized {
            detail: "balance query is available for contract principals only until PK binding exists".into(),
        }),
    }
}

/// Load the singleton [`ContractConfig`](crate::r#type::ContractConfig) (`crate::state::CONFIG_KEY`).
pub fn get_config(contract: &Contract, ctx: QueryCtx) -> Result<ContractConfig, ContractError> {
    Ok(contract.config.load(ctx.deps.storage)?)
}

/// Resolve [`IdentityPrincipal`] to a ledger [`cosmwasm_std::Addr`], then read [`Balance`] from
/// [`crate::state::BALANCES_KEY`] (missing key → [`Balance::zero`]).
pub fn check_balance(
    contract: &Contract,
    ctx: QueryCtx,
    principal: IdentityPrincipal,
) -> Result<Balance, ContractError> {
    let addr = principal_to_addr(&principal)?;
    Ok(contract
        .balances
        .may_load(ctx.deps.storage, addr)?
        .unwrap_or_else(Balance::zero))
}

/// Look up [`ProofStatus`] for `trace_id` in [`crate::state::PROOFS_KEY`].
/// Missing keys return [`ContractError::TraceNotFound`] (distinct from an on-chain [`ProofStatus::Pending`] row).
pub fn verify_trace(contract: &Contract, ctx: QueryCtx, trace_id: String) -> Result<ProofStatus, ContractError> {
    match contract.proofs.may_load(ctx.deps.storage, trace_id.clone())? {
        Some(status) => Ok(status),
        None => Err(ContractError::TraceNotFound { trace_id }),
    }
}
