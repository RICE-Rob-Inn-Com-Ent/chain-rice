#!/bin/bash
# Full ChainRice Development Environment Startup
# Uses Nix + Docker for complete blockchain development

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

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function to wait for service
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=0
    
    print_info "Waiting for $service_name on port $port..."
    
    while [ $attempt -lt $max_attempts ]; do
        if check_port $port; then
            sleep 1
            attempt=$((attempt + 1))
        else
            print_success "$service_name is ready!"
            return 0
        fi
    done
    
    print_error "$service_name failed to start within $max_attempts seconds"
    return 1
}

# Function to start Docker services
start_docker_services() {
    print_status "🐳 Starting Docker services..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Build and start services
    print_info "Building Docker images..."
    docker-compose build --parallel
    
    print_info "Starting Docker services..."
    docker-compose up -d
    
    # Wait for services to be ready
    print_info "Waiting for services to be ready..."
    sleep 10
    
    # Check service health
    if wait_for_service "blockchain" "26657"; then
        print_success "Blockchain service is ready"
    else
        print_warning "Blockchain service may not be ready yet"
    fi
    
    if wait_for_service "hardhat" "8545"; then
        print_success "Hardhat service is ready"
    else
        print_warning "Hardhat service may not be ready yet"
    fi
    
    if wait_for_service "frontend" "3000"; then
        print_success "Frontend service is ready"
    else
        print_warning "Frontend service may not be ready yet"
    fi
    
    if wait_for_service "dashboard" "8080"; then
        print_success "Dashboard service is ready"
    else
        print_warning "Dashboard service may not be ready yet"
    fi
}

# Function to start blockchain directly (fallback)
start_blockchain_direct() {
    print_status "⛓️  Starting blockchain directly..."
    
    if [ -f "scripts/start-blockchain-real.sh" ]; then
        bash scripts/start-blockchain-real.sh > /tmp/blockchain.log 2>&1 &
        echo $! > /tmp/blockchain.pid
        print_success "Blockchain started directly"
    else
        print_error "Blockchain startup script not found"
        return 1
    fi
}

# Function to start frontend directly (fallback)
start_frontend_direct() {
    print_status "🌾 Starting frontend directly..."
    
    if [ -d "projects/chain-rice" ]; then
        cd projects/chain-rice
        
        # Install dependencies if needed
        if [ ! -d "node_modules" ]; then
            print_info "Installing frontend dependencies..."
            npm install --silent || yarn install --silent || pnpm install --silent || true
        fi
        
        # Start Vite dev server
        npm run dev > /tmp/frontend.log 2>&1 &
        echo $! > /tmp/frontend.pid
        cd ../..
        print_success "Frontend started directly"
    else
        print_error "ChainRice frontend not found"
        return 1
    fi
}

# Function to start dashboard directly (fallback)
start_dashboard_direct() {
    print_status "📊 Starting dashboard directly..."
    
    if [ -d "scripts/dashboard" ]; then
        cd scripts/dashboard
        python3 -m http.server 8080 > /tmp/dashboard.log 2>&1 &
        echo $! > /tmp/dashboard.pid
        cd ../..
        print_success "Dashboard started directly"
    else
        print_error "Dashboard not found"
        return 1
    fi
}

# Cleanup function
cleanup() {
    print_info "Shutting down all services..."
    
    # Stop Docker services
    if command -v docker-compose &> /dev/null; then
        print_info "Stopping Docker services..."
        docker-compose down
    fi
    
    # Stop direct services
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
print_status "🌾 Starting Full ChainRice Development Environment"
print_status "================================================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    print_error "Please run this script from the rice-dev root directory"
    exit 1
fi

# Check if Docker is available
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    print_info "Docker and Docker Compose found, starting with Docker..."
    start_docker_services
else
    print_warning "Docker not found, starting services directly..."
    start_blockchain_direct
    start_frontend_direct
    start_dashboard_direct
fi

# Wait a moment for services to start
sleep 5

# Open browser if possible
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:3000 &
    xdg-open http://localhost:8080 &
elif command -v open > /dev/null; then
    open http://localhost:3000 &
    open http://localhost:8080 &
fi

# Display service status
print_status "🎉 Full ChainRice Development Environment Started!"
print_info "Service URLs:"
print_info "🌾 ChainRice Frontend: http://localhost:3000"
print_info "⛓️  Blockchain RPC: http://localhost:26657"
print_info "📊 Blockchain REST: http://localhost:1317"
print_info "📜 Hardhat Node: http://localhost:8545"
print_info "📊 Blockchain Dashboard: http://localhost:8080"
print_info ""
print_info "Blockchain Features:"
print_info "🔗 Chain ID: chainrice-1"
print_info "💎 CRICE Token: urice (main token)"
print_info "🪙 MWT Token: Ready for deployment"
print_info "🔗 CosmWasm: Enabled for smart contracts"
print_info ""
print_info "Development Features:"
print_info "🔥 Hot Reload: Enabled for frontend"
print_info "📦 Block Production: Real-time monitoring"
print_info "🐳 Docker: Containerized services"
print_info "📊 Dashboard: Real-time blockchain status"
print_info ""
print_info "Token Management:"
print_info "🔄 Transfer Interface: http://localhost:3000/transfer"
print_info "📈 Balance Checker: http://localhost:3000/balances"
print_info "🚀 Contract Deploy: http://localhost:3000/deploy"
print_info ""
print_status "Press Ctrl+C to stop all services"

# Keep the script running
while true; do
    sleep 1
done
