//! Write paths — state mutations, submessages, and events (called from Sylvia `#[sv::msg(exec)]`).

use cosmwasm_std::Response;
use sylvia::ctx::{ExecCtx, InstantiateCtx};

use crate::error::ContractError;
use crate::events;
use crate::state::{Config, VersionState};
use crate::types::ContractVersion;
use crate::Contract;

// [ ] https://docs.cosmwasm.com/ — rust_decimal for amounts
// [ ] execute_transfer — balance checks; addr_validate; atomic Map updates; events
// [ ] execute_mint / burn — admin + max supply from config; Decimal math
// [ ] execute_set_policy — CEL string; policies/ validation before store
// [ ] execute_evaluate_policy — policies engine + context from env/cue
// [ ] execute_verify_proof — ark-groth16 verify via private/; proof status in state
// [ ] all amounts: rust_decimal::Decimal — no f64

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
