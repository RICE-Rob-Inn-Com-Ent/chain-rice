use cosmwasm_std::{entry_point, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult};
use mwt_token::error::ContractError;
use mwt_token::msg::{ExecuteMsg, InstantiateMsg, MigrateMsg, QueryMsg};
use mwt_token::{execute, instantiate, migrate, query};

#[entry_point]
pub fn instantiate_entry(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    instantiate(deps, env, info, msg)
}

#[entry_point]
pub fn execute_entry(deps: DepsMut, env: Env, info: MessageInfo, msg: ExecuteMsg) -> Result<Response, ContractError> {
    execute(deps, env, info, msg)
}

#[entry_point]
pub fn query_entry(deps: Deps, env: Env, msg: QueryMsg) -> StdResult<Binary> {
    query(deps, env, msg)
}

#[entry_point]
pub fn migrate_entry(deps: DepsMut, env: Env, msg: MigrateMsg) -> Result<Response, ContractError> {
    migrate(deps, env, msg)
}
