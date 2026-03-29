//! Migration — `MigrateMsg` handling (Sylvia-generated), version bumps, and storage transforms.

use cosmwasm_std::Response;
use sylvia::ctx::MigrateCtx;

use crate::error::ContractError;
use crate::state::VersionState;
use crate::Contract;

pub fn migrate(
    contract: &Contract,
    ctx: MigrateCtx,
    target_version: u64,
) -> Result<Response, ContractError> {
    let mut vs = contract
        .version
        .load(ctx.deps.storage)
        .unwrap_or(VersionState { current: 0 });
    if target_version <= vs.current {
        return Err(ContractError::MigrationAlreadyApplied {
            current: vs.current,
            requested: target_version,
        });
    }
    vs.current = target_version;
    contract.version.save(ctx.deps.storage, &vs)?;
    Ok(Response::new())
}
