use cosmwasm_std::{
    entry_point, to_binary, Binary, Deps, DepsMut, Env, MessageInfo,
    Response, StdResult, Uint128, CosmosMsg, WasmMsg, SubMsg,
};
use cw2::set_contract_version;
use cw20_base::{
    contract::{execute as cw20_execute, instantiate as cw20_instantiate, query as cw20_query},
    msg::{ExecuteMsg as Cw20ExecuteMsg, InstantiateMsg as Cw20InstantiateMsg, QueryMsg as Cw20QueryMsg},
    state::{Cw20Contract, TokenInfo},
};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

const CONTRACT_NAME: &str = "crates.io:mwt_dao_cw20";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMsg {
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub initial_balances: Vec<Cw20Coin>,
    pub mint: Option<MinterResponse>,
    pub marketing: Option<InstantiateMarketingInfo>,
    pub dao_governance: Option<DaoGovernanceConfig>,
    pub staking_config: Option<StakingConfig>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Cw20Coin {
    pub address: String,
    pub amount: Uint128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct MinterResponse {
    pub minter: String,
    pub cap: Option<Uint128>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMarketingInfo {
    pub project: Option<String>,
    pub description: Option<String>,
    pub marketing: Option<String>,
    pub logo: Option<Logo>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Logo {
    pub url: Option<String>,
    pub embedded: Option<EmbeddedLogo>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct EmbeddedLogo {
    pub svg: Option<Binary>,
    pub png: Option<Binary>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct DaoGovernanceConfig {
    pub governance_contract: String,
    pub proposal_threshold: Uint128,
    pub voting_period: u64,
    pub quorum: Uint128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct StakingConfig {
    pub staking_contract: String,
    pub reward_rate: Uint128,
    pub lock_period: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg {
    // Standard CW20 messages
    Transfer { recipient: String, amount: Uint128 },
    Send { contract: String, amount: Uint128, msg: Binary },
    Burn { amount: Uint128 },
    Mint { recipient: String, amount: Uint128 },
    
    // DAO-specific messages
    UpdateDaoConfig { config: DaoGovernanceConfig },
    UpdateStakingConfig { config: StakingConfig },
    Stake { amount: Uint128 },
    Unstake { amount: Uint128 },
    ClaimRewards {},
    Vote { proposal_id: u64, vote: VoteOption },
    CreateProposal { title: String, description: String, amount: Uint128 },
    
    // Advanced features
    BatchTransfer { transfers: Vec<TransferRequest> },
    BatchMint { mints: Vec<MintRequest> },
    Pause {},
    Unpause {},
    Blacklist { address: String },
    Unblacklist { address: String },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct TransferRequest {
    pub recipient: String,
    pub amount: Uint128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct MintRequest {
    pub recipient: String,
    pub amount: Uint128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum VoteOption {
    Yes,
    No,
    Abstain,
    Veto,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    // Standard CW20 queries
    Balance { address: String },
    TokenInfo {},
    Minter {},
    AllAllowances { owner: String, start_after: Option<String>, limit: Option<u32> },
    AllAccounts { start_after: Option<String>, limit: Option<u32> },
    
    // DAO-specific queries
    DaoConfig {},
    StakingConfig {},
    StakedBalance { address: String },
    Rewards { address: String },
    Proposals { start_after: Option<u64>, limit: Option<u32> },
    Proposal { id: u64 },
    Votes { proposal_id: u64 },
    
    // Advanced queries
    TotalSupply {},
    CirculatingSupply {},
    IsPaused {},
    Blacklisted { address: String },
    AllBlacklisted { start_after: Option<String>, limit: Option<u32> },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct TokenInfoResponse {
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub total_supply: Uint128,
    pub circulating_supply: Uint128,
    pub dao_config: Option<DaoGovernanceConfig>,
    pub staking_config: Option<StakingConfig>,
    pub is_paused: bool,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct BalanceResponse {
    pub balance: Uint128,
    pub staked_balance: Uint128,
    pub available_balance: Uint128,
    pub rewards: Uint128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct ProposalResponse {
    pub id: u64,
    pub title: String,
    pub description: String,
    pub proposer: String,
    pub amount: Uint128,
    pub status: ProposalStatus,
    pub votes: Vec<VoteInfo>,
    pub created_at: u64,
    pub expires_at: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct VoteInfo {
    pub voter: String,
    pub vote: VoteOption,
    pub amount: Uint128,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ProposalStatus {
    Active,
    Passed,
    Rejected,
    Executed,
    Expired,
}

#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> StdResult<Response> {
    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;
    
    // Convert to CW20 instantiate message
    let cw20_msg = Cw20InstantiateMsg {
        name: msg.name,
        symbol: msg.symbol,
        decimals: msg.decimals,
        initial_balances: msg.initial_balances,
        mint: msg.mint,
        marketing: msg.marketing,
    };
    
    // Call CW20 base instantiate
    let response = cw20_instantiate(deps, env, info, cw20_msg)?;
    
    // Store DAO-specific configurations
    if let Some(dao_config) = msg.dao_governance {
        DAO_CONFIG.save(deps.storage, &dao_config)?;
    }
    
    if let Some(staking_config) = msg.staking_config {
        STAKING_CONFIG.save(deps.storage, &staking_config)?;
    }
    
    // Initialize additional state
    PAUSED.save(deps.storage, &false)?;
    
    Ok(response)
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> StdResult<Response> {
    match msg {
        ExecuteMsg::Transfer { recipient, amount } => {
            if PAUSED.load(deps.storage)? {
                return Err(cosmwasm_std::StdError::generic_err("Contract is paused"));
            }
            
            if is_blacklisted(deps.as_ref(), &info.sender)? {
                return Err(cosmwasm_std::StdError::generic_err("Address is blacklisted"));
            }
            
            let cw20_msg = Cw20ExecuteMsg::Transfer { recipient, amount };
            cw20_execute(deps, env, info, cw20_msg)
        }
        
        ExecuteMsg::Send { contract, amount, msg } => {
            if PAUSED.load(deps.storage)? {
                return Err(cosmwasm_std::StdError::generic_err("Contract is paused"));
            }
            
            let cw20_msg = Cw20ExecuteMsg::Send { contract, amount, msg };
            cw20_execute(deps, env, info, cw20_msg)
        }
        
        ExecuteMsg::Burn { amount } => {
            let cw20_msg = Cw20ExecuteMsg::Burn { amount };
            cw20_execute(deps, env, info, cw20_msg)
        }
        
        ExecuteMsg::Mint { recipient, amount } => {
            let cw20_msg = Cw20ExecuteMsg::Mint { recipient, amount };
            cw20_execute(deps, env, info, cw20_msg)
        }
        
        ExecuteMsg::Stake { amount } => execute_stake(deps, env, info, amount),
        ExecuteMsg::Unstake { amount } => execute_unstake(deps, env, info, amount),
        ExecuteMsg::ClaimRewards {} => execute_claim_rewards(deps, env, info),
        ExecuteMsg::Vote { proposal_id, vote } => execute_vote(deps, env, info, proposal_id, vote),
        ExecuteMsg::CreateProposal { title, description, amount } => {
            execute_create_proposal(deps, env, info, title, description, amount)
        }
        
        ExecuteMsg::UpdateDaoConfig { config } => execute_update_dao_config(deps, env, info, config),
        ExecuteMsg::UpdateStakingConfig { config } => execute_update_staking_config(deps, env, info, config),
        
        ExecuteMsg::BatchTransfer { transfers } => execute_batch_transfer(deps, env, info, transfers),
        ExecuteMsg::BatchMint { mints } => execute_batch_mint(deps, env, info, mints),
        
        ExecuteMsg::Pause {} => execute_pause(deps, env, info),
        ExecuteMsg::Unpause {} => execute_unpause(deps, env, info),
        ExecuteMsg::Blacklist { address } => execute_blacklist(deps, env, info, address),
        ExecuteMsg::Unblacklist { address } => execute_unblacklist(deps, env, info, address),
    }
}

#[entry_point]
pub fn query(deps: Deps, env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Balance { address } => {
            let balance = BALANCES.load(deps.storage, &deps.api.addr_validate(&address)?)?;
            let staked_balance = STAKED_BALANCES.load(deps.storage, &deps.api.addr_validate(&address)?).unwrap_or_default();
            let rewards = REWARDS.load(deps.storage, &deps.api.addr_validate(&address)?).unwrap_or_default();
            
            let response = BalanceResponse {
                balance,
                staked_balance,
                available_balance: balance - staked_balance,
                rewards,
            };
            
            to_binary(&response)
        }
        
        QueryMsg::TokenInfo {} => {
            let token_info = TOKEN_INFO.load(deps.storage)?;
            let dao_config = DAO_CONFIG.may_load(deps.storage)?;
            let staking_config = STAKING_CONFIG.may_load(deps.storage)?;
            let is_paused = PAUSED.load(deps.storage)?;
            
            let response = TokenInfoResponse {
                name: token_info.name,
                symbol: token_info.symbol,
                decimals: token_info.decimals,
                total_supply: token_info.total_supply,
                circulating_supply: token_info.total_supply,
                dao_config,
                staking_config,
                is_paused,
            };
            
            to_binary(&response)
        }
        
        QueryMsg::DaoConfig {} => {
            let config = DAO_CONFIG.load(deps.storage)?;
            to_binary(&config)
        }
        
        QueryMsg::StakingConfig {} => {
            let config = STAKING_CONFIG.load(deps.storage)?;
            to_binary(&config)
        }
        
        QueryMsg::StakedBalance { address } => {
            let staked = STAKED_BALANCES.load(deps.storage, &deps.api.addr_validate(&address)?).unwrap_or_default();
            to_binary(&staked)
        }
        
        QueryMsg::Rewards { address } => {
            let rewards = REWARDS.load(deps.storage, &deps.api.addr_validate(&address)?).unwrap_or_default();
            to_binary(&rewards)
        }
        
        QueryMsg::Proposal { id } => {
            let proposal = PROPOSALS.load(deps.storage, id)?;
            to_binary(&proposal)
        }
        
        QueryMsg::Proposals { start_after, limit } => {
            let proposals = query_proposals(deps, start_after, limit)?;
            to_binary(&proposals)
        }
        
        QueryMsg::Votes { proposal_id } => {
            let votes = VOTES.load(deps.storage, proposal_id)?;
            to_binary(&votes)
        }
        
        QueryMsg::IsPaused {} => {
            let is_paused = PAUSED.load(deps.storage)?;
            to_binary(&is_paused)
        }
        
        QueryMsg::Blacklisted { address } => {
            let is_blacklisted = BLACKLIST.load(deps.storage, &deps.api.addr_validate(&address)?).unwrap_or(false);
            to_binary(&is_blacklisted)
        }
        
        _ => cw20_query(deps, env, msg.into()),
    }
}

// State management
use cw_storage_plus::{Item, Map};

pub const DAO_CONFIG: Item<DaoGovernanceConfig> = Item::new("dao_config");
pub const STAKING_CONFIG: Item<StakingConfig> = Item::new("staking_config");
pub const STAKED_BALANCES: Map<&Addr, Uint128> = Map::new("staked_balances");
pub const REWARDS: Map<&Addr, Uint128> = Map::new("rewards");
pub const PROPOSALS: Map<u64, ProposalResponse> = Map::new("proposals");
pub const VOTES: Map<u64, Vec<VoteInfo>> = Map::new("votes");
pub const PAUSED: Item<bool> = Item::new("paused");
pub const BLACKLIST: Map<&Addr, bool> = Map::new("blacklist");

// Import from cw20_base
use cw20_base::state::{BALANCES, TOKEN_INFO};
use cosmwasm_std::Addr;

// Implementation functions
fn execute_stake(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    amount: Uint128,
) -> StdResult<Response> {
    // Implementation for staking
    let current_staked = STAKED_BALANCES.load(deps.storage, &info.sender).unwrap_or_default();
    STAKED_BALANCES.save(deps.storage, &info.sender, &(current_staked + amount))?;
    
    Ok(Response::new()
        .add_attribute("action", "stake")
        .add_attribute("amount", amount.to_string()))
}

fn execute_unstake(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    amount: Uint128,
) -> StdResult<Response> {
    // Implementation for unstaking
    let current_staked = STAKED_BALANCES.load(deps.storage, &info.sender)?;
    if current_staked < amount {
        return Err(cosmwasm_std::StdError::generic_err("Insufficient staked balance"));
    }
    
    STAKED_BALANCES.save(deps.storage, &info.sender, &(current_staked - amount))?;
    
    Ok(Response::new()
        .add_attribute("action", "unstake")
        .add_attribute("amount", amount.to_string()))
}

fn execute_claim_rewards(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
) -> StdResult<Response> {
    // Implementation for claiming rewards
    let rewards = REWARDS.load(deps.storage, &info.sender).unwrap_or_default();
    if rewards.is_zero() {
        return Err(cosmwasm_std::StdError::generic_err("No rewards to claim"));
    }
    
    REWARDS.save(deps.storage, &info.sender, &Uint128::zero())?;
    
    Ok(Response::new()
        .add_attribute("action", "claim_rewards")
        .add_attribute("amount", rewards.to_string()))
}

fn execute_vote(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    proposal_id: u64,
    vote: VoteOption,
) -> StdResult<Response> {
    // Implementation for voting
    let mut votes = VOTES.load(deps.storage, proposal_id).unwrap_or_default();
    let balance = BALANCES.load(deps.storage, &info.sender)?;
    
    votes.push(VoteInfo {
        voter: info.sender.to_string(),
        vote,
        amount: balance,
    });
    
    VOTES.save(deps.storage, proposal_id, &votes)?;
    
    Ok(Response::new()
        .add_attribute("action", "vote")
        .add_attribute("proposal_id", proposal_id.to_string())
        .add_attribute("vote", format!("{:?}", vote)))
}

fn execute_create_proposal(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    title: String,
    description: String,
    amount: Uint128,
) -> StdResult<Response> {
    // Implementation for creating proposals
    let dao_config = DAO_CONFIG.load(deps.storage)?;
    let balance = BALANCES.load(deps.storage, &info.sender)?;
    
    if balance < dao_config.proposal_threshold {
        return Err(cosmwasm_std::StdError::generic_err("Insufficient balance to create proposal"));
    }
    
    let proposal_id = env.block.time.seconds();
    let proposal = ProposalResponse {
        id: proposal_id,
        title,
        description,
        proposer: info.sender.to_string(),
        amount,
        status: ProposalStatus::Active,
        votes: vec![],
        created_at: env.block.time.seconds(),
        expires_at: env.block.time.seconds() + dao_config.voting_period,
    };
    
    PROPOSALS.save(deps.storage, proposal_id, &proposal)?;
    
    Ok(Response::new()
        .add_attribute("action", "create_proposal")
        .add_attribute("proposal_id", proposal_id.to_string()))
}

fn execute_update_dao_config(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    config: DaoGovernanceConfig,
) -> StdResult<Response> {
    // Only governance contract can update config
    let current_config = DAO_CONFIG.load(deps.storage)?;
    if info.sender != deps.api.addr_validate(&current_config.governance_contract)? {
        return Err(cosmwasm_std::StdError::generic_err("Unauthorized"));
    }
    
    DAO_CONFIG.save(deps.storage, &config)?;
    
    Ok(Response::new()
        .add_attribute("action", "update_dao_config"))
}

fn execute_update_staking_config(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    config: StakingConfig,
) -> StdResult<Response> {
    // Only governance contract can update config
    let dao_config = DAO_CONFIG.load(deps.storage)?;
    if info.sender != deps.api.addr_validate(&dao_config.governance_contract)? {
        return Err(cosmwasm_std::StdError::generic_err("Unauthorized"));
    }
    
    STAKING_CONFIG.save(deps.storage, &config)?;
    
    Ok(Response::new()
        .add_attribute("action", "update_staking_config"))
}

fn execute_batch_transfer(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    transfers: Vec<TransferRequest>,
) -> StdResult<Response> {
    if PAUSED.load(deps.storage)? {
        return Err(cosmwasm_std::StdError::generic_err("Contract is paused"));
    }
    
    let mut total_amount = Uint128::zero();
    let mut messages: Vec<SubMsg> = vec![];
    
    for transfer in transfers {
        total_amount += transfer.amount;
        let msg = Cw20ExecuteMsg::Transfer {
            recipient: transfer.recipient,
            amount: transfer.amount,
        };
        messages.push(SubMsg::new(WasmMsg::Execute {
            contract_addr: env.contract.address.to_string(),
            msg: to_binary(&msg)?,
            funds: vec![],
        }));
    }
    
    // Check sender has enough balance
    let balance = BALANCES.load(deps.storage, &info.sender)?;
    if balance < total_amount {
        return Err(cosmwasm_std::StdError::generic_err("Insufficient balance"));
    }
    
    Ok(Response::new()
        .add_submessages(messages)
        .add_attribute("action", "batch_transfer")
        .add_attribute("total_amount", total_amount.to_string()))
}

fn execute_batch_mint(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    mints: Vec<MintRequest>,
) -> StdResult<Response> {
    let mut messages: Vec<SubMsg> = vec![];
    
    for mint in mints {
        let msg = Cw20ExecuteMsg::Mint {
            recipient: mint.recipient,
            amount: mint.amount,
        };
        messages.push(SubMsg::new(WasmMsg::Execute {
            contract_addr: env.contract.address.to_string(),
            msg: to_binary(&msg)?,
            funds: vec![],
        }));
    }
    
    Ok(Response::new()
        .add_submessages(messages)
        .add_attribute("action", "batch_mint"))
}

fn execute_pause(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
) -> StdResult<Response> {
    // Only governance contract can pause
    let dao_config = DAO_CONFIG.load(deps.storage)?;
    if info.sender != deps.api.addr_validate(&dao_config.governance_contract)? {
        return Err(cosmwasm_std::StdError::generic_err("Unauthorized"));
    }
    
    PAUSED.save(deps.storage, &true)?;
    
    Ok(Response::new()
        .add_attribute("action", "pause"))
}

fn execute_unpause(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
) -> StdResult<Response> {
    // Only governance contract can unpause
    let dao_config = DAO_CONFIG.load(deps.storage)?;
    if info.sender != deps.api.addr_validate(&dao_config.governance_contract)? {
        return Err(cosmwasm_std::StdError::generic_err("Unauthorized"));
    }
    
    PAUSED.save(deps.storage, &false)?;
    
    Ok(Response::new()
        .add_attribute("action", "unpause"))
}

fn execute_blacklist(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    address: String,
) -> StdResult<Response> {
    // Only governance contract can blacklist
    let dao_config = DAO_CONFIG.load(deps.storage)?;
    if info.sender != deps.api.addr_validate(&dao_config.governance_contract)? {
        return Err(cosmwasm_std::StdError::generic_err("Unauthorized"));
    }
    
    let addr = deps.api.addr_validate(&address)?;
    BLACKLIST.save(deps.storage, &addr, &true)?;
    
    Ok(Response::new()
        .add_attribute("action", "blacklist")
        .add_attribute("address", address))
}

fn execute_unblacklist(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    address: String,
) -> StdResult<Response> {
    // Only governance contract can unblacklist
    let dao_config = DAO_CONFIG.load(deps.storage)?;
    if info.sender != deps.api.addr_validate(&dao_config.governance_contract)? {
        return Err(cosmwasm_std::StdError::generic_err("Unauthorized"));
    }
    
    let addr = deps.api.addr_validate(&address)?;
    BLACKLIST.save(deps.storage, &addr, &false)?;
    
    Ok(Response::new()
        .add_attribute("action", "unblacklist")
        .add_attribute("address", address))
}

fn is_blacklisted(deps: Deps, address: &Addr) -> StdResult<bool> {
    Ok(BLACKLIST.load(deps.storage, address).unwrap_or(false))
}

fn query_proposals(
    deps: Deps,
    start_after: Option<u64>,
    limit: Option<u32>,
) -> StdResult<Vec<ProposalResponse>> {
    let limit = limit.unwrap_or(30).min(100) as usize;
    let start = start_after.map(|id| id + 1);
    
    let proposals: StdResult<Vec<_>> = PROPOSALS
        .range(deps.storage, start, None, cosmwasm_std::Order::Ascending)
        .take(limit)
        .collect();
    
    proposals
}

// Schema generation
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
            name: "MeowTopia DAO Token".to_string(),
            symbol: "MWT".to_string(),
            decimals: 6,
            initial_balances: vec![Cw20Coin {
                address: "creator".to_string(),
                amount: Uint128::new(1000000),
            }],
            mint: Some(MinterResponse {
                minter: "creator".to_string(),
                cap: Some(Uint128::new(10000000)),
            }),
            marketing: None,
            dao_governance: Some(DaoGovernanceConfig {
                governance_contract: "governance".to_string(),
                proposal_threshold: Uint128::new(1000),
                voting_period: 604800, // 7 days
                quorum: Uint128::new(10000),
            }),
            staking_config: Some(StakingConfig {
                staking_contract: "staking".to_string(),
                reward_rate: Uint128::new(100),
                lock_period: 86400, // 1 day
            }),
        };

        let res = instantiate(deps.as_mut(), env, info, msg).unwrap();
        assert_eq!(0, res.messages.len());
    }
} 