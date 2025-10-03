#!/bin/bash
# Start ChainRice Cosmos SDK Blockchain

set -e

echo "🚀 Starting ChainRice Cosmos SDK Blockchain..."

# Set environment variables
export CHAINRICE_HOME="$PWD/.crice"
export CHAINRICE_CHAIN_ID="crice-1"

# Create blockchain data directory
mkdir -p "$CHAINRICE_HOME"/{config,data}

# Initialize blockchain if not exists
if [ ! -f "$CHAINRICE_HOME/config/genesis.json" ]; then
    echo "📦 Initializing blockchain..."
    cd /home/mrDinkelman/rice-dev/libs/backend
    
    # Initialize the blockchain
    ./chainriced init chainrice-validator --chain-id crice-1 --home "$CHAINRICE_HOME"
    
    # Create keys for test accounts
    echo "alice123456789" | ./chainriced keys add alice --home "$CHAINRICE_HOME" --keyring-backend test --output json > /tmp/alice_key.json
    echo "bob123456789" | ./chainriced keys add bob --home "$CHAINRICE_HOME" --keyring-backend test --output json > /tmp/bob_key.json
    
    # Add genesis accounts
    ./chainriced add-genesis-account alice 1000000urice,500000unori --home "$CHAINRICE_HOME" --keyring-backend test
    ./chainriced add-genesis-account bob 750000urice,250000unori --home "$CHAINRICE_HOME" --keyring-backend test
    
    # Create genesis transaction
    echo "alice123456789" | ./chainriced gentx alice 100000urice --chain-id crice-1 --home "$CHAINRICE_HOME" --keyring-backend test
    
    # Collect genesis transactions
    ./chainriced collect-gentxs --home "$CHAINRICE_HOME"
    
    echo "✅ Blockchain initialized!"
fi

# Start the blockchain
echo "⛓️  Starting ChainRice blockchain..."
cd /home/mrDinkelman/rice-dev/libs/backend
./chainriced start --home "$CHAINRICE_HOME" --rpc.laddr tcp://0.0.0.0:26657 --p2p.laddr tcp://0.0.0.0:26656 --grpc.address 0.0.0.0:9090 --api.enable
