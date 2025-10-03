#!/bin/bash
# Complete ChainRice Development Environment Startup
# Starts blockchain, dashboard, and frontend with hot reload

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

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"
}

print_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

print_success() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')] SUCCESS:${NC} $1"
}

# Cleanup function
cleanup() {
    print_info "Shutting down all services..."
    
    for pid_file in /tmp/*.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                print_info "Stopping process $pid..."
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done
    
    rm -f /tmp/*.log
    print_status "All services stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main execution
print_status "🌾 Starting Complete ChainRice Development Environment"
print_status "====================================================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    print_error "Please run this script from the rice-dev root directory"
    exit 1
fi

# Start blockchain
print_status "⛓️  Starting blockchain..."
bash scripts/start-blockchain-real.sh > /tmp/blockchain.log 2>&1 &
echo $! > /tmp/blockchain.pid
sleep 5

# Start dashboard
print_status "📊 Starting dashboard..."
cd scripts/dashboard
python3 -m http.server 8080 > /tmp/dashboard.log 2>&1 &
echo $! > /tmp/dashboard.pid
cd ../..
sleep 3

# Start frontend if Node.js is available
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    print_status "🌾 Starting ChainRice frontend..."
    if [ -d "projects/chain-rice" ]; then
        cd projects/chain-rice
        
        # Install dependencies if needed
        if [ ! -d "node_modules" ]; then
            print_info "Installing frontend dependencies..."
            npm install --silent || true
        fi
        
        # Start Vite dev server
        npm run dev > /tmp/frontend.log 2>&1 &
        echo $! > /tmp/frontend.pid
        cd ../..
        print_success "Frontend started on http://localhost:3000"
    else
        print_warning "ChainRice frontend not found"
    fi
else
    print_warning "Node.js/npm not found, skipping frontend"
fi

# Wait for services to start
sleep 5

# Open browser if possible
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:8080/index.html &
    if [ -f /tmp/frontend.pid ]; then
        xdg-open http://localhost:3000 &
    fi
elif command -v open > /dev/null; then
    open http://localhost:8080/index.html &
    if [ -f /tmp/frontend.pid ]; then
        open http://localhost:3000 &
    fi
fi

# Display service status
print_status "🎉 ChainRice Development Environment Started!"
print_info "Service URLs:"
print_info "📊 Blockchain Dashboard: http://localhost:8080/index.html"
if [ -f /tmp/frontend.pid ]; then
    print_info "🌾 ChainRice Frontend: http://localhost:3000"
fi
print_info "⛓️  Blockchain RPC: http://localhost:26657"
print_info "📊 Blockchain REST: http://localhost:1317"
print_info ""
print_info "Blockchain Features:"
print_info "🔗 Chain ID: chainrice-1"
print_info "💎 CRICE Token: urice (main token)"
print_info "🪙 MWT Token: Ready for deployment"
print_info "🔗 CosmWasm: Enabled for smart contracts"
print_info ""
print_info "Block Production:"
print_info "📦 Blocks are being produced every 6 seconds"
print_info "📊 Monitor blocks in real-time on the dashboard"
print_info "🔍 Check blockchain status: http://localhost:1317/status"
print_info ""
print_status "Press Ctrl+C to stop all services"

# Keep the script running
while true; do
    sleep 1
done