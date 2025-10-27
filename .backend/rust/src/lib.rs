use cosmwasm_std::{
    entry_point, to_binary, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult,
    Uint128, Addr,
};

use cw2::set_contract_version;
use cw_utils::must_pay;

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg, MigrateMsg};
use crate::state::{Config, CONFIG, TokenInfo, TOKEN_INFO, Balances, BALANCES, Allowances, ALLOWANCES};

// version info for migration info
const CONTRACT_NAME: &str = "crates.io:nori-token";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let config = Config {
        owner: info.sender.clone(),
        minter: msg.minter.unwrap_or_else(|| info.sender.clone()),
        burn_enabled: msg.burn_enabled.unwrap_or(true),
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

    // If initial supply is provided, mint to the owner
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
        .add_attribute("decimals", token_info.decimals.to_string()))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn execute(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::Transfer { recipient, amount } => {
            execute::transfer(deps, info, recipient, amount)
        }
        ExecuteMsg::TransferFrom { owner, recipient, amount } => {
            execute::transfer_from(deps, info, owner, recipient, amount)
        }
        ExecuteMsg::Approve { spender, amount } => {
            execute::approve(deps, info, spender, amount)
        }
        ExecuteMsg::IncreaseAllowance { spender, amount } => {
            execute::increase_allowance(deps, info, spender, amount)
        }
        ExecuteMsg::DecreaseAllowance { spender, amount } => {
            execute::decrease_allowance(deps, info, spender, amount)
        }
        ExecuteMsg::Mint { recipient, amount } => {
            execute::mint(deps, info, recipient, amount)
        }
        ExecuteMsg::Burn { amount } => {
            execute::burn(deps, info, amount)
        }
        ExecuteMsg::BurnFrom { owner, amount } => {
            execute::burn_from(deps, info, owner, amount)
        }
        ExecuteMsg::UpdateMinter { new_minter } => {
            execute::update_minter(deps, info, new_minter)
        }
        ExecuteMsg::UpdateBurnEnabled { burn_enabled } => {
            execute::update_burn_enabled(deps, info, burn_enabled)
        }
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

        // Check if sender has enough balance
        let sender_balance = BALANCES.load(deps.storage, &info.sender)?;
        if sender_balance < amount {
            return Err(ContractError::InsufficientFunds {});
        }

        // Update balances
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
            .add_attribute("amount", amount))
    }

    pub fn transfer_from(
        deps: DepsMut,
        info: MessageInfo,
        owner: String,
        recipient: String,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let owner_addr = deps.api.addr_validate(&owner)?;
        let recipient_addr = deps.api.addr_validate(&recipient)?;

        // Check allowance
        let allowance = ALLOWANCES.load(deps.storage, (&owner_addr, &info.sender))?;
        if allowance < amount {
            return Err(ContractError::InsufficientAllowance {});
        }

        // Check if owner has enough balance
        let owner_balance = BALANCES.load(deps.storage, &owner_addr)?;
        if owner_balance < amount {
            return Err(ContractError::InsufficientFunds {});
        }

        // Update allowance
        ALLOWANCES.update(deps.storage, (&owner_addr, &info.sender), |allowance| -> StdResult<_> {
            Ok(allowance.unwrap_or_default() - amount)
        })?;

        // Update balances
        BALANCES.update(deps.storage, &owner_addr, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() - amount)
        })?;

        BALANCES.update(deps.storage, &recipient_addr, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() + amount)
        })?;

        Ok(Response::new()
            .add_attribute("method", "transfer_from")
            .add_attribute("from", owner)
            .add_attribute("to", recipient)
            .add_attribute("amount", amount))
    }

    pub fn approve(
        deps: DepsMut,
        info: MessageInfo,
        spender: String,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let spender_addr = deps.api.addr_validate(&spender)?;

        ALLOWANCES.save(deps.storage, (&info.sender, &spender_addr), &amount)?;

        Ok(Response::new()
            .add_attribute("method", "approve")
            .add_attribute("owner", info.sender)
            .add_attribute("spender", spender)
            .add_attribute("amount", amount))
    }

    pub fn increase_allowance(
        deps: DepsMut,
        info: MessageInfo,
        spender: String,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let spender_addr = deps.api.addr_validate(&spender)?;

        ALLOWANCES.update(deps.storage, (&info.sender, &spender_addr), |allowance| -> StdResult<_> {
            Ok(allowance.unwrap_or_default() + amount)
        })?;

        Ok(Response::new()
            .add_attribute("method", "increase_allowance")
            .add_attribute("owner", info.sender)
            .add_attribute("spender", spender)
            .add_attribute("amount", amount))
    }

    pub fn decrease_allowance(
        deps: DepsMut,
        info: MessageInfo,
        spender: String,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let spender_addr = deps.api.addr_validate(&spender)?;

        ALLOWANCES.update(deps.storage, (&info.sender, &spender_addr), |allowance| -> StdResult<_> {
            let current = allowance.unwrap_or_default();
            if amount > current {
                return Err(cosmwasm_std::StdError::generic_err("Cannot decrease allowance below zero"));
            }
            Ok(current - amount)
        })?;

        Ok(Response::new()
            .add_attribute("method", "decrease_allowance")
            .add_attribute("owner", info.sender)
            .add_attribute("spender", spender)
            .add_attribute("amount", amount))
    }

    pub fn mint(
        deps: DepsMut,
        info: MessageInfo,
        recipient: String,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let config = CONFIG.load(deps.storage)?;

        // Only minter can mint
        if info.sender != config.minter {
            return Err(ContractError::Unauthorized {});
        }

        let recipient_addr = deps.api.addr_validate(&recipient)?;

        // Update balance
        BALANCES.update(deps.storage, &recipient_addr, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() + amount)
        })?;

        // Update total supply
        TOKEN_INFO.update(deps.storage, |mut info| -> StdResult<_> {
            info.total_supply += amount;
            Ok(info)
        })?;

        Ok(Response::new()
            .add_attribute("method", "mint")
            .add_attribute("to", recipient)
            .add_attribute("amount", amount))
    }

    pub fn burn(
        deps: DepsMut,
        info: MessageInfo,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let config = CONFIG.load(deps.storage)?;

        // Check if burning is enabled
        if !config.burn_enabled {
            return Err(ContractError::BurnDisabled {});
        }

        // Check if sender has enough balance
        let sender_balance = BALANCES.load(deps.storage, &info.sender)?;
        if sender_balance < amount {
            return Err(ContractError::InsufficientFunds {});
        }

        // Update balance
        BALANCES.update(deps.storage, &info.sender, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() - amount)
        })?;

        // Update total supply
        TOKEN_INFO.update(deps.storage, |mut info| -> StdResult<_> {
            info.total_supply = info.total_supply.checked_sub(amount)
                .map_err(|_| cosmwasm_std::StdError::generic_err("Cannot burn more than total supply"))?;
            Ok(info)
        })?;

        Ok(Response::new()
            .add_attribute("method", "burn")
            .add_attribute("from", info.sender)
            .add_attribute("amount", amount))
    }

    pub fn burn_from(
        deps: DepsMut,
        info: MessageInfo,
        owner: String,
        amount: Uint128,
    ) -> Result<Response, ContractError> {
        let config = CONFIG.load(deps.storage)?;

        // Check if burning is enabled
        if !config.burn_enabled {
            return Err(ContractError::BurnDisabled {});
        }

        let owner_addr = deps.api.addr_validate(&owner)?;

        // Check allowance
        let allowance = ALLOWANCES.load(deps.storage, (&owner_addr, &info.sender))?;
        if allowance < amount {
            return Err(ContractError::InsufficientAllowance {});
        }

        // Check if owner has enough balance
        let owner_balance = BALANCES.load(deps.storage, &owner_addr)?;
        if owner_balance < amount {
            return Err(ContractError::InsufficientFunds {});
        }

        // Update allowance
        ALLOWANCES.update(deps.storage, (&owner_addr, &info.sender), |allowance| -> StdResult<_> {
            Ok(allowance.unwrap_or_default() - amount)
        })?;

        // Update balance
        BALANCES.update(deps.storage, &owner_addr, |balance| -> StdResult<_> {
            Ok(balance.unwrap_or_default() - amount)
        })?;

        // Update total supply
        TOKEN_INFO.update(deps.storage, |mut info| -> StdResult<_> {
            info.total_supply = info.total_supply.checked_sub(amount)
                .map_err(|_| cosmwasm_std::StdError::generic_err("Cannot burn more than total supply"))?;
            Ok(info)
        })?;

        Ok(Response::new()
            .add_attribute("method", "burn_from")
            .add_attribute("from", owner)
            .add_attribute("amount", amount))
    }

    pub fn update_minter(
        deps: DepsMut,
        info: MessageInfo,
        new_minter: String,
    ) -> Result<Response, ContractError> {
        let config = CONFIG.load(deps.storage)?;

        // Only owner can update minter
        if info.sender != config.owner {
            return Err(ContractError::Unauthorized {});
        }

        let new_minter_addr = deps.api.addr_validate(&new_minter)?;

        let mut config = config;
        config.minter = new_minter_addr.clone();
        CONFIG.save(deps.storage, &config)?;

        Ok(Response::new()
            .add_attribute("method", "update_minter")
            .add_attribute("new_minter", new_minter))
    }

    pub fn update_burn_enabled(
        deps: DepsMut,
        info: MessageInfo,
        burn_enabled: bool,
    ) -> Result<Response, ContractError> {
        let config = CONFIG.load(deps.storage)?;

        // Only owner can update burn enabled
        if info.sender != config.owner {
            return Err(ContractError::Unauthorized {});
        }

        let mut config = config;
        config.burn_enabled = burn_enabled;
        CONFIG.save(deps.storage, &config)?;

        Ok(Response::new()
            .add_attribute("method", "update_burn_enabled")
            .add_attribute("burn_enabled", burn_enabled.to_string()))
    }
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Balance { address } => to_binary(&query::balance(deps, address)?),
        QueryMsg::TokenInfo {} => to_binary(&query::token_info(deps)?),
        QueryMsg::Minter {} => to_binary(&query::minter(deps)?),
        QueryMsg::Allowance { owner, spender } => to_binary(&query::allowance(deps, owner, spender)?),
        QueryMsg::AllAllowances { owner, start_after, limit } => {
            to_binary(&query::all_allowances(deps, owner, start_after, limit)?)
        }
        QueryMsg::AllAccounts { start_after, limit } => {
            to_binary(&query::all_accounts(deps, start_after, limit)?)
        }
    }
}

pub mod query {
    use super::*;
    use crate::msg::{BalanceResponse, TokenInfoResponse, MinterResponse, AllowanceResponse, AllAllowancesResponse, AllAccountsResponse};
    use cosmwasm_std::Order;

    pub fn balance(deps: Deps, address: String) -> StdResult<BalanceResponse> {
        let address = deps.api.addr_validate(&address)?;
        let balance = BALANCES.load(deps.storage, &address).unwrap_or_default();
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

    pub fn minter(deps: Deps) -> StdResult<MinterResponse> {
        let config = CONFIG.load(deps.storage)?;
        Ok(MinterResponse {
            minter: config.minter.to_string(),
        })
    }

    pub fn allowance(deps: Deps, owner: String, spender: String) -> StdResult<AllowanceResponse> {
        let owner = deps.api.addr_validate(&owner)?;
        let spender = deps.api.addr_validate(&spender)?;
        let allowance = ALLOWANCES.load(deps.storage, (&owner, &spender)).unwrap_or_default();
        Ok(AllowanceResponse {
            allowance,
            expires: None, // No expiration for simplicity
        })
    }

    pub fn all_allowances(
        deps: Deps,
        owner: String,
        start_after: Option<String>,
        limit: Option<u32>,
    ) -> StdResult<AllAllowancesResponse> {
        let owner = deps.api.addr_validate(&owner)?;
        let limit = limit.unwrap_or(30).min(30) as usize;

        let start = start_after.map(|addr| {
            let addr = deps.api.addr_validate(&addr).unwrap();
            (owner.clone(), addr)
        });

        let allowances: StdResult<Vec<_>> = ALLOWANCES
            .prefix(&owner)
            .range(deps.storage, start, None, Order::Ascending)
            .take(limit)
            .map(|item| {
                let ((_, spender), allowance) = item?;
                Ok((spender.to_string(), allowance))
            })
            .collect();

        Ok(AllAllowancesResponse {
            allowances: allowances?,
        })
    }

    pub fn all_accounts(
        deps: Deps,
        start_after: Option<String>,
        limit: Option<u32>,
    ) -> StdResult<AllAccountsResponse> {
        let limit = limit.unwrap_or(30).min(30) as usize;

        let start = start_after.map(|addr| {
            let addr = deps.api.addr_validate(&addr).unwrap();
            addr
        });

        let accounts: StdResult<Vec<_>> = BALANCES
            .range(deps.storage, start, None, Order::Ascending)
            .take(limit)
            .map(|item| {
                let (addr, balance) = item?;
                Ok((addr.to_string(), balance))
            })
            .collect();

        Ok(AllAccountsResponse {
            accounts: accounts?,
        })
    }
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn migrate(deps: DepsMut, _env: Env, _msg: MigrateMsg) -> Result<Response, ContractError> {
    let ver = cw2::get_contract_version(deps.storage)?;
    // ensure we are migrating from an allowed version
    if ver.contract != CONTRACT_NAME {
        return Err(ContractError::Unauthorized {});
    }
    // Note: better to do proper semver comparison, but string compare *usually* works
    if ver.version >= CONTRACT_VERSION {
        return Err(ContractError::Unauthorized {});
    }

    // set the new version info
    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;

    Ok(Response::new()
        .add_attribute("previous_name", ver.contract)
        .add_attribute("previous_version", ver.version)
        .add_attribute("new_name", CONTRACT_NAME)
        .add_attribute("new_version", CONTRACT_VERSION))
}

pub mod error {
    use cosmwasm_std::StdError;
    use thiserror::Error;

    #[derive(Error, Debug)]
    pub enum ContractError {
        #[error("{0}")]
        Std(#[from] StdError),

        #[error("Unauthorized")]
        Unauthorized {},

        #[error("Insufficient funds")]
        InsufficientFunds {},

        #[error("Insufficient allowance")]
        InsufficientAllowance {},

        #[error("Burn disabled")]
        BurnDisabled {},
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
        pub burn_enabled: Option<bool>,
    }

    #[cw_serde]
    pub enum ExecuteMsg {
        Transfer { recipient: String, amount: Uint128 },
        TransferFrom { owner: String, recipient: String, amount: Uint128 },
        Approve { spender: String, amount: Uint128 },
        IncreaseAllowance { spender: String, amount: Uint128 },
        DecreaseAllowance { spender: String, amount: Uint128 },
        Mint { recipient: String, amount: Uint128 },
        Burn { amount: Uint128 },
        BurnFrom { owner: String, amount: Uint128 },
        UpdateMinter { new_minter: String },
        UpdateBurnEnabled { burn_enabled: bool },
    }

    #[cw_serde]
    #[derive(QueryResponses)]
    pub enum QueryMsg {
        #[returns(BalanceResponse)]
        Balance { address: String },
        #[returns(TokenInfoResponse)]
        TokenInfo {},
        #[returns(MinterResponse)]
        Minter {},
        #[returns(AllowanceResponse)]
        Allowance { owner: String, spender: String },
        #[returns(AllAllowancesResponse)]
        AllAllowances { owner: String, start_after: Option<String>, limit: Option<u32> },
        #[returns(AllAccountsResponse)]
        AllAccounts { start_after: Option<String>, limit: Option<u32> },
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
    pub struct MinterResponse {
        pub minter: String,
    }

    #[cw_serde]
    pub struct AllowanceResponse {
        pub allowance: Uint128,
        pub expires: Option<u64>,
    }

    #[cw_serde]
    pub struct AllAllowancesResponse {
        pub allowances: Vec<(String, Uint128)>,
    }

    #[cw_serde]
    pub struct AllAccountsResponse {
        pub accounts: Vec<(String, Uint128)>,
    }
}

#[cw_serde]
pub struct MigrateMsg {}

pub mod state {
    use cosmwasm_schema::cw_serde;
    use cosmwasm_std::{Addr, Uint128};
    use cw_storage_plus::{Item, Map};

    #[cw_serde]
    pub struct Config {
        pub owner: Addr,
        pub minter: Addr,
        pub burn_enabled: bool,
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
    pub const ALLOWANCES: Map<(Addr, Addr), Uint128> = Map::new("allowances");
}
