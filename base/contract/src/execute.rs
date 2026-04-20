//! Write paths — state mutations, submessages, and events (Sylvia `#[sv::msg(exec)]` dispatch).
//!
//! **Gatekeeper:** [`ensure_unpaused`] on mutating execs. **Authority:** admin-only where required.
//! **Telemetry:** [`crate::event`] builders attached to [`Response`] (no emission helpers in `event.rs`).

use cosmwasm_std::{to_hex, Binary, Response};
use cw2::set_contract_version;
use sylvia::ctx::{ExecCtx, InstantiateCtx};

use crate::crypto;
use crate::error::ContractError;
use crate::event::{
    self, BalanceDirection, EventBalance, EventConfig, EventIntent, IntentStatus,
};
use crate::msg::BalanceAdjustment;
use crate::r#type::{
    Balance, ContractConfig, ContractVersion, IdentityPrincipal, ProofStatus, TokenAmount,
};
use crate::state::{VersionState, CW2_CONTRACT_NAME};
use crate::Contract;

fn event_config_from(cfg: &ContractConfig) -> EventConfig {
    let mut tags = Vec::<&'static str>::new();
    if cfg.zk_enabled {
        tags.push("zk");
    }
    if cfg.pq_enabled {
        tags.push("pq");
    }
    if cfg.is_paused {
        tags.push("pause");
    }
    EventConfig {
        admin: cfg.admin.to_string(),
        policy_engine: cfg
            .policy_engine_address
            .as_ref()
            .map(ToString::to_string)
            .unwrap_or_default(),
        features_active: tags.join(","),
    }
}

pub fn instantiate(
    contract: &Contract,
    ctx: InstantiateCtx,
    admin: Option<String>,
    policy_engine_address: Option<String>,
    zk_enabled: bool,
    pq_enabled: bool,
) -> Result<Response, ContractError> {
    set_contract_version(
        ctx.deps.storage,
        CW2_CONTRACT_NAME,
        env!("CARGO_PKG_VERSION"),
    )?;

    let admin_addr = match admin.as_deref() {
        Some(s) => ctx.deps.api.addr_validate(s)?,
        None => ctx.info.sender.clone(),
    };
    let policy = match policy_engine_address.as_deref() {
        Some(s) if !s.is_empty() => Some(ctx.deps.api.addr_validate(s)?),
        _ => None,
    };
    let mut cfg = ContractConfig::new(admin_addr);
    cfg.policy_engine_address = policy;
    cfg.zk_enabled = zk_enabled;
    cfg.pq_enabled = pq_enabled;
    contract.config.save(ctx.deps.storage, &cfg)?;
    contract.version.save(
        ctx.deps.storage,
        &VersionState {
            current: ContractVersion::default(),
        },
    )?;
    let mut resp = Response::new();
    resp = event::emit_instantiated(resp, Some(cfg.admin.as_str()));
    Ok(resp)
}

fn ensure_unpaused(cfg: &ContractConfig) -> Result<(), ContractError> {
    if cfg.is_paused {
        return Err(ContractError::ContractPaused);
    }
    Ok(())
}

fn ensure_admin(ctx: &ExecCtx, cfg: &ContractConfig) -> Result<(), ContractError> {
    if ctx.info.sender != cfg.admin {
        return Err(ContractError::Unauthorized {
            detail: "only the contract admin may perform this action".into(),
        });
    }
    Ok(())
}

fn principal_contract_addr(principal: &IdentityPrincipal) -> Result<cosmwasm_std::Addr, ContractError> {
    match principal {
        IdentityPrincipal::Contract(addr) => Ok(addr.clone()),
        IdentityPrincipal::PublicKey { .. } => Err(ContractError::Unauthorized {
            detail: "balance ledger is keyed by contract addresses only; public-key principals are not bound yet"
                .into(),
        }),
    }
}

fn intent_trace_id(payload: &[u8]) -> String {
    to_hex(crypto::sha256_digest(payload))
}

pub fn update_config(
    contract: &Contract,
    ctx: ExecCtx,
    admin: Option<String>,
    policy_engine_address: Option<String>,
    zk_enabled: Option<bool>,
    pq_enabled: Option<bool>,
    is_paused: Option<bool>,
) -> Result<Response, ContractError> {
    let mut cfg = contract.config.load(ctx.deps.storage)?;
    ensure_admin(&ctx, &cfg)?;
    if let Some(a) = admin {
        cfg.admin = ctx.deps.api.addr_validate(&a)?;
    }
    if let Some(p) = policy_engine_address {
        cfg.policy_engine_address = if p.is_empty() {
            None
        } else {
            Some(ctx.deps.api.addr_validate(&p)?)
        };
    }
    if let Some(z) = zk_enabled {
        cfg.zk_enabled = z;
    }
    if let Some(p) = pq_enabled {
        cfg.pq_enabled = p;
    }
    if let Some(pa) = is_paused {
        cfg.is_paused = pa;
    }
    contract.config.save(ctx.deps.storage, &cfg)?;
    Ok(Response::new().add_event(event_config_from(&cfg).into_event()))
}

pub fn execute_intent(
    contract: &Contract,
    ctx: ExecCtx,
    payload: Binary,
    proof: Option<Binary>,
) -> Result<Response, ContractError> {
    let cfg = contract.config.load(ctx.deps.storage)?;
    ensure_unpaused(&cfg)?;

    let trace_id = intent_trace_id(payload.as_slice());
    let status = match proof.as_ref() {
        None => ProofStatus::Pending,
        Some(p) if p.is_empty() => {
            return Err(ContractError::ProofInvalid {
                detail: "proof must be omitted or non-empty (96-byte ed25519 pubkey||sig)".into(),
            });
        }
        Some(p) => {
            crypto::verify_intent_proof_ed25519(payload.as_slice(), p.as_slice())?;
            ProofStatus::Verified
        }
    };

    contract
        .proofs
        .save(ctx.deps.storage, trace_id.clone(), &status)?;

    let actor = IdentityPrincipal::Contract(ctx.info.sender.clone());
    let intent_event = EventIntent {
        trace_id,
        actor,
        status: IntentStatus::Success,
        // Contracts do not receive remaining gas in `Env`; indexers may correlate via tx gas.
        gas_used: 0,
    };

    Ok(Response::new().add_event(intent_event.into_event()))
}

pub fn manage_balance(
    contract: &Contract,
    ctx: ExecCtx,
    principal: IdentityPrincipal,
    amount: TokenAmount,
    adjustment: BalanceAdjustment,
) -> Result<Response, ContractError> {
    let cfg = contract.config.load(ctx.deps.storage)?;
    ensure_unpaused(&cfg)?;
    ensure_admin(&ctx, &cfg)?;

    let direction = match &adjustment {
        BalanceAdjustment::Credit => BalanceDirection::Credit,
        BalanceAdjustment::Debit => BalanceDirection::Debit,
    };
    let principal_event = principal.clone();

    let addr = principal_contract_addr(&principal)?;
    let mut bal = contract
        .balances
        .may_load(ctx.deps.storage, addr.clone())?
        .unwrap_or_else(Balance::zero);
    match adjustment {
        BalanceAdjustment::Credit => {
            bal.amount = bal
                .amount
                .checked_add(amount.raw)
                .map_err(|_| ContractError::InvalidAmount {
                    val: "balance credit overflow".into(),
                })?;
        }
        BalanceAdjustment::Debit => {
            bal.amount = bal.amount.checked_sub(amount.raw).map_err(|_| {
                ContractError::InsufficientFunds {
                    required: amount.raw.to_string(),
                    found: bal.amount.to_string(),
                }
            })?;
        }
    }
    if bal.amount.is_zero() {
        contract.balances.remove(ctx.deps.storage, addr.clone());
    } else {
        contract.balances.save(ctx.deps.storage, addr, &bal)?;
    }

    let balance_event = EventBalance {
        principal: principal_event,
        amount_change: amount.raw,
        direction,
    };

    Ok(Response::new().add_event(balance_event.into_event()))
}
