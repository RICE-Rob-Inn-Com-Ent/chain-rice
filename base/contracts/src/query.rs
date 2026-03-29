//! Read-only queries — no storage writes.

use sylvia::ctx::QueryCtx;

use crate::error::ContractError;
use crate::msg::ConfigResponse;
use crate::state::VersionState;
use crate::Contract;

pub fn config(contract: &Contract, ctx: QueryCtx) -> Result<ConfigResponse, ContractError> {
    let cfg = contract.config.load(ctx.deps.storage)?;
    let ver = contract
        .version
        .load(ctx.deps.storage)
        .unwrap_or(VersionState { current: 0 });
    Ok(ConfigResponse {
        admin: cfg.admin,
        version: ver.current,
    })
}
