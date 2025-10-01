// Chain Rice Smart Contract Library
// Multi-chain integration with CosmWasm, Ethereum, Solana, NEAR, and more

use cosmwasm_std::{Deps, DepsMut, Env, MessageInfo, Response, StdError, StdResult};
use cw2::set_contract_version;
use cw_storage_plus::{Item, Map};
use serde::{Deserialize, Serialize};

const CONTRACT_NAME: &str = "chain-rice-smart-contract";
const CONTRACT_VERSION: &str = "1.0.0";

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct InstantiateMsg {
    pub name: String,
    pub symbol: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg {
    // Multi-chain operations
    BridgeToEthereum(BridgeToEthereumMsg),
    BridgeToSolana(BridgeToSolanaMsg),
    BridgeToNear(BridgeToNearMsg),
    // CosmWasm operations
    Transfer(TransferMsg),
    Mint(MintMsg),
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct BridgeToEthereumMsg {
    pub recipient: String,
    pub amount: u128,
    pub token_address: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct BridgeToSolanaMsg {
    pub recipient: String,
    pub amount: u64,
    pub mint: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct BridgeToNearMsg {
    pub recipient: String,
    pub amount: u128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct TransferMsg {
    pub recipient: String,
    pub amount: u128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct MintMsg {
    pub recipient: String,
    pub amount: u128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    Balance(BalanceQuery),
    Info(InfoQuery),
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct BalanceQuery {
    pub address: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct InfoQuery {}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct BalanceResponse {
    pub balance: u128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct InfoResponse {
    pub name: String,
    pub symbol: String,
    pub total_supply: u128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum QueryResponse {
    Balance(BalanceResponse),
    Info(InfoResponse),
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ContractState {
    pub name: String,
    pub symbol: String,
    pub total_supply: u128,
}

// Storage
const STATE: Item<ContractState> = Item::new("state");
const BALANCES: Map<String, u128> = Map::new("balances");

pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    msg: InstantiateMsg,
) -> StdResult<Response> {
    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;

    // Initialize contract state
    let state = ContractState {
        name: msg.name,
        symbol: msg.symbol,
        total_supply: 0,
    };

    STATE.save(deps.storage, &state)?;

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("name", state.name)
        .add_attribute("symbol", state.symbol))
}

pub fn execute(deps: DepsMut, env: Env, info: MessageInfo, msg: ExecuteMsg) -> StdResult<Response> {
    match msg {
        ExecuteMsg::BridgeToEthereum(bridge_msg) => bridge_to_ethereum(deps, env, info, bridge_msg),
        ExecuteMsg::BridgeToSolana(bridge_msg) => bridge_to_solana(deps, env, info, bridge_msg),
        ExecuteMsg::BridgeToNear(bridge_msg) => bridge_to_near(deps, env, info, bridge_msg),
        ExecuteMsg::Transfer(transfer_msg) => transfer(deps, env, info, transfer_msg),
        ExecuteMsg::Mint(mint_msg) => mint(deps, env, info, mint_msg),
    }
}

pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<QueryResponse> {
    match msg {
        QueryMsg::Balance(balance_query) => {
            let balance = BALANCES.may_load(deps.storage, balance_query.address)?;
            Ok(QueryResponse::Balance(BalanceResponse {
                balance: balance.unwrap_or(0),
            }))
        }
        QueryMsg::Info(_) => {
            let state = STATE.load(deps.storage)?;
            Ok(QueryResponse::Info(InfoResponse {
                name: state.name,
                symbol: state.symbol,
                total_supply: state.total_supply,
            }))
        }
    }
}

fn bridge_to_ethereum(
    _deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    _msg: BridgeToEthereumMsg,
) -> StdResult<Response> {
    // TODO: Implement Ethereum bridge logic
    Ok(Response::new().add_attribute("method", "bridge_to_ethereum"))
}

fn bridge_to_solana(
    _deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    _msg: BridgeToSolanaMsg,
) -> StdResult<Response> {
    // TODO: Implement Solana bridge logic
    Ok(Response::new().add_attribute("method", "bridge_to_solana"))
}

fn bridge_to_near(
    _deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    _msg: BridgeToNearMsg,
) -> StdResult<Response> {
    // TODO: Implement NEAR bridge logic
    Ok(Response::new().add_attribute("method", "bridge_to_near"))
}

fn transfer(deps: DepsMut, _env: Env, info: MessageInfo, msg: TransferMsg) -> StdResult<Response> {
    let sender = info.sender.to_string();
    let recipient = msg.recipient;
    let amount = msg.amount;

    // Check sender balance
    let sender_balance = BALANCES
        .may_load(deps.storage, sender.clone())?
        .unwrap_or(0);
    if sender_balance < amount {
        return Err(StdError::generic_err(format!(
            "Insufficient funds: need {}, have {}",
            amount, sender_balance
        )));
    }

    // Update balances
    BALANCES.save(deps.storage, sender.clone(), &(sender_balance - amount))?;
    let recipient_balance = BALANCES
        .may_load(deps.storage, recipient.clone())?
        .unwrap_or(0);
    BALANCES.save(
        deps.storage,
        recipient.clone(),
        &(recipient_balance + amount),
    )?;

    Ok(Response::new()
        .add_attribute("method", "transfer")
        .add_attribute("from", sender)
        .add_attribute("to", recipient)
        .add_attribute("amount", amount.to_string()))
}

fn mint(deps: DepsMut, _env: Env, _info: MessageInfo, msg: MintMsg) -> StdResult<Response> {
    let recipient = msg.recipient;
    let amount = msg.amount;

    // Update recipient balance
    let current_balance = BALANCES
        .may_load(deps.storage, recipient.clone())?
        .unwrap_or(0);
    BALANCES.save(deps.storage, recipient.clone(), &(current_balance + amount))?;

    // Update total supply
    let mut state = STATE.load(deps.storage)?;
    state.total_supply += amount;
    STATE.save(deps.storage, &state)?;

    Ok(Response::new()
        .add_attribute("method", "mint")
        .add_attribute("to", recipient)
        .add_attribute("amount", amount.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use cosmwasm_std::testing::{mock_dependencies, mock_env, mock_info};
    use cosmwasm_std::{coins, from_binary};

    #[test]
    fn test_instantiate() {
        let mut deps = mock_dependencies();
        let env = mock_env();
        let info = mock_info("creator", &coins(1000, "earth"));

        let msg = InstantiateMsg {
            name: "Chain Rice".to_string(),
            symbol: "RICE".to_string(),
        };

        let res = instantiate(deps.as_mut(), env, info, msg).unwrap();
        assert_eq!(0, res.messages.len());
    }

    #[test]
    fn test_mint() {
        let mut deps = mock_dependencies();
        let env = mock_env();
        let info = mock_info("creator", &[]);

        // First instantiate
        let instantiate_msg = InstantiateMsg {
            name: "Chain Rice".to_string(),
            symbol: "RICE".to_string(),
        };
        instantiate(deps.as_mut(), env.clone(), info.clone(), instantiate_msg).unwrap();

        // Then mint
        let mint_msg = ExecuteMsg::Mint(MintMsg {
            recipient: "user1".to_string(),
            amount: 1000,
        });

        let res = execute(deps.as_mut(), env, info, mint_msg).unwrap();
        assert_eq!(0, res.messages.len());
    }
}
