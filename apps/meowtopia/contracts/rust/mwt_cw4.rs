use cosmwasm_std::{Deps, DepsMut, Env, MessageInfo, Response, StdResult, Binary};

pub fn instantiate(deps: DepsMut, env: Env, info: MessageInfo) -> StdResult<Response> {
    Ok(Response::default())
}

pub fn execute(deps: DepsMut, env: Env, info: MessageInfo, msg: Binary) -> StdResult<Response> {
    Ok(Response::default())
}

pub fn query(deps: Deps, env: Env, msg: Binary) -> StdResult<Binary> {
    Ok(Binary::default())
}
