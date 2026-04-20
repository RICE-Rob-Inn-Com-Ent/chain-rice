//! **Evolution protocol** — schema bumps ([`crate::state::VersionState`]) + cw2 semver, with **no partial writes**
//! on failure (CosmWasm rolls back the whole `migrate` entry on `Err`).
//!
//! **Authority:** the chain only invokes `migrate` for the code id the admin authorized; this module does not
//! reset sovereign maps unless an explicit, versioned transform says so.

use cosmwasm_std::Response;
use cw2::{ensure_from_older_version, get_contract_version};
use sylvia::ctx::MigrateCtx;

use crate::Contract;
use crate::error::ContractError;
use crate::event;
use crate::state::{CW2_CONTRACT_NAME, VERSION_KEY, VersionState};

/// Apply storage transforms stepping **from** `current + 1` **through** `target` (inclusive).
///
/// Add `match` arms as layout versions are introduced; each arm must be **idempotent-safe** for its target only.
fn migrate_schema_to(
    contract: &Contract,
    storage: &mut dyn cosmwasm_std::Storage,
    target_schema: u64,
) -> Result<(), ContractError> {
    match target_schema {
        1 => {
            // Initial shipped layout (`VERSION_KEY` + cw2) — no key renames or wipes.
            let _ = (contract, storage);
            Ok(())
        },
        _ => Err(ContractError::SerializationError {
            detail: format!(
                "no storage transformation registered for schema version {target_schema}; extend migration.rs ladder"
            ),
        }),
    }
}

pub fn migrate(contract: &Contract, ctx: MigrateCtx, target_version: u64) -> Result<Response, ContractError> {
    let cw2_stored = get_contract_version(ctx.deps.storage)?;
    if cw2_stored.contract != CW2_CONTRACT_NAME {
        return Err(ContractError::Unauthorized {
            detail: format!(
                "cw2 contract id mismatch: expected {CW2_CONTRACT_NAME}, found {}; refusing migration",
                cw2_stored.contract
            ),
        });
    }

    let mut vs = contract.version.load(ctx.deps.storage).unwrap_or(VersionState { current: 0 });
    if target_version <= vs.current {
        return Err(ContractError::MigrationAlreadyApplied {
            current: vs.current,
            requested: target_version,
        });
    }

    for step in (vs.current + 1)..=target_version {
        migrate_schema_to(contract, ctx.deps.storage, step)?;
    }

    vs.current = target_version;
    contract.version.save(ctx.deps.storage, &vs)?;

    let code_version = env!("CARGO_PKG_VERSION");
    ensure_from_older_version(ctx.deps.storage, CW2_CONTRACT_NAME, code_version)?;

    Ok(Response::new()
        .add_event(event::migrated_event(target_version))
        .add_attribute("rice_migration", VERSION_KEY)
        .add_attribute("schema_version", target_version.to_string())
        .add_attribute("cw2_version", code_version))
}
