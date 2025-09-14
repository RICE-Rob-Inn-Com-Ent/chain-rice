#!/bin/bash

# Chain Rice Smart Contract Interaction Script
# Provides easy commands to interact with deployed contracts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHAIN_ID=""
RPC_URL=""
GAS_PRICES=""
KEY_NAME=""
CONTRACT_ADDRESS=""
CONTRACT_TYPE=""

print_usage() {
    echo -e "${BLUE}🤝 Chain Rice Contract Interaction Script${NC}"
    echo "=============================================="
    echo ""
    echo "Usage: $0 [OPTIONS] COMMAND [ARGS...]"
    echo ""
    echo "Options:"
    echo "  -c, --chain-id ID        Chain ID (required)"
    echo "  -r, --rpc-url URL        RPC URL (required)"
    echo "  -g, --gas-prices PRICES  Gas prices (e.g., 0.025uosmo)"
    echo "  -k, --key-name NAME      Key name for signing (required)"
    echo "  -a, --address ADDR       Contract address (required)"
    echo "  -t, --type TYPE          Contract type (cw20|dao|nft)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Commands:"
    echo "  query CONFIG             Query contract configuration"
    echo "  query INFO               Query contract info"
    echo "  mint AMOUNT              Mint tokens (CW20/NFT)"
    echo "  burn AMOUNT              Burn tokens (CW20/NFT)"
    echo "  transfer TO AMOUNT       Transfer tokens (CW20)"
    echo "  create-proposal TITLE    Create DAO proposal"
    echo "  vote PROPOSAL_ID VOTE    Vote on DAO proposal"
    echo ""
    echo "Examples:"
    echo "  $0 -c osmosis-1 -r https://rpc.osmosis.zone -k mykey -a cosmos123... -t cw20 query CONFIG"
    echo "  $0 -c osmosis-1 -r https://rpc.osmosis.zone -k mykey -a cosmos123... -t cw20 mint 1000000"
}

query_config() {
    echo -e "${GREEN}🔍 Querying contract configuration...${NC}"
    
    local query_msg='{"get_config":{}}'
    
    wasmd query wasm contract-state smart $CONTRACT_ADDRESS "$query_msg" \
        --node $RPC_URL \
        --output json | jq '.'
}

query_info() {
    echo -e "${GREEN}🔍 Querying contract info...${NC}"
    
    local query_msg=""
    case $CONTRACT_TYPE in
        cw20|nft)
            query_msg='{"get_token_info":{}}'
            ;;
        dao)
            query_msg='{"list_proposals":{}}'
            ;;
        *)
            echo -e "${RED}❌ Unknown contract type: $CONTRACT_TYPE${NC}"
            exit 1
            ;;
    esac
    
    wasmd query wasm contract-state smart $CONTRACT_ADDRESS "$query_msg" \
        --node $RPC_URL \
        --output json | jq '.'
}

execute_mint() {
    local amount="$1"
    echo -e "${GREEN}🪙 Minting $amount tokens...${NC}"
    
    local execute_msg=""
    case $CONTRACT_TYPE in
        cw20)
            execute_msg="{\"mint\":{\"to\":\"$KEY_NAME\",\"amount\":\"$amount\"}}"
            ;;
        nft)
            execute_msg="{\"mint\":{\"to\":\"$KEY_NAME\",\"token_id\":\"$(date +%s)\",\"token_uri\":\"https://chain-rice.com/metadata/$(date +%s).json\"}}"
            ;;
        *)
            echo -e "${RED}❌ Mint not supported for contract type: $CONTRACT_TYPE${NC}"
            exit 1
            ;;
    esac
    
    wasmd tx wasm execute $CONTRACT_ADDRESS "$execute_msg" \
        --from $KEY_NAME \
        --chain-id $CHAIN_ID \
        --node $RPC_URL \
        --gas auto \
        --gas-adjustment 1.3 \
        --gas-prices $GAS_PRICES \
        --output json \
        --yes | jq '.'
}

execute_burn() {
    local amount="$1"
    echo -e "${GREEN}🔥 Burning $amount tokens...${NC}"
    
    local execute_msg=""
    case $CONTRACT_TYPE in
        cw20)
            execute_msg="{\"burn\":{\"from\":\"$KEY_NAME\",\"amount\":\"$amount\"}}"
            ;;
        nft)
            execute_msg="{\"burn\":{\"token_id\":\"$amount\"}}"
            ;;
        *)
            echo -e "${RED}❌ Burn not supported for contract type: $CONTRACT_TYPE${NC}"
            exit 1
            ;;
    esac
    
    wasmd tx wasm execute $CONTRACT_ADDRESS "$execute_msg" \
        --from $KEY_NAME \
        --chain-id $CHAIN_ID \
        --node $RPC_URL \
        --gas auto \
        --gas-adjustment 1.3 \
        --gas-prices $GAS_PRICES \
        --output json \
        --yes | jq '.'
}

execute_transfer() {
    local to="$1"
    local amount="$2"
    echo -e "${GREEN}💸 Transferring $amount tokens to $to...${NC}"
    
    if [ "$CONTRACT_TYPE" != "cw20" ]; then
        echo -e "${RED}❌ Transfer only supported for CW20 contracts${NC}"
        exit 1
    fi
    
    local execute_msg="{\"transfer\":{\"to\":\"$to\",\"amount\":\"$amount\"}}"
    
    wasmd tx wasm execute $CONTRACT_ADDRESS "$execute_msg" \
        --from $KEY_NAME \
        --chain-id $CHAIN_ID \
        --node $RPC_URL \
        --gas auto \
        --gas-adjustment 1.3 \
        --gas-prices $GAS_PRICES \
        --output json \
        --yes | jq '.'
}

create_proposal() {
    local title="$1"
    echo -e "${GREEN}📝 Creating proposal: $title...${NC}"
    
    if [ "$CONTRACT_TYPE" != "dao" ]; then
        echo -e "${RED}❌ Create proposal only supported for DAO contracts${NC}"
        exit 1
    fi
    
    local execute_msg="{\"create_proposal\":{\"title\":\"$title\",\"description\":\"Proposal created via interaction script\",\"proposal_type\":\"governance\"}}"
    
    wasmd tx wasm execute $CONTRACT_ADDRESS "$execute_msg" \
        --from $KEY_NAME \
        --chain-id $CHAIN_ID \
        --node $RPC_URL \
        --gas auto \
        --gas-adjustment 1.3 \
        --gas-prices $GAS_PRICES \
        --output json \
        --yes | jq '.'
}

vote_proposal() {
    local proposal_id="$1"
    local vote="$2"
    echo -e "${GREEN}🗳️ Voting $vote on proposal $proposal_id...${NC}"
    
    if [ "$CONTRACT_TYPE" != "dao" ]; then
        echo -e "${RED}❌ Vote only supported for DAO contracts${NC}"
        exit 1
    fi
    
    local execute_msg="{\"vote\":{\"proposal_id\":$proposal_id,\"vote\":\"$vote\"}}"
    
    wasmd tx wasm execute $CONTRACT_ADDRESS "$execute_msg" \
        --from $KEY_NAME \
        --chain-id $CHAIN_ID \
        --node $RPC_URL \
        --gas auto \
        --gas-adjustment 1.3 \
        --gas-prices $GAS_PRICES \
        --output json \
        --yes | jq '.'
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--chain-id)
            CHAIN_ID="$2"
            shift 2
            ;;
        -r|--rpc-url)
            RPC_URL="$2"
            shift 2
            ;;
        -g|--gas-prices)
            GAS_PRICES="$2"
            shift 2
            ;;
        -k|--key-name)
            KEY_NAME="$2"
            shift 2
            ;;
        -a|--address)
            CONTRACT_ADDRESS="$2"
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
        query)
            COMMAND="query"
            shift
            break
            ;;
        mint)
            COMMAND="mint"
            shift
            break
            ;;
        burn)
            COMMAND="burn"
            shift
            break
            ;;
        transfer)
            COMMAND="transfer"
            shift
            break
            ;;
        create-proposal)
            COMMAND="create-proposal"
            shift
            break
            ;;
        vote)
            COMMAND="vote"
            shift
            break
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$CHAIN_ID" ]]; then
    echo -e "${RED}❌ Chain ID is required${NC}"
    print_usage
    exit 1
fi

if [[ -z "$RPC_URL" ]]; then
    echo -e "${RED}❌ RPC URL is required${NC}"
    print_usage
    exit 1
fi

if [[ -z "$KEY_NAME" ]]; then
    echo -e "${RED}❌ Key name is required${NC}"
    print_usage
    exit 1
fi

if [[ -z "$CONTRACT_ADDRESS" ]]; then
    echo -e "${RED}❌ Contract address is required${NC}"
    print_usage
    exit 1
fi

if [[ -z "$CONTRACT_TYPE" ]]; then
    echo -e "${RED}❌ Contract type is required${NC}"
    print_usage
    exit 1
fi

# Set default gas prices if not provided
if [[ -z "$GAS_PRICES" ]]; then
    case $CHAIN_ID in
        *osmosis*)
            GAS_PRICES="0.025uosmo"
            ;;
        *juno*)
            GAS_PRICES="0.025ujuno"
            ;;
        *)
            GAS_PRICES="0.025stake"
            ;;
    esac
fi

# Check if required tools are installed
if ! command -v wasmd &> /dev/null; then
    echo -e "${RED}❌ wasmd not found. Please install CosmWasm CLI tools${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq not found. Please install jq${NC}"
    exit 1
fi

# Execute command
case $COMMAND in
    query)
        case "$1" in
            CONFIG)
                query_config
                ;;
            INFO)
                query_info
                ;;
            *)
                echo -e "${RED}❌ Unknown query type: $1${NC}"
                echo "Available: CONFIG, INFO"
                exit 1
                ;;
        esac
        ;;
    mint)
        if [[ -z "$1" ]]; then
            echo -e "${RED}❌ Amount required for mint command${NC}"
            exit 1
        fi
        execute_mint "$1"
        ;;
    burn)
        if [[ -z "$1" ]]; then
            echo -e "${RED}❌ Amount required for burn command${NC}"
            exit 1
        fi
        execute_burn "$1"
        ;;
    transfer)
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo -e "${RED}❌ To address and amount required for transfer command${NC}"
            exit 1
        fi
        execute_transfer "$1" "$2"
        ;;
    create-proposal)
        if [[ -z "$1" ]]; then
            echo -e "${RED}❌ Title required for create-proposal command${NC}"
            exit 1
        fi
        create_proposal "$1"
        ;;
    vote)
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo -e "${RED}❌ Proposal ID and vote required for vote command${NC}"
            exit 1
        fi
        vote_proposal "$1" "$2"
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $COMMAND${NC}"
        print_usage
        exit 1
        ;;
esac
