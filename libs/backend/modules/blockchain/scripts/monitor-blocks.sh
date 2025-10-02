#!/bin/bash

# ChainRice Blockchain Block Monitor
echo "🔍 ChainRice Blockchain Block Monitor"
echo "======================================"
echo ""

# Simulate block production
block_height=1
while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Generate some realistic block data
    block_hash=$(openssl rand -hex 16)
    tx_count=$((RANDOM % 5 + 1))
    gas_used=$((RANDOM % 1000000 + 500000))
    
    echo "📦 Block #$block_height | $timestamp"
    echo "   Hash: $block_hash"
    echo "   Transactions: $tx_count"
    echo "   Gas Used: $gas_used"
    
    # Show different block types
    case $((block_height % 4)) in
        0)
            echo "   Type: 🪙 Token Transaction (CRICE)"
            ;;
        1)
            echo "   Type: 🔗 CosmWasm Contract Call"
            ;;
        2)
            echo "   Type: ⚡ Validator Rewards"
            ;;
        3)
            echo "   Type: 🏗️  MWT Token Operations"
            ;;
    esac
    
    echo "   Status: ✅ Committed"
    echo ""
    
    # Increment block height
    ((block_height++))
    
    # Wait 3 seconds between blocks
    sleep 3
done
