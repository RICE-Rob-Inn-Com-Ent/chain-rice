//! **`.rice` dispatcher** — Sylvia contract shell: storage handles, `#[sv::msg]`, and **strict delegation**
//! to [`crate::execute`], [`crate::query`], and [`crate::migration`]. No business logic here.

use cosmwasm_std::{Addr, Binary, Response};
use cw_storage_plus::{Item, Map, SnapshotMap};
use sylvia::ctx::{ExecCtx, InstantiateCtx, MigrateCtx, QueryCtx};

use crate::error::ContractError;
use crate::msg::BalanceAdjustment;
use crate::state::{BALANCES_KEY, CONFIG_KEY, PROOFS_KEY, VERSION_KEY, VersionState, governance_weights_snapshot};
use crate::r#type::{Balance, ContractConfig, IdentityPrincipal, ProofStatus, TokenAmount};

/// Sovereign storage — keys and [`SnapshotMap`] strategy from [`crate::state`].
pub struct Contract {
    pub config: Item<ContractConfig>,
    pub version: Item<VersionState>,
    pub balances: Map<Addr, Balance>,
    pub proofs: Map<String, ProofStatus>,
    pub governance_weights: SnapshotMap<Addr, Balance>,
}

#[cfg_attr(not(feature = "library"), sylvia::entry_points)]
#[sylvia::contract]
#[sv::error(ContractError)]
impl Contract {
    #[must_use]
    pub const fn new() -> Self {
        Self {
            config: Item::new(CONFIG_KEY),
            version: Item::new(VERSION_KEY),
            balances: Map::new(BALANCES_KEY),
            proofs: Map::new(PROOFS_KEY),
            governance_weights: governance_weights_snapshot(),
        }
    }

    #[sv::msg(instantiate)]
    fn instantiate(
        &self,
        ctx: InstantiateCtx,
        #[serde(default)] admin: Option<String>,
        #[serde(default)] policy_engine_address: Option<String>,
        #[serde(default)] zk_enabled: bool,
        #[serde(default)] pq_enabled: bool,
    ) -> Result<Response, ContractError> {
        crate::execute::instantiate(self, ctx, admin, policy_engine_address, zk_enabled, pq_enabled)
    }

    #[sv::msg(exec)]
    fn update_config(
        &self,
        ctx: ExecCtx,
        #[serde(default)] admin: Option<String>,
        #[serde(default)] policy_engine_address: Option<String>,
        #[serde(default)] zk_enabled: Option<bool>,
        #[serde(default)] pq_enabled: Option<bool>,
        #[serde(default)] is_paused: Option<bool>,
    ) -> Result<Response, ContractError> {
        crate::execute::update_config(self, ctx, admin, policy_engine_address, zk_enabled, pq_enabled, is_paused)
    }

    #[sv::msg(exec)]
    fn execute_intent(
        &self,
        ctx: ExecCtx,
        payload: Binary,
        #[serde(default, skip_serializing_if = "Option::is_none")] proof: Option<Binary>,
    ) -> Result<Response, ContractError> {
        crate::execute::execute_intent(self, ctx, payload, proof)
    }

    #[sv::msg(exec)]
    fn manage_balance(
        &self,
        ctx: ExecCtx,
        principal: IdentityPrincipal,
        amount: TokenAmount,
        adjustment: BalanceAdjustment,
    ) -> Result<Response, ContractError> {
        crate::execute::manage_balance(self, ctx, principal, amount, adjustment)
    }

    #[sv::msg(query, resp = ContractConfig)]
    fn get_config(&self, ctx: QueryCtx) -> Result<ContractConfig, ContractError> {
        crate::query::get_config(self, ctx)
    }

    #[sv::msg(query, resp = Balance)]
    fn check_balance(&self, ctx: QueryCtx, principal: IdentityPrincipal) -> Result<Balance, ContractError> {
        crate::query::check_balance(self, ctx, principal)
    }

    #[sv::msg(query, resp = ProofStatus)]
    fn verify_trace(&self, ctx: QueryCtx, trace_id: String) -> Result<ProofStatus, ContractError> {
        crate::query::verify_trace(self, ctx, trace_id)
    }

    #[sv::msg(migrate)]
    fn migrate(&self, ctx: MigrateCtx, target_version: u64) -> Result<Response, ContractError> {
        crate::migration::migrate(self, ctx, target_version)
    }
}
