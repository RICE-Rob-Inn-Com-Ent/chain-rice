#!/bin/bash

# ChainRice Blockchain Initialization Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHAIN_ID="chainrice-1"
DENOM="urice"
NODE_HOME="$HOME/.chainrice"
BINARY_NAME="chainriced"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if binary exists
check_binary() {
    if ! command -v $BINARY_NAME &> /dev/null; then
        print_error "$BINARY_NAME is not installed or not in PATH"
        print_status "Please build the binary first: go build -o $BINARY_NAME ./cmd/chainriced"
        exit 1
    fi
    print_success "$BINARY_NAME is available"
}

# Function to initialize the chain
init_chain() {
    print_status "Initializing ChainRice blockchain..."
    
    # Remove existing data if it exists
    if [ -d "$NODE_HOME" ]; then
        print_warning "Removing existing node data..."
        rm -rf "$NODE_HOME"
    fi
    
    # Initialize the chain
    $BINARY_NAME init chainrice-node --chain-id $CHAIN_ID --home $NODE_HOME
    
    # Copy config files
    cp config/app.yaml $NODE_HOME/config/
    cp config/config.toml $NODE_HOME/config/
    cp config/genesis.json $NODE_HOME/config/
    
    print_success "Chain initialized successfully"
}

# Function to create a validator
create_validator() {
    print_status "Creating validator..."
    
    # Create a new key
    $BINARY_NAME keys add validator --keyring-backend test --home $NODE_HOME
    
    # Add genesis account
    $BINARY_NAME genesis add-genesis-account validator 1000000000000$DENOM --keyring-backend test --home $NODE_HOME
    
    # Create genesis transaction
    $BINARY_NAME genesis gentx validator 100000000000$DENOM --chain-id $CHAIN_ID --keyring-backend test --home $NODE_HOME
    
    # Collect genesis transactions
    $BINARY_NAME genesis collect-gentxs --home $NODE_HOME
    
    print_success "Validator created successfully"
}

# Function to start the node
start_node() {
    print_status "Starting ChainRice node..."
    
    # Start the node
    $BINARY_NAME start --home $NODE_HOME
}

# Function to show help
show_help() {
    echo "Usage: $0 [init|validator|start|help]"
    echo "  init      - Initialize the blockchain"
    echo "  validator - Create a validator"
    echo "  start     - Start the node"
    echo "  help      - Show this help message"
}

# Main function
main() {
    case "${1:-help}" in
        "init")
            check_binary
            init_chain
            ;;
        "validator")
            check_binary
            create_validator
            ;;
        "start")
            check_binary
            start_node
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
