use cosmwasm_std::{
    entry_point, to_binary, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult,
    Uint128, StdError, Addr,
};

use cw2::set_contract_version;
use cw20::{Cw20ExecuteMsg, Cw20QueryMsg, Cw20ReceiveMsg};
use cw20_base::{
    contract::{execute as cw20_execute, instantiate as cw20_instantiate, query as cw20_query},
    ContractError as Cw20BaseError,
    state::{MinterData, TokenInfo, BALANCES, TOKEN_INFO},
};

pub mod msg;
pub mod state;
pub mod error;

use error::ContractError;
use msg::{ExecuteMsg, InstantiateMsg, QueryMsg, MeowtopiaMintMsg};
use state::{MINTER_CONFIG, GAME_CONFIG, MinterConfig, GameConfig};

// Contract info
const CONTRACT_NAME: &str = "mwt-token";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");

#[entry_point]
pub fn instantiate(
    mut deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    // Set contract version
    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;

    // Create the CW20 token info
    let token_info = TokenInfo {
        name: msg.name.clone(),
        symbol: msg.symbol.clone(),
        decimals: msg.decimals,
        total_supply: Uint128::zero(),
        mint: Some(MinterData {
            minter: info.sender.clone(),
            cap: msg.mint_cap,
        }),
    };

    TOKEN_INFO.save(deps.storage, &token_info)?;

    // Initialize minter configuration for Meowtopia features
    let minter_config = MinterConfig {
        owner: info.sender.clone(),
        can_mint_for_gameplay: true,
        can_mint_for_breeding: true,
        can_mint_for_staking: true,
        max_mint_per_transaction: msg.max_mint_per_tx.unwrap_or(Uint128::new(1000000)),
    };
    MINTER_CONFIG.save(deps.storage, &minter_config)?;

    // Initialize game configuration
    let game_config = GameConfig {
        breeding_cost: msg.breeding_cost.unwrap_or(Uint128::new(100)),
        feeding_cost: msg.feeding_cost.unwrap_or(Uint128::new(10)),
        staking_reward_rate: msg.staking_reward_rate.unwrap_or(Uint128::new(5)), // 5% per period
        tournament_entry_fee: msg.tournament_entry_fee.unwrap_or(Uint128::new(50)),
    };
    GAME_CONFIG.save(deps.storage, &game_config)?;

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("token_name", msg.name)
        .add_attribute("token_symbol", msg.symbol)
        .add_attribute("initial_minter", info.sender)
        .add_attribute("contract_name", CONTRACT_NAME)
        .add_attribute("contract_version", CONTRACT_VERSION))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        // Standard CW20 messages
        ExecuteMsg::Transfer { recipient, amount } => {
            Ok(cw20_execute(deps, env, info, Cw20ExecuteMsg::Transfer { recipient, amount })?)
        }
        ExecuteMsg::Burn { amount } => {
            Ok(cw20_execute(deps, env, info, Cw20ExecuteMsg::Burn { amount })?)
        }
        ExecuteMsg::Send { contract, amount, msg } => {
            Ok(cw20_execute(deps, env, info, Cw20ExecuteMsg::Send { contract, amount, msg })?)
        }
        ExecuteMsg::IncreaseAllowance { spender, amount, expires } => {
            Ok(cw20_execute(deps, env, info, Cw20ExecuteMsg::IncreaseAllowance { spender, amount, expires })?)
        }
        ExecuteMsg::DecreaseAllowance { spender, amount, expires } => {
            Ok(cw20_execute(deps, env, info, Cw20ExecuteMsg::DecreaseAllowance { spender, amount, expires })?)
        }
        ExecuteMsg::TransferFrom { owner, recipient, amount } => {
            Ok(cw20_execute(deps, env, info, Cw20ExecuteMsg::TransferFrom { owner, recipient, amount })?)
        }
        ExecuteMsg::BurnFrom { owner, amount } => {
            Ok(cw20_execute(deps, env, info, Cw20ExecuteMsg::BurnFrom { owner, amount })?)
        }
        ExecuteMsg::SendFrom { owner, contract, amount, msg } => {
            Ok(cw20_execute(deps, env, info, Cw20ExecuteMsg::SendFrom { owner, contract, amount, msg })?)
        }
        
        // Custom Meowtopia messages
        ExecuteMsg::MintForGame { recipient, amount, reason } => {
            execute_mint_for_game(deps, env, info, recipient, amount, reason)
        }
        ExecuteMsg::MintForBreeding { recipient, amount, cat_id } => {
            execute_mint_for_breeding(deps, env, info, recipient, amount, cat_id)
        }
        ExecuteMsg::BurnForActivity { amount, activity } => {
            execute_burn_for_activity(deps, env, info, amount, activity)
        }
        ExecuteMsg::UpdateGameConfig { 
            breeding_cost, 
            feeding_cost, 
            staking_reward_rate, 
            tournament_entry_fee 
        } => {
            execute_update_game_config(deps, env, info, breeding_cost, feeding_cost, staking_reward_rate, tournament_entry_fee)
        }
        ExecuteMsg::UpdateMinterConfig { 
            can_mint_for_gameplay, 
            can_mint_for_breeding, 
            can_mint_for_staking, 
            max_mint_per_transaction 
        } => {
            execute_update_minter_config(deps, env, info, can_mint_for_gameplay, can_mint_for_breeding, can_mint_for_staking, max_mint_per_transaction)
        }
    }
}

// Custom execute functions
pub fn execute_mint_for_game(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    recipient: String,
    amount: Uint128,
    reason: String,
) -> Result<Response, ContractError> {
    let minter_config = MINTER_CONFIG.load(deps.storage)?;
    
    // Check if sender is authorized minter
    if info.sender != minter_config.owner {
        return Err(ContractError::Unauthorized {});
    }

    // Check if gameplay minting is enabled
    if !minter_config.can_mint_for_gameplay {
        return Err(ContractError::GameplayMintingDisabled {});
    }

    // Check mint amount limits
    if amount > minter_config.max_mint_per_transaction {
        return Err(ContractError::ExceedsMaxMint {});
    }

    // Validate recipient address
    let recipient_addr = deps.api.addr_validate(&recipient)?;

    // Mint tokens
    mint_tokens(deps, recipient_addr, amount)?;

    Ok(Response::new()
        .add_attribute("method", "mint_for_game")
        .add_attribute("recipient", recipient)
        .add_attribute("amount", amount)
        .add_attribute("reason", reason))
}

pub fn execute_mint_for_breeding(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    recipient: String,
    amount: Uint128,
    cat_id: String,
) -> Result<Response, ContractError> {
    let minter_config = MINTER_CONFIG.load(deps.storage)?;
    
    // Check if sender is authorized minter
    if info.sender != minter_config.owner {
        return Err(ContractError::Unauthorized {});
    }

    // Check if breeding minting is enabled
    if !minter_config.can_mint_for_breeding {
        return Err(ContractError::BreedingMintingDisabled {});
    }

    // Validate recipient address
    let recipient_addr = deps.api.addr_validate(&recipient)?;

    // Mint tokens
    mint_tokens(deps, recipient_addr, amount)?;

    Ok(Response::new()
        .add_attribute("method", "mint_for_breeding")
        .add_attribute("recipient", recipient)
        .add_attribute("amount", amount)
        .add_attribute("cat_id", cat_id))
}

pub fn execute_burn_for_activity(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    amount: Uint128,
    activity: String,
) -> Result<Response, ContractError> {
    // Burn tokens from sender's balance
    burn_tokens(deps, info.sender.clone(), amount)?;

    Ok(Response::new()
        .add_attribute("method", "burn_for_activity")
        .add_attribute("burner", info.sender)
        .add_attribute("amount", amount)
        .add_attribute("activity", activity))
}

pub fn execute_update_game_config(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    breeding_cost: Option<Uint128>,
    feeding_cost: Option<Uint128>,
    staking_reward_rate: Option<Uint128>,
    tournament_entry_fee: Option<Uint128>,
) -> Result<Response, ContractError> {
    let minter_config = MINTER_CONFIG.load(deps.storage)?;
    
    // Only owner can update config
    if info.sender != minter_config.owner {
        return Err(ContractError::Unauthorized {});
    }

    let mut config = GAME_CONFIG.load(deps.storage)?;
    
    if let Some(cost) = breeding_cost {
        config.breeding_cost = cost;
    }
    if let Some(cost) = feeding_cost {
        config.feeding_cost = cost;
    }
    if let Some(rate) = staking_reward_rate {
        config.staking_reward_rate = rate;
    }
    if let Some(fee) = tournament_entry_fee {
        config.tournament_entry_fee = fee;
    }

    GAME_CONFIG.save(deps.storage, &config)?;

    Ok(Response::new()
        .add_attribute("method", "update_game_config")
        .add_attribute("updated_by", info.sender))
}

pub fn execute_update_minter_config(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    can_mint_for_gameplay: Option<bool>,
    can_mint_for_breeding: Option<bool>,
    can_mint_for_staking: Option<bool>,
    max_mint_per_transaction: Option<Uint128>,
) -> Result<Response, ContractError> {
    let mut config = MINTER_CONFIG.load(deps.storage)?;
    
    // Only owner can update config
    if info.sender != config.owner {
        return Err(ContractError::Unauthorized {});
    }
    
    if let Some(gameplay) = can_mint_for_gameplay {
        config.can_mint_for_gameplay = gameplay;
    }
    if let Some(breeding) = can_mint_for_breeding {
        config.can_mint_for_breeding = breeding;
    }
    if let Some(staking) = can_mint_for_staking {
        config.can_mint_for_staking = staking;
    }
    if let Some(max_mint) = max_mint_per_transaction {
        config.max_mint_per_transaction = max_mint;
    }

    MINTER_CONFIG.save(deps.storage, &config)?;

    Ok(Response::new()
        .add_attribute("method", "update_minter_config")
        .add_attribute("updated_by", info.sender))
}

// Helper functions
fn mint_tokens(deps: DepsMut, recipient: Addr, amount: Uint128) -> Result<(), ContractError> {
    // Update total supply
    let mut token_info = TOKEN_INFO.load(deps.storage)?;
    token_info.total_supply += amount;
    TOKEN_INFO.save(deps.storage, &token_info)?;

    // Update recipient balance
    BALANCES.update(
        deps.storage,
        &recipient,
        |balance: Option<Uint128>| -> StdResult<Uint128> {
            Ok(balance.unwrap_or_default() + amount)
        },
    )?;

    Ok(())
}

fn burn_tokens(deps: DepsMut, owner: Addr, amount: Uint128) -> Result<(), ContractError> {
    // Update owner balance
    BALANCES.update(
        deps.storage,
        &owner,
        |balance: Option<Uint128>| -> StdResult<Uint128> {
            let current_balance = balance.unwrap_or_default();
            if current_balance < amount {
                return Err(StdError::generic_err("Insufficient funds"));
            }
            Ok(current_balance - amount)
        },
    )?;

    // Update total supply
    let mut token_info = TOKEN_INFO.load(deps.storage)?;
    token_info.total_supply -= amount;
    TOKEN_INFO.save(deps.storage, &token_info)?;

    Ok(())
}

#[entry_point]
pub fn query(deps: Deps, env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        // Standard CW20 queries
        QueryMsg::Balance { address } => {
            to_binary(&cw20_query(deps, env, Cw20QueryMsg::Balance { address })?)
        }
        QueryMsg::TokenInfo {} => {
            to_binary(&cw20_query(deps, env, Cw20QueryMsg::TokenInfo {})?)
        }
        QueryMsg::Minter {} => {
            to_binary(&cw20_query(deps, env, Cw20QueryMsg::Minter {})?)
        }
        QueryMsg::Allowance { owner, spender } => {
            to_binary(&cw20_query(deps, env, Cw20QueryMsg::Allowance { owner, spender })?)
        }
        QueryMsg::AllAllowances { owner, start_after, limit } => {
            to_binary(&cw20_query(deps, env, Cw20QueryMsg::AllAllowances { owner, start_after, limit })?)
        }
        QueryMsg::AllAccounts { start_after, limit } => {
            to_binary(&cw20_query(deps, env, Cw20QueryMsg::AllAccounts { start_after, limit })?)
        }
        
        // Custom Meowtopia queries
        QueryMsg::GameConfig {} => {
            to_binary(&GAME_CONFIG.load(deps.storage)?)
        }
        QueryMsg::MinterConfig {} => {
            to_binary(&MINTER_CONFIG.load(deps.storage)?)
        }
    }
}