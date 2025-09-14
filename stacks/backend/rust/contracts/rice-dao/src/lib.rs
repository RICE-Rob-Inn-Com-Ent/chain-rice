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
        .map(|item| item.map(|(_, proposal)| proposal))
        .collect();
    Ok(proposals?)
}
