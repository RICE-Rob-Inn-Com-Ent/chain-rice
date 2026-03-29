//! Sylvia contract — entry points (`instantiate`, `execute`, `query`, `migrate`) and storage handles.

use cosmwasm_std::Response;
use cw_storage_plus::Item;
use sylvia::ctx::{ExecCtx, InstantiateCtx, MigrateCtx, QueryCtx};

use crate::error::ContractError;
use crate::msg::ConfigResponse;
use crate::state::{Config, VersionState};

// [ ] https://cosmwasm.github.io/sylvia/ — https://docs.cosmwasm.com/
// [ ] CONTRACT_NAME / VERSION — cw2::set_contract_version; env!("CARGO_PKG_*") or cue-mapped constants
// [ ] instantiate — deps.api.addr_validate; events; admin from PASETO / env-validated paths
// [ ] #[contract] #[sv::msg(instantiate|execute|query)] — full Sylvia surface
// [ ] pause/unpause — only admin; RICE_* token validation
// [ ] sudo — governance-only; force_transfer, slash — gated by chain

/// Contract storage — add `Map` / `IndexedMap` / `Deque` fields as needed.
pub struct Contract {
    pub config: Item<Config>,
    pub version: Item<VersionState>,
}

#[cfg_attr(not(feature = "library"), sylvia::entry_points)]
#[sylvia::contract]
#[sv::error(ContractError)]
impl Contract {
    pub const fn new() -> Self {
        Self {
            config: Item::new(crate::state::CONFIG_KEY),
            version: Item::new(crate::state::VERSION_KEY),
        }
    }

    #[sv::msg(instantiate)]
    fn instantiate(
        &self,
        ctx: InstantiateCtx,
        admin: Option<String>,
    ) -> Result<Response, ContractError> {
        crate::execute::instantiate(self, ctx, admin)
    }

    #[sv::msg(exec)]
    fn no_op(&self, ctx: ExecCtx) -> Result<Response, ContractError> {
        crate::execute::no_op(ctx)
    }

    #[sv::msg(query, resp = ConfigResponse)]
    fn config(&self, ctx: QueryCtx) -> Result<ConfigResponse, ContractError> {
        crate::query::config(self, ctx)
    }

    #[sv::msg(migrate)]
    fn migrate(
        &self,
        ctx: MigrateCtx,
        target_version: u64,
    ) -> Result<Response, ContractError> {
        crate::migration::migrate(self, ctx, target_version)
    }
}
