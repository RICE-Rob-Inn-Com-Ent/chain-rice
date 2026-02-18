use cosmwasm_std::{
    entry_point, to_binary, Addr, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult, Uint128,
};
use cw2::set_contract_version;
use cw_storage_plus::{Item, Map};

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg};
use crate::state::{Config, TokenInfo, BALANCES, CONFIG, TOKEN_INFO};

const CONTRACT_NAME: &str = "crates.io:cxt-token";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");

// ChainRice blockchain uses prefix "crice" for addresses
// All addresses must start with "crice1"

pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    // Verify address starts with crice1
    if !info.sender.as_str().starts_with("crice1") {
        return Err(ContractError::InvalidAddress { address: info.sender.to_string() });
    }

    let minter_addr = if let Some(minter) = msg.minter {
        deps.api.addr_validate(&minter)?
    } else {
        info.sender.clone()
    };

    let config = Config {
        owner: info.sender.clone(),
        minter: minter_addr,
    };

    let token_info = TokenInfo {
        name: msg.name,
        symbol: msg.symbol,
        decimals: msg.decimals,
        total_supply: Uint128::zero(),
    };

    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;
    CONFIG.save(deps.storage, &config)?;
    TOKEN_INFO.save(deps.storage, &token_info)?;

    if let Some(initial_supply) = msg.initial_supply {
        if initial_supply > Uint128::zero() {
            BALANCES.update(deps.storage, &info.sender, |balance| -> StdResult<_> {
                Ok(balance.unwrap_or_default() + initial_supply)
            })?;

            TOKEN_INFO.update(deps.storage, |mut info| -> StdResult<_> {
                info.total_supply = initial_supply;
                Ok(info)
            })?;
        }
    }

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("owner", info.sender)
        .add_attribute("name", token_info.name)
        .add_attribute("symbol", token_info.symbol)
        .add_attribute("chain", "ChainRice")
        .add_attribute("prefix", "crice1"))
}

pub fn execute(deps: DepsMut, _env: Env, info: MessageInfo, msg: ExecuteMsg) -> Result<Response, ContractError> {
    // Verify sender address starts with crice1
    if !info.sender.as_str().starts_with("crice1") {
        return Err(ContractError::InvalidAddress { address: info.sender.to_string() });
    }

    match msg {
        ExecuteMsg::Transfer { recipient, amount } => {
            // Verify recipient address
            let recipient_addr = deps.api.addr_validate(&recipient)?;
            if !recipient_addr.as_str().starts_with("crice1") {
                return Err(ContractError::InvalidAddress { address: recipient });
            }
            execute::transfer(deps, info, recipient, amount)
        },
        ExecuteMsg::Mint { recipient, amount } => {
            // Verify recipient address
            let recipient_addr = deps.api.addr_validate(&recipient)?;
            if !recipient_addr.as_str().starts_with("crice1") {
                return Err(ContractError::InvalidAddress { address: recipient });
            }
            execute::mint(deps, info, recipient, amount)
        },
        ExecuteMsg::Burn { amount } => execute::burn(deps, info, amount),
    }
}

pub mod execute {
    use super::*;

    pub fn transfer(
        deps: DepsMut,
        info: MessageInfo,
        recipient: String,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let recipient_addr = deps.api.addr_validate(&recipient)?;
        let sender_balance = BALANCES.load(deps.storage, &info.sender)?;

        if sender_balance < amount {
            return Err(ContractError::InsufficientFunds {});
        }

        BALANCES.update(deps.storage, &info.sender, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() - amount)
        })?;

        BALANCES.update(deps.storage, &recipient_addr, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() + amount)
        })?;

        Ok(Response::new()
            .add_attribute("method", "transfer")
            .add_attribute("from", info.sender)
            .add_attribute("to", recipient)
            .add_attribute("amount", amount)
            .add_attribute("chain", "ChainRice"))
    }

    pub fn mint(
        deps: DepsMut,
        info: MessageInfo,
        recipient: String,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let config = CONFIG.load(deps.storage)?;
        if info.sender != config.minter {
            return Err(ContractError::Unauthorized {});
        }

        let recipient_addr = deps.api.addr_validate(&recipient)?;
        BALANCES.update(deps.storage, &recipient_addr, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() + amount)
        })?;

        TOKEN_INFO.update(deps.storage, |mut info| -> StdResult<_> {
            info.total_supply += amount;
            Ok(info)
        })?;

        Ok(Response::new()
            .add_attribute("method", "mint")
            .add_attribute("to", recipient)
            .add_attribute("amount", amount)
            .add_attribute("chain", "ChainRice"))
    }

    pub fn burn(deps: DepsMut, info: MessageInfo, amount: Uint128) -> Result<Response, ContractError> {
        let sender_balance = BALANCES.load(deps.storage, &info.sender)?;
        if sender_balance < amount {
            return Err(ContractError::InsufficientFunds {});
        }

        BALANCES.update(deps.storage, &info.sender, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() - amount)
        })?;

        TOKEN_INFO.update(deps.storage, |mut info| -> StdResult<_> {
            info.total_supply = info
                .total_supply
                .checked_sub(amount)
                .map_err(|_| cosmwasm_std::StdError::generic_err("Cannot burn more than total supply"))?;
            Ok(info)
        })?;

        Ok(Response::new()
            .add_attribute("method", "burn")
            .add_attribute("from", info.sender)
            .add_attribute("amount", amount)
            .add_attribute("chain", "ChainRice"))
    }
}

pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Balance { address } => to_binary(&query::balance(deps, address)?),
        QueryMsg::TokenInfo {} => to_binary(&query::token_info(deps)?),
    }
}

pub mod query {
    use super::*;
    use crate::msg::{BalanceResponse, TokenInfoResponse};

    pub fn balance(deps: Deps, address: String) -> StdResult<BalanceResponse> {
        let address = deps.api.addr_validate(&address)?;
        if !address.as_str().starts_with("crice1") {
            return Err(cosmwasm_std::StdError::generic_err(format!(
                "Invalid address: must start with crice1, got {}",
                address
            )));
        }
        let balance = BALANCES.load(deps.storage, address).unwrap_or_default();
        Ok(BalanceResponse { balance })
    }

    pub fn token_info(deps: Deps) -> StdResult<TokenInfoResponse> {
        let token_info = TOKEN_INFO.load(deps.storage)?;
        Ok(TokenInfoResponse {
            name: token_info.name,
            symbol: token_info.symbol,
            decimals: token_info.decimals,
            total_supply: token_info.total_supply,
        })
    }
}

pub fn migrate(deps: DepsMut, _env: Env, _msg: crate::msg::MigrateMsg) -> Result<Response, ContractError> {
    let ver = cw2::get_contract_version(deps.storage)?;
    if ver.contract != CONTRACT_NAME {
        return Err(ContractError::Unauthorized {});
    }
    if ver.version >= CONTRACT_VERSION.to_string() {
        return Err(ContractError::Unauthorized {});
    }

    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;

    Ok(Response::new()
        .add_attribute("previous_version", ver.version)
        .add_attribute("new_version", CONTRACT_VERSION)
        .add_attribute("chain", "ChainRice"))
}

pub mod error {
    use cosmwasm_std::StdError;
    use thiserror::Error;

    #[derive(Error, Debug, PartialEq)]
    pub enum ContractError {
        #[error("{0}")]
        Std(#[from] StdError),

        #[error("Unauthorized")]
        Unauthorized {},

        #[error("Insufficient funds")]
        InsufficientFunds {},

        #[error("Invalid address: {address}. Address must start with 'crice1'")]
        InvalidAddress { address: String },
    }
}

pub mod msg {
    use cosmwasm_schema::{cw_serde, QueryResponses};
    use cosmwasm_std::Uint128;

    #[cw_serde]
    pub struct InstantiateMsg {
        pub name: String,
        pub symbol: String,
        pub decimals: u8,
        pub initial_supply: Option<Uint128>,
        pub minter: Option<String>,
    }

    #[cw_serde]
    pub enum ExecuteMsg {
        Transfer { recipient: String, amount: Uint128 },
        Mint { recipient: String, amount: Uint128 },
        Burn { amount: Uint128 },
    }

    #[cw_serde]
    #[derive(QueryResponses)]
    pub enum QueryMsg {
        #[returns(BalanceResponse)]
        Balance { address: String },
        #[returns(TokenInfoResponse)]
        TokenInfo {},
    }

    #[cw_serde]
    pub struct BalanceResponse {
        pub balance: Uint128,
    }

    #[cw_serde]
    pub struct TokenInfoResponse {
        pub name: String,
        pub symbol: String,
        pub decimals: u8,
        pub total_supply: Uint128,
    }

    #[cw_serde]
    pub struct MigrateMsg {}
}

pub mod state {
    use cosmwasm_schema::cw_serde;
    use cosmwasm_std::{Addr, Uint128};
    use cw_storage_plus::{Item, Map};

    #[cw_serde]
    pub struct Config {
        pub owner: Addr,
        pub minter: Addr,
    }

    #[cw_serde]
    pub struct TokenInfo {
        pub name: String,
        pub symbol: String,
        pub decimals: u8,
        pub total_supply: Uint128,
    }

    pub const CONFIG: Item<Config> = Item::new("config");
    pub const TOKEN_INFO: Item<TokenInfo> = Item::new("token_info");
    pub const BALANCES: Map<Addr, Uint128> = Map::new("balances");
}
