use cosmwasm_std::{
    entry_point, to_json_binary, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult,
};

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg};
use crate::state::{Config, TokenInfo, CONFIG, TOKEN_INFO};

pub mod error;
pub mod msg;
pub mod state;

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
        base_uri: msg.base_uri,
        max_supply: msg.max_supply,
    };

    let token_info = TokenInfo {
        total_supply: 0,
        minted: 0,
    };

    CONFIG.save(deps.storage, &config)?;
    TOKEN_INFO.save(deps.storage, &token_info)?;

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("owner", info.sender)
        .add_attribute("name", config.name)
        .add_attribute("symbol", config.symbol))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::Mint { to, token_id, token_uri } => {
            execute_mint(deps, env, info, to, token_id, token_uri)
        }
        ExecuteMsg::Transfer { to, token_id } => {
            execute_transfer(deps, env, info, to, token_id)
        }
        ExecuteMsg::Approve { spender, token_id } => {
            execute_approve(deps, env, info, spender, token_id)
        }
        ExecuteMsg::Burn { token_id } => {
            execute_burn(deps, env, info, token_id)
        }
    }
}

pub fn execute_mint(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    to: String,
    token_id: String,
    token_uri: String,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    
    // Only owner can mint
    if info.sender != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    let mut token_info = TOKEN_INFO.load(deps.storage)?;
    
    // Check max supply
    if token_info.minted >= config.max_supply {
        return Err(ContractError::MaxSupplyReached {});
    }

    token_info.minted += 1;
    token_info.total_supply += 1;

    TOKEN_INFO.save(deps.storage, &token_info)?;

    Ok(Response::new()
        .add_attribute("action", "mint")
        .add_attribute("to", to)
        .add_attribute("token_id", token_id)
        .add_attribute("token_uri", token_uri))
}

pub fn execute_transfer(
    _deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    to: String,
    token_id: String,
) -> Result<Response, ContractError> {
    // For simplicity, we'll just log the transfer
    // In a real implementation, you'd need to track ownership per token
    
    Ok(Response::new()
        .add_attribute("action", "transfer")
        .add_attribute("from", info.sender.to_string())
        .add_attribute("to", to)
        .add_attribute("token_id", token_id))
}

pub fn execute_approve(
    _deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    spender: String,
    token_id: String,
) -> Result<Response, ContractError> {
    // For simplicity, we'll just log the approval
    // In a real implementation, you'd need to track approvals per token
    
    Ok(Response::new()
        .add_attribute("action", "approve")
        .add_attribute("owner", info.sender.to_string())
        .add_attribute("spender", spender)
        .add_attribute("token_id", token_id))
}

pub fn execute_burn(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    token_id: String,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    
    // Only owner can burn
    if info.sender != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    let mut token_info = TOKEN_INFO.load(deps.storage)?;
    token_info.total_supply -= 1;
    token_info.minted -= 1;

    TOKEN_INFO.save(deps.storage, &token_info)?;

    Ok(Response::new()
        .add_attribute("action", "burn")
        .add_attribute("token_id", token_id))
}

#[entry_point]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::GetConfig {} => to_json_binary(&query_config(deps)?),
        QueryMsg::GetTokenInfo {} => to_json_binary(&query_token_info(deps)?),
        QueryMsg::GetToken { token_id: _ } => {
            // For simplicity, return empty token info
            to_json_binary(&"Token not found")
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
