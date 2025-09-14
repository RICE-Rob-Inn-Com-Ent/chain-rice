#!/bin/bash

# Chain Rice Smart Contract Generator
# Generates various types of CosmWasm smart contracts

set -e

CONTRACT_NAME=""
CONTRACT_TYPE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo -e "${BLUE}🌾 Chain Rice Smart Contract Generator${NC}"
    echo "=========================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --name NAME        Contract name (required)"
    echo "  -t, --type TYPE        Contract type (required)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Available contract types:"
    echo "  cw20                  CW20 Token Contract"
    echo "  dao                   DAO Governance Contract"
    echo "  nft                   NFT Collection Contract"
    echo "  marketplace           NFT Marketplace Contract"
    echo "  staking               Staking Contract"
    echo "  vesting               Token Vesting Contract"
    echo ""
    echo "Examples:"
    echo "  $0 -n my-token -t cw20"
    echo "  $0 -n rice-dao -t dao"
    echo "  $0 -n rice-nfts -t nft"
}

generate_cw20() {
    echo -e "${GREEN}🚀 Generating CW20 Token Contract: $CONTRACT_NAME${NC}"
    
    mkdir -p contracts/$CONTRACT_NAME
    cd contracts/$CONTRACT_NAME
    
    # Create Cargo.toml
    cat > Cargo.toml << EOF
[package]
name = "$CONTRACT_NAME"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
cosmwasm-std = "1.4"
cosmwasm-storage = "1.4"
cw-storage-plus = "1.0"
schemars = "0.8"
serde = { version = "1.0", default-features = false, features = ["derive"] }
thiserror = "1.0"

[dev-dependencies]
cosmwasm-schema = "1.4"
cw-multi-test = "1.0"
EOF

    # Create src directory structure
    mkdir -p src
    
    # Copy from existing CW20 contract
    cp ../../src/*.rs src/
    
    echo -e "${GREEN}✅ CW20 contract generated successfully!${NC}"
    echo -e "${YELLOW}📁 Location: contracts/$CONTRACT_NAME/${NC}"
    echo -e "${YELLOW}🔧 Run: cd contracts/$CONTRACT_NAME && cargo build${NC}"
}

generate_dao() {
    echo -e "${GREEN}🏛️ Generating DAO Contract: $CONTRACT_NAME${NC}"
    
    mkdir -p contracts/$CONTRACT_NAME
    cd contracts/$CONTRACT_NAME
    
    # Create Cargo.toml
    cat > Cargo.toml << EOF
[package]
name = "$CONTRACT_NAME"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
cosmwasm-std = "1.4"
cosmwasm-storage = "1.4"
cw-storage-plus = "1.0"
cw-utils = "1.0"
schemars = "0.8"
serde = { version = "1.0", default-features = false, features = ["derive"] }
thiserror = "1.0"

[dev-dependencies]
cosmwasm-schema = "1.4"
cw-multi-test = "1.0"
EOF

    # Create src directory structure
    mkdir -p src
    
    # Generate DAO contract files
    generate_dao_files
    
    echo -e "${GREEN}✅ DAO contract generated successfully!${NC}"
    echo -e "${YELLOW}📁 Location: contracts/$CONTRACT_NAME/${NC}"
    echo -e "${YELLOW}🔧 Run: cd contracts/$CONTRACT_NAME && cargo build${NC}"
}

generate_nft() {
    echo -e "${GREEN}🎨 Generating NFT Contract: $CONTRACT_NAME${NC}"
    
    mkdir -p contracts/$CONTRACT_NAME
    cd contracts/$CONTRACT_NAME
    
    # Create Cargo.toml
    cat > Cargo.toml << EOF
[package]
name = "$CONTRACT_NAME"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
cosmwasm-std = "1.4"
cosmwasm-storage = "1.4"
cw-storage-plus = "1.0"
cw-utils = "1.0"
schemars = "0.8"
serde = { version = "1.0", default-features = false, features = ["derive"] }
thiserror = "1.0"

[dev-dependencies]
cosmwasm-schema = "1.4"
cw-multi-test = "1.0"
EOF

    # Create src directory structure
    mkdir -p src
    
    # Generate NFT contract files
    generate_nft_files
    
    echo -e "${GREEN}✅ NFT contract generated successfully!${NC}"
    echo -e "${YELLOW}📁 Location: contracts/$CONTRACT_NAME/${NC}"
    echo -e "${YELLOW}🔧 Run: cd contracts/$CONTRACT_NAME && cargo build${NC}"
}

generate_dao_files() {
    # Create lib.rs
    cat > src/lib.rs << 'EOF'
use cosmwasm_std::{
    entry_point, to_json_binary, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult,
};

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg};
use crate::state::{Config, Proposal, CONFIG, PROPOSALS};

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
        admin: info.sender.clone(),
        name: msg.name,
        description: msg.description,
        voting_period: msg.voting_period,
        quorum: msg.quorum,
        threshold: msg.threshold,
    };

    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("admin", info.sender)
        .add_attribute("name", config.name))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::CreateProposal { title, description, proposal_type } => {
            execute_create_proposal(deps, env, info, title, description, proposal_type)
        }
        ExecuteMsg::Vote { proposal_id, vote } => {
            execute_vote(deps, env, info, proposal_id, vote)
        }
        ExecuteMsg::ExecuteProposal { proposal_id } => {
            execute_proposal(deps, env, info, proposal_id)
        }
    }
}

pub fn execute_create_proposal(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    title: String,
    description: String,
    proposal_type: String,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    
    // Only admin can create proposals
    if info.sender != config.admin {
        return Err(ContractError::Unauthorized {});
    }

    let proposal_id = env.block.height;
    let proposal = Proposal {
        id: proposal_id,
        title,
        description,
        proposal_type,
        proposer: info.sender.clone(),
        status: "active".to_string(),
        votes_for: 0,
        votes_against: 0,
        created_at: env.block.time,
        voting_end: env.block.time.plus_seconds(config.voting_period),
    };

    PROPOSALS.save(deps.storage, proposal_id, &proposal)?;

    Ok(Response::new()
        .add_attribute("action", "create_proposal")
        .add_attribute("proposal_id", proposal_id.to_string())
        .add_attribute("proposer", info.sender))
}

pub fn execute_vote(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    proposal_id: u64,
    vote: String,
) -> Result<Response, ContractError> {
    let mut proposal = PROPOSALS.load(deps.storage, proposal_id)?;
    
    // Check if voting period is still active
    if env.block.time > proposal.voting_end {
        return Err(ContractError::VotingPeriodEnded {});
    }

    // Check if proposal is still active
    if proposal.status != "active" {
        return Err(ContractError::ProposalNotActive {});
    }

    // Update vote counts
    match vote.as_str() {
        "yes" => proposal.votes_for += 1,
        "no" => proposal.votes_against += 1,
        _ => return Err(ContractError::InvalidVote {}),
    }

    PROPOSALS.save(deps.storage, proposal_id, &proposal)?;

    Ok(Response::new()
        .add_attribute("action", "vote")
        .add_attribute("proposal_id", proposal_id.to_string())
        .add_attribute("voter", info.sender)
        .add_attribute("vote", vote))
}

pub fn execute_proposal(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    proposal_id: u64,
) -> Result<Response, ContractError> {
    let mut proposal = PROPOSALS.load(deps.storage, proposal_id)?;
    let config = CONFIG.load(deps.storage)?;
    
    // Only admin can execute proposals
    if info.sender != config.admin {
        return Err(ContractError::Unauthorized {});
    }

    // Check if voting period has ended
    if env.block.time <= proposal.voting_end {
        return Err(ContractError::VotingPeriodActive {});
    }

    // Check if proposal passed
    let total_votes = proposal.votes_for + proposal.votes_against;
    if total_votes < config.quorum {
        proposal.status = "rejected".to_string();
        PROPOSALS.save(deps.storage, proposal_id, &proposal)?;
        return Err(ContractError::QuorumNotMet {});
    }

    let threshold_met = (proposal.votes_for as f64 / total_votes as f64) >= config.threshold;
    
    if threshold_met {
        proposal.status = "passed".to_string();
    } else {
        proposal.status = "rejected".to_string();
    }

    PROPOSALS.save(deps.storage, proposal_id, &proposal)?;

    Ok(Response::new()
        .add_attribute("action", "execute_proposal")
        .add_attribute("proposal_id", proposal_id.to_string())
        .add_attribute("status", proposal.status.clone()))
}

#[entry_point]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::GetConfig {} => to_json_binary(&query_config(deps)?),
        QueryMsg::GetProposal { id } => to_json_binary(&query_proposal(deps, id)?),
        QueryMsg::ListProposals {} => to_json_binary(&query_proposals(deps)?),
    }
}

fn query_config(deps: Deps) -> StdResult<Config> {
    let config = CONFIG.load(deps.storage)?;
    Ok(config)
}

fn query_proposal(deps: Deps, id: u64) -> StdResult<Proposal> {
    let proposal = PROPOSALS.load(deps.storage, id)?;
    Ok(proposal)
}

fn query_proposals(deps: Deps) -> StdResult<Vec<Proposal>> {
    let proposals: StdResult<Vec<_>> = PROPOSALS
        .range(deps.storage, None, None, cosmwasm_std::Order::Ascending)
        .collect();
    Ok(proposals?)
}
EOF

    # Create error.rs
    cat > src/error.rs << 'EOF'
use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("Voting period has ended")]
    VotingPeriodEnded {},

    #[error("Voting period is still active")]
    VotingPeriodActive {},

    #[error("Proposal is not active")]
    ProposalNotActive {},

    #[error("Invalid vote")]
    InvalidVote {},

    #[error("Quorum not met")]
    QuorumNotMet {},
}
EOF

    # Create msg.rs
    cat > src/msg.rs << 'EOF'
use cosmwasm_std::Addr;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMsg {
    pub name: String,
    pub description: String,
    pub voting_period: u64,
    pub quorum: u64,
    pub threshold: f64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub enum ExecuteMsg {
    CreateProposal {
        title: String,
        description: String,
        proposal_type: String,
    },
    Vote {
        proposal_id: u64,
        vote: String,
    },
    ExecuteProposal {
        proposal_id: u64,
    },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub enum QueryMsg {
    GetConfig {},
    GetProposal { id: u64 },
    ListProposals {},
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Config {
    pub admin: Addr,
    pub name: String,
    pub description: String,
    pub voting_period: u64,
    pub quorum: u64,
    pub threshold: f64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Proposal {
    pub id: u64,
    pub title: String,
    pub description: String,
    pub proposal_type: String,
    pub proposer: Addr,
    pub status: String,
    pub votes_for: u64,
    pub votes_against: u64,
    pub created_at: cosmwasm_std::Timestamp,
    pub voting_end: cosmwasm_std::Timestamp,
}
EOF

    # Create state.rs
    cat > src/state.rs << 'EOF'
use cosmwasm_std::Addr;
use cw_storage_plus::{Item, Map};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Config {
    pub admin: Addr,
    pub name: String,
    pub description: String,
    pub voting_period: u64,
    pub quorum: u64,
    pub threshold: f64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Proposal {
    pub id: u64,
    pub title: String,
    pub description: String,
    pub proposal_type: String,
    pub proposer: Addr,
    pub status: String,
    pub votes_for: u64,
    pub votes_against: u64,
    pub created_at: cosmwasm_std::Timestamp,
    pub voting_end: cosmwasm_std::Timestamp,
}

pub const CONFIG: Item<Config> = Item::new("config");
pub const PROPOSALS: Map<u64, Proposal> = Map::new("proposals");
EOF
}

generate_nft_files() {
    # Create lib.rs
    cat > src/lib.rs << 'EOF'
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
EOF

    # Create error.rs
    cat > src/error.rs << 'EOF'
use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("Max supply reached")]
    MaxSupplyReached {},

    #[error("Token not found")]
    TokenNotFound {},

    #[error("Not owner")]
    NotOwner {},
}
EOF

    # Create msg.rs
    cat > src/msg.rs << 'EOF'
use cosmwasm_std::Addr;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMsg {
    pub name: String,
    pub symbol: String,
    pub base_uri: String,
    pub max_supply: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub enum ExecuteMsg {
    Mint { to: String, token_id: String, token_uri: String },
    Transfer { to: String, token_id: String },
    Approve { spender: String, token_id: String },
    Burn { token_id: String },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub enum QueryMsg {
    GetConfig {},
    GetTokenInfo {},
    GetToken { token_id: String },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Config {
    pub owner: Addr,
    pub name: String,
    pub symbol: String,
    pub base_uri: String,
    pub max_supply: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct TokenInfo {
    pub total_supply: u64,
    pub minted: u64,
}
EOF

    # Create state.rs
    cat > src/state.rs << 'EOF'
use cosmwasm_std::Addr;
use cw_storage_plus::Item;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct Config {
    pub owner: Addr,
    pub name: String,
    pub symbol: String,
    pub base_uri: String,
    pub max_supply: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct TokenInfo {
    pub total_supply: u64,
    pub minted: u64,
}

pub const CONFIG: Item<Config> = Item::new("config");
pub const TOKEN_INFO: Item<TokenInfo> = Item::new("token_info");
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            CONTRACT_NAME="$2"
            shift 2
            ;;
        -t|--type)
            CONTRACT_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$CONTRACT_NAME" ]]; then
    echo -e "${RED}❌ Contract name is required${NC}"
    print_usage
    exit 1
fi

if [[ -z "$CONTRACT_TYPE" ]]; then
    echo -e "${RED}❌ Contract type is required${NC}"
    print_usage
    exit 1
fi

# Generate contract based on type
case $CONTRACT_TYPE in
    cw20)
        generate_cw20
        ;;
    dao)
        generate_dao
        ;;
    nft)
        generate_nft
        ;;
    marketplace)
        echo -e "${YELLOW}⚠️ Marketplace contract generation not implemented yet${NC}"
        ;;
    staking)
        echo -e "${YELLOW}⚠️ Staking contract generation not implemented yet${NC}"
        ;;
    vesting)
        echo -e "${YELLOW}⚠️ Vesting contract generation not implemented yet${NC}"
        ;;
    *)
        echo -e "${RED}❌ Unknown contract type: $CONTRACT_TYPE${NC}"
        print_usage
        exit 1
        ;;
esac
