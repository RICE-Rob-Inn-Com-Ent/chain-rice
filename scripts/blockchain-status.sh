#!/bin/bash
# Blockchain Status Checker for ChainRice

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"
}

print_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

print_success() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')] SUCCESS:${NC} $1"
}

# Function to check if a service is running
check_service() {
    local service_name=$1
    local port=$2
    local pid_file="/tmp/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_success "$service_name is running (PID: $pid, Port: $port)"
            return 0
        else
            print_error "$service_name is not running (stale PID file)"
            return 1
        fi
    else
        print_error "$service_name is not running (no PID file)"
        return 1
    fi
}

# Function to check blockchain endpoints
check_blockchain_endpoints() {
    print_info "Checking blockchain endpoints..."
    
    # Check RPC endpoint
    if curl -s http://localhost:26657/status > /dev/null 2>&1; then
        print_success "Blockchain RPC is responding (localhost:26657)"
    else
        print_error "Blockchain RPC is not responding (localhost:26657)"
    fi
    
    # Check REST endpoint
    if curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null 2>&1; then
        print_success "Blockchain REST API is responding (localhost:1317)"
    else
        print_error "Blockchain REST API is not responding (localhost:1317)"
    fi
}

# Function to check smart contracts
check_smart_contracts() {
    print_info "Checking smart contracts..."
    
    # Check Hardhat node
    if curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' http://localhost:8545 > /dev/null 2>&1; then
        print_success "Hardhat node is responding (localhost:8545)"
    else
        print_error "Hardhat node is not responding (localhost:8545)"
    fi
}

# Function to check frontend
check_frontend() {
    print_info "Checking ChainRice frontend..."
    
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_success "ChainRice frontend is responding (localhost:3000)"
    else
        print_error "ChainRice frontend is not responding (localhost:3000)"
    fi
}

# Main execution
print_status "🔍 ChainRice Blockchain Status Check"
print_status "===================================="

echo ""
print_info "Checking running services..."

# Check blockchain service
if check_service "blockchain" "26657"; then
    check_blockchain_endpoints
else
    print_error "Blockchain service is not running"
fi

echo ""

# Check smart contracts
if check_service "hardhat" "8545" || check_service "contracts" "8545"; then
    check_smart_contracts
else
    print_error "Smart contracts service is not running"
fi

echo ""

# Check frontend
if check_service "frontend" "3000"; then
    check_frontend
else
    print_error "ChainRice frontend is not running"
fi

echo ""

# Check dashboard
if check_service "dashboard" "8080"; then
    print_success "Development dashboard is running (localhost:8080)"
else
    print_error "Development dashboard is not running"
fi

echo ""
print_status "📊 Service Summary:"
print_info "🌾 ChainRice Frontend: http://localhost:3000"
print_info "⛓️  Blockchain RPC: http://localhost:26657"
print_info "📊 Blockchain REST: http://localhost:1317"
print_info "📜 Hardhat Node: http://localhost:8545"
print_info "📊 Development Dashboard: http://localhost:8080/chainrice-dashboard.html"

echo ""
print_status "💎 Token Information:"
print_info "💰 CRICE Token: urice (main blockchain token)"
print_info "🪙 MWT Token: Ready for deployment"
print_info "🔗 CosmWasm: Enabled for smart contracts"

echo ""
print_status "✨ ChainRice Development Environment Status Complete!"
