use cosmwasm_std::{
    entry_point, to_json_binary, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult,
};

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg};
use crate::state::{Config, TokenInfo, CONFIG, TOKEN_INFO};

pub mod error;
pub mod msg;
pub mod state;

#[cfg(test)]
mod contract;

#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let config = Config {
        owner: info.sender.clone(),
        name: msg.name,
        symbol: msg.symbol,
        decimals: msg.decimals,
        total_supply: msg.initial_supply,
    };

    let token_info = TokenInfo {
        total_supply: msg.initial_supply,
        minted: msg.initial_supply,
    };

    CONFIG.save(deps.storage, &config)?;
    TOKEN_INFO.save(deps.storage, &token_info)?;

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("owner", info.sender)
        .add_attribute("name", config.name)
        .add_attribute("symbol", config.symbol)
        .add_attribute("total_supply", config.total_supply.to_string()))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::Mint { to, amount } => execute_mint(deps, env, info, to, amount),
        ExecuteMsg::Burn { from, amount } => execute_burn(deps, env, info, from, amount),
        ExecuteMsg::Transfer { to, amount } => execute_transfer(deps, env, info, to, amount),
        ExecuteMsg::UpdateOwner { new_owner } => execute_update_owner(deps, env, info, new_owner),
    }
}

pub fn execute_mint(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    to: String,
    amount: u128,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    
    // Only owner can mint
    if info.sender != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    let mut token_info = TOKEN_INFO.load(deps.storage)?;
    token_info.minted += amount;
    token_info.total_supply += amount;

    TOKEN_INFO.save(deps.storage, &token_info)?;

    Ok(Response::new()
        .add_attribute("action", "mint")
        .add_attribute("to", to)
        .add_attribute("amount", amount.to_string()))
}

pub fn execute_burn(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    from: String,
    amount: u128,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    
    // Only owner can burn
    if info.sender != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    let mut token_info = TOKEN_INFO.load(deps.storage)?;
    if token_info.total_supply < amount {
        return Err(ContractError::InsufficientBalance {});
    }

    token_info.total_supply -= amount;
    token_info.minted -= amount;

    TOKEN_INFO.save(deps.storage, &token_info)?;

    Ok(Response::new()
        .add_attribute("action", "burn")
        .add_attribute("from", from)
        .add_attribute("amount", amount.to_string()))
}

pub fn execute_transfer(
    _deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    to: String,
    amount: u128,
) -> Result<Response, ContractError> {
    // For simplicity, we'll just log the transfer
    // In a real implementation, you'd need to track balances per address
    
    Ok(Response::new()
        .add_attribute("action", "transfer")
        .add_attribute("from", info.sender.to_string())
        .add_attribute("to", to)
        .add_attribute("amount", amount.to_string()))
}

pub fn execute_update_owner(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    new_owner: String,
) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;
    
    // Only current owner can update
    if info.sender != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    config.owner = deps.api.addr_validate(&new_owner)?;
    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new()
        .add_attribute("action", "update_owner")
        .add_attribute("new_owner", new_owner))
}

#[entry_point]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::GetConfig {} => to_json_binary(&query_config(deps)?),
        QueryMsg::GetTokenInfo {} => to_json_binary(&query_token_info(deps)?),
        QueryMsg::GetBalance { address: _ } => {
            // For simplicity, return 0 balance
            // In a real implementation, you'd track balances per address
            to_json_binary(&0u128)
        }
    }
}

fn query_config(deps: Deps) -> StdResult<Config> {
    let config = CONFIG.load(deps.storage)?;
    Ok(config)
}

fn query_token_info(deps: Deps) -> StdResult<TokenInfo> {
    let token_info = TOKEN_INFO.load(deps.storage)?;
    Ok(token_info)
}
