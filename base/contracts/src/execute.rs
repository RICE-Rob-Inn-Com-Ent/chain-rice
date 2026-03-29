//! Write paths — state mutations, submessages, and events (called from Sylvia `#[sv::msg(exec)]`).

use cosmwasm_std::Response;
use sylvia::ctx::{ExecCtx, InstantiateCtx};

use crate::error::ContractError;
use crate::events;
use crate::state::{Config, VersionState};
use crate::types::ContractVersion;
use crate::Contract;

pub fn instantiate(
    contract: &Contract,
    ctx: InstantiateCtx,
    admin: Option<String>,
) -> Result<Response, ContractError> {
    let cfg = Config { admin: admin.clone() };
    contract.config.save(ctx.deps.storage, &cfg)?;
    contract.version.save(
        ctx.deps.storage,
        &VersionState {
            current: ContractVersion::default(),
        },
    )?;
    let mut resp = Response::new();
    resp = events::emit_instantiated(resp, admin.as_deref());
    Ok(resp)
}

pub fn no_op(_ctx: ExecCtx) -> Result<Response, ContractError> {
    Ok(Response::new())
}
