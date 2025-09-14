#!/bin/bash

# Chain Rice Smart Contract Deployment Script
# Deploys contracts to CosmWasm-compatible blockchains

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
CONTRACT_NAME=""
CONTRACT_TYPE=""

print_usage() {
    echo -e "${BLUE}🚀 Chain Rice Contract Deployment Script${NC}"
    echo "=============================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --chain-id ID        Chain ID (required)"
    echo "  -r, --rpc-url URL        RPC URL (required)"
    echo "  -g, --gas-prices PRICES  Gas prices (e.g., 0.025uosmo)"
    echo "  -k, --key-name NAME      Key name for signing (required)"
    echo "  -n, --contract NAME      Contract name to deploy (required)"
    echo "  -t, --type TYPE          Contract type (cw20|dao|nft)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -c osmosis-1 -r https://rpc.osmosis.zone -k mykey -n rice-token -t cw20"
    echo "  $0 -c juno-1 -r https://rpc.juno.zone -k mykey -n rice-dao -t dao"
}

deploy_contract() {
    echo -e "${GREEN}🚀 Deploying $CONTRACT_TYPE contract: $CONTRACT_NAME${NC}"
    
    # Check if contract exists
    if [ ! -d "contracts/$CONTRACT_NAME" ]; then
        echo -e "${RED}❌ Contract $CONTRACT_NAME not found in contracts/ directory${NC}"
        exit 1
    fi
    
    cd "contracts/$CONTRACT_NAME"
    
    # Build the contract
    echo -e "${YELLOW}🔨 Building contract...${NC}"
    cargo build --release --target wasm32-unknown-unknown
    
    # Optimize the wasm file
    echo -e "${YELLOW}⚡ Optimizing wasm file...${NC}"
    if command -v wasm-opt &> /dev/null; then
        wasm-opt -Os target/wasm32-unknown-unknown/release/$CONTRACT_NAME.wasm -o $CONTRACT_NAME.wasm
    else
        cp target/wasm32-unknown-unknown/release/$CONTRACT_NAME.wasm $CONTRACT_NAME.wasm
        echo -e "${YELLOW}⚠️ wasm-opt not found, using unoptimized wasm${NC}"
    fi
    
    # Upload the contract
    echo -e "${YELLOW}📤 Uploading contract to blockchain...${NC}"
    UPLOAD_RESULT=$(wasmd tx wasm store $CONTRACT_NAME.wasm \
        --from $KEY_NAME \
        --chain-id $CHAIN_ID \
        --node $RPC_URL \
        --gas auto \
        --gas-adjustment 1.3 \
        --gas-prices $GAS_PRICES \
        --output json \
        --yes)
    
    CODE_ID=$(echo $UPLOAD_RESULT | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
    
    if [ "$CODE_ID" = "null" ] || [ -z "$CODE_ID" ]; then
        echo -e "${RED}❌ Failed to upload contract${NC}"
        echo "$UPLOAD_RESULT"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Contract uploaded successfully!${NC}"
    echo -e "${BLUE}📋 Code ID: $CODE_ID${NC}"
    
    # Instantiate the contract
    echo -e "${YELLOW}🏗️ Instantiating contract...${NC}"
    
    # Generate instantiate message based on contract type
    INSTANTIATE_MSG=$(generate_instantiate_msg)
    
    INSTANTIATE_RESULT=$(wasmd tx wasm instantiate $CODE_ID "$INSTANTIATE_MSG" \
        --from $KEY_NAME \
        --chain-id $CHAIN_ID \
        --node $RPC_URL \
        --gas auto \
        --gas-adjustment 1.3 \
        --gas-prices $GAS_PRICES \
        --label "$CONTRACT_NAME" \
        --admin $KEY_NAME \
        --output json \
        --yes)
    
    CONTRACT_ADDRESS=$(echo $INSTANTIATE_RESULT | jq -r '.logs[0].events[] | select(.type=="instantiate") | .attributes[] | select(.key=="_contract_address") | .value')
    
    if [ "$CONTRACT_ADDRESS" = "null" ] || [ -z "$CONTRACT_ADDRESS" ]; then
        echo -e "${RED}❌ Failed to instantiate contract${NC}"
        echo "$INSTANTIATE_RESULT"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Contract instantiated successfully!${NC}"
    echo -e "${BLUE}📋 Contract Address: $CONTRACT_ADDRESS${NC}"
    
    # Save deployment info
    echo "CONTRACT_NAME=$CONTRACT_NAME" > deployment.info
    echo "CONTRACT_TYPE=$CONTRACT_TYPE" >> deployment.info
    echo "CODE_ID=$CODE_ID" >> deployment.info
    echo "CONTRACT_ADDRESS=$CONTRACT_ADDRESS" >> deployment.info
    echo "CHAIN_ID=$CHAIN_ID" >> deployment.info
    echo "DEPLOYED_AT=$(date)" >> deployment.info
    
    echo -e "${GREEN}📄 Deployment info saved to deployment.info${NC}"
    
    cd ../..
}

generate_instantiate_msg() {
    case $CONTRACT_TYPE in
        cw20)
            echo '{"name":"Chain Rice Token","symbol":"CRT","decimals":6,"initial_supply":"1000000"}'
            ;;
        dao)
            echo '{"name":"Chain Rice DAO","description":"Decentralized governance for Chain Rice","voting_period":604800,"quorum":100,"threshold":0.5}'
            ;;
        nft)
            echo '{"name":"Chain Rice NFTs","symbol":"CRN","base_uri":"https://chain-rice.com/metadata/","max_supply":10000}'
            ;;
        *)
            echo '{}'
            ;;
    esac
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
        -n|--contract)
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

# Deploy the contract
deploy_contract
