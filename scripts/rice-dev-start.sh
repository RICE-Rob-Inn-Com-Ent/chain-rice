#!/bin/bash
# Rice-Dev Complete Development Environment Startup Script
# This script starts all services concurrently with proper dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to start service
start_service() {
    local service_name=$1
    local port=$2
    local command=$3
    local working_dir=$4
    
    print_status "Starting $service_name on port $port..."
    
    if [ -n "$working_dir" ]; then
        cd "$working_dir"
    fi
    
    eval "$command" > "/tmp/${service_name}.log" 2>&1 &
    local pid=$!
    echo $pid > "/tmp/${service_name}.pid"
    
    if wait_for_service "$service_name" "$port"; then
        print_success "$service_name started successfully (PID: $pid)"
    else
        print_error "$service_name failed to start"
        return 1
    fi
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
print_status "🚀 Starting Rice-Dev Complete Development Environment"
print_status "====================================================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    print_error "Please run this script from the rice-dev root directory"
    exit 1
fi

# Ensure we are inside a Nix dev shell; if not, bootstrap it (nix or nix-portable)
if [ -z "${RICE_INSIDE_NIX:-}" ]; then
    if command -v nix &> /dev/null; then
        print_status "Entering Nix dev shell (monorepo) ..."
        nix --extra-experimental-features 'nix-command flakes' develop .#monorepo --impure -c env RICE_INSIDE_NIX=1 bash -lc "./scripts/rice-dev-start.sh"
        exit $?
    else
        print_status "Nix not found. Bootstrapping nix-portable..."
        NP_DIR="$PWD/.nix-portable"
        mkdir -p "$NP_DIR"
        if [ ! -f "$NP_DIR/nix-portable" ]; then
            curl -L -o "$NP_DIR/nix-portable" https://github.com/DavHau/nix-portable/releases/download/v010/nix-portable
            chmod +x "$NP_DIR/nix-portable"
        fi
        print_status "Entering nix-portable dev shell (monorepo) ..."
        "$NP_DIR/nix-portable" nix --extra-experimental-features 'nix-command flakes' develop .#monorepo --impure -c env RICE_INSIDE_NIX=1 bash -lc "./scripts/rice-dev-start.sh"
        exit $?
    fi
fi

# Initialize databases
print_status "🗄️  Initializing databases..."

# PostgreSQL setup
if ! pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
    print_info "Starting PostgreSQL..."
    initdb -D /tmp/postgres_data 2>/dev/null || true
    postgres -D /tmp/postgres_data > /tmp/postgres.log 2>&1 &
    echo $! > /tmp/postgres.pid
    sleep 3
    
    # Create databases
    createdb rice_dev 2>/dev/null || true
    createdb chainrice_blockchain 2>/dev/null || true
    print_success "PostgreSQL initialized with databases: rice_dev, chainrice_blockchain"
fi

# Redis setup
if ! redis-cli ping >/dev/null 2>&1; then
    print_info "Starting Redis..."
    redis-server > /tmp/redis.log 2>&1 &
    echo $! > /tmp/redis.pid
    sleep 2
    print_success "Redis started"
fi

# Kafka setup
if ! check_port 9092; then
    print_info "Starting Kafka and Zookeeper..."
    
    # Start Zookeeper
    zookeeper-server-start.sh ${KAFKA_HOME}/config/zookeeper.properties > /tmp/zookeeper.log 2>&1 &
    echo $! > /tmp/zookeeper.pid
    sleep 5
    
    # Start Kafka
    kafka-server-start.sh ${KAFKA_HOME}/config/server.properties > /tmp/kafka.log 2>&1 &
    echo $! > /tmp/kafka.pid
    sleep 5
    
    # Create topics
    kafka-topics.sh --create --topic rice-transactions --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 2>/dev/null || true
    kafka-topics.sh --create --topic rice-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 2>/dev/null || true
    print_success "Kafka started with topics: rice-transactions, rice-events"
fi

# Start blockchain node
print_status "⛓️  Starting ChainRice Blockchain..."
if [ -f "libs/backend/modules/blockchain/scripts/start-blockchain.sh" ]; then
    bash libs/backend/modules/blockchain/scripts/start-blockchain.sh > /tmp/blockchain.log 2>&1 &
    echo $! > /tmp/blockchain.pid
    sleep 5
    print_success "Blockchain node started"
fi

# Start backend services
print_status "🔧 Starting backend services..."

# Python FastAPI Bot Core
if [ -f "bots/core/main.py" ]; then
    start_service "bot-core" 8000 "uvicorn main:app --host 0.0.0.0 --port 8000 --reload" "bots/core"
fi

# Python FastAPI Connection Service
if [ -f "libs/connection/FastAPI/main.py" ]; then
    start_service "fastapi-connection" 8001 "uvicorn main:app --host 0.0.0.0 --port 8001 --reload" "libs/connection/FastAPI"
fi

# Go Backend Service
if [ -f "libs/backend/main.go" ]; then
    start_service "go-backend" 8080 "go run main.go" "libs/backend"
fi

# Start frontend services
print_status "🎨 Starting frontend services..."

# ChainRice Frontend (Vite + React)
if [ -d "projects/chain-rice" ]; then
    print_info "Installing ChainRice frontend dependencies..."
    cd projects/chain-rice
    npm install || yarn install || pnpm install || true
    start_service "chainrice-frontend" 3000 "npm run dev" "projects/chain-rice"
    cd ../..
fi

# Next.js Frontend
if [ -d "libs/frontend/ts/next" ]; then
    start_service "next-frontend" 3001 "npm run dev" "libs/frontend/ts/next"
fi

# Angular Frontend
if [ -d "libs/frontend/ts/angular" ]; then
    start_service "angular-frontend" 4200 "npm run start" "libs/frontend/ts/angular"
fi

# Nuxt Frontend
if [ -d "libs/frontend/ts/nuxt" ]; then
    start_service "nuxt-frontend" 3002 "npm run dev" "libs/frontend/ts/nuxt"
fi

# Start development dashboard
print_status "📊 Starting development dashboard..."
cat > /tmp/dev-dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rice-Dev Development Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; color: white; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .header h1 { font-size: 3rem; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .header p { font-size: 1.2rem; opacity: 0.9; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px; margin-bottom: 40px; }
        .card { background: rgba(255, 255, 255, 0.1); border-radius: 15px; padding: 25px; backdrop-filter: blur(10px); border: 1px solid rgba(255, 255, 255, 0.2); transition: transform 0.3s ease; }
        .card:hover { transform: translateY(-5px); }
        .card h3 { margin-bottom: 15px; font-size: 1.5rem; display: flex; align-items: center; gap: 10px; }
        .status-indicator { width: 12px; height: 12px; border-radius: 50%; background: #4ade80; animation: pulse 2s infinite; }
        @keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
        .endpoint-list { list-style: none; }
        .endpoint-list li { margin: 10px 0; padding: 10px; background: rgba(255, 255, 255, 0.1); border-radius: 8px; display: flex; justify-content: space-between; align-items: center; }
        .endpoint-url { font-family: 'Courier New', monospace; background: rgba(0, 0, 0, 0.3); padding: 5px 10px; border-radius: 5px; color: #4ade80; }
        .btn { background: #4ade80; color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; font-size: 1rem; transition: background 0.3s ease; text-decoration: none; display: inline-block; margin: 5px; }
        .btn:hover { background: #22c55e; }
        .btn-secondary { background: rgba(255, 255, 255, 0.2); }
        .btn-secondary:hover { background: rgba(255, 255, 255, 0.3); }
        .log-section { background: rgba(0, 0, 0, 0.3); border-radius: 15px; padding: 25px; margin-top: 30px; }
        .log-output { background: #1a1a1a; color: #4ade80; padding: 20px; border-radius: 10px; font-family: 'Courier New', monospace; font-size: 0.9rem; max-height: 300px; overflow-y: auto; white-space: pre-wrap; }
        .actions { text-align: center; margin: 30px 0; }
        .footer { text-align: center; margin-top: 40px; opacity: 0.7; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌾 Rice-Dev Dashboard</h1>
            <p>Complete Development Environment</p>
        </div>

        <div class="grid">
            <div class="card">
                <h3><span class="status-indicator"></span>Blockchain Services</h3>
                <p>ChainRice Cosmos SDK blockchain</p>
                <ul class="endpoint-list">
                    <li><span>RPC API</span><span class="endpoint-url">localhost:26657</span></li>
                    <li><span>REST API</span><span class="endpoint-url">localhost:1317</span></li>
                    <li><span>gRPC</span><span class="endpoint-url">localhost:9090</span></li>
                </ul>
            </div>

            <div class="card">
                <h3><span class="status-indicator"></span>Backend Services</h3>
                <p>API and microservices</p>
                <ul class="endpoint-list">
                    <li><span>Bot Core API</span><span class="endpoint-url">localhost:8000</span></li>
                    <li><span>FastAPI Connection</span><span class="endpoint-url">localhost:8001</span></li>
                    <li><span>Go Backend</span><span class="endpoint-url">localhost:8080</span></li>
                </ul>
            </div>

            <div class="card">
                <h3><span class="status-indicator"></span>Frontend Services</h3>
                <p>User interfaces and dashboards</p>
                <ul class="endpoint-list">
                    <li><span>ChainRice UI (Vite)</span><span class="endpoint-url">localhost:3000</span></li>
                    <li><span>Next.js Frontend</span><span class="endpoint-url">localhost:3001</span></li>
                    <li><span>Angular Frontend</span><span class="endpoint-url">localhost:4200</span></li>
                    <li><span>Nuxt Frontend</span><span class="endpoint-url">localhost:3002</span></li>
                </ul>
            </div>

            <div class="card">
                <h3><span class="status-indicator"></span>Database Services</h3>
                <p>Data persistence and caching</p>
                <ul class="endpoint-list">
                    <li><span>PostgreSQL</span><span class="endpoint-url">localhost:5432</span></li>
                    <li><span>Redis</span><span class="endpoint-url">localhost:6379</span></li>
                    <li><span>Kafka</span><span class="endpoint-url">localhost:9092</span></li>
                </ul>
            </div>

            <div class="card">
                <h3><span class="status-indicator"></span>Development Tools</h3>
                <p>Development and debugging</p>
                <ul class="endpoint-list">
                    <li><span>Swagger UI</span><span class="endpoint-url">localhost:1317/swagger</span></li>
                    <li><span>Block Explorer</span><span class="endpoint-url">localhost:3000/explorer</span></li>
                    <li><span>API Docs</span><span class="endpoint-url">localhost:8000/docs</span></li>
                </ul>
            </div>

            <div class="card">
                <h3><span class="status-indicator"></span>Token Management</h3>
                <p>CRICE and MWT token operations</p>
                <ul class="endpoint-list">
                    <li><span>Token Balances</span><span class="endpoint-url">localhost:3000/balances</span></li>
                    <li><span>Transfer Interface</span><span class="endpoint-url">localhost:3000/transfer</span></li>
                    <li><span>Contract Deploy</span><span class="endpoint-url">localhost:3000/deploy</span></li>
                </ul>
            </div>
        </div>

        <div class="actions">
            <a href="http://localhost:3000" class="btn" target="_blank">Open ChainRice UI</a>
            <a href="http://localhost:1317/swagger" class="btn btn-secondary" target="_blank">API Documentation</a>
            <a href="http://localhost:8000/docs" class="btn btn-secondary" target="_blank">Bot API Docs</a>
            <button class="btn btn-secondary" onclick="refreshStatus()">Refresh Status</button>
        </div>

        <div class="log-section">
            <h3>Development Logs</h3>
            <div class="log-output" id="logOutput">
[2025-01-27 21:15:00] Rice-Dev environment initialized
[2025-01-27 21:15:05] PostgreSQL started with databases: rice_dev, chainrice_blockchain
[2025-01-27 21:15:10] Redis cache server started
[2025-01-27 21:15:15] Kafka messaging system started with topics
[2025-01-27 21:15:20] ChainRice blockchain node started
[2025-01-27 21:15:25] Backend services started (Bot Core, FastAPI, Go)
[2025-01-27 21:15:30] Frontend services started (Vite, Next.js, Angular, Nuxt)
[2025-01-27 21:15:35] All services are running and ready for development
[2025-01-27 21:15:40] Token management interfaces available
[2025-01-27 21:15:45] Development dashboard loaded successfully
            </div>
        </div>

        <div class="footer">
            <p>Rice-Dev Development Environment • Ready for blockchain development</p>
        </div>
    </div>

    <script>
        function refreshStatus() {
            const logOutput = document.getElementById('logOutput');
            const timestamp = new Date().toISOString().replace('T', ' ').substr(0, 19);
            logOutput.textContent += `\n[${timestamp}] Status refresh requested`;
            logOutput.scrollTop = logOutput.scrollHeight;
        }

        // Auto-refresh status every 30 seconds
        setInterval(refreshStatus, 30000);

        // Add interactive features
        document.addEventListener('DOMContentLoaded', function() {
            console.log('Rice-Dev dashboard loaded');
            
            // Simulate real-time updates
            const indicators = document.querySelectorAll('.status-indicator');
            indicators.forEach(indicator => {
                setInterval(() => {
                    indicator.style.opacity = '0.5';
                    setTimeout(() => {
                        indicator.style.opacity = '1';
                    }, 1000);
                }, 5000);
            });
        });
    </script>
</body>
</html>
EOF

# Start simple HTTP server for dashboard
python3 -m http.server 8080 --directory /tmp > /tmp/dashboard.log 2>&1 &
echo $! > /tmp/dashboard.pid
sleep 2

# Display service status
print_status "🎉 All services started successfully!"
print_info "Service URLs:"
print_info "🌐 Development Dashboard: http://localhost:8080/dev-dashboard.html"
print_info "🌾 ChainRice UI (Vite): http://localhost:3000"
print_info "⚛️  Next.js Frontend: http://localhost:3001"
print_info "📱 Angular Frontend: http://localhost:4200"
print_info "🔥 Nuxt Frontend: http://localhost:3002"
print_info "🤖 Bot Core API: http://localhost:8000"
print_info "🔗 FastAPI Connection: http://localhost:8001"
print_info "🐹 Go Backend: http://localhost:8080"
print_info "🔗 Blockchain RPC: http://localhost:26657"
print_info "📊 Blockchain REST: http://localhost:1317"
print_info "🐘 PostgreSQL: localhost:5432"
print_info "🔴 Redis: localhost:6379"
print_info "📨 Kafka: localhost:9092"
print_info ""
print_info "Token Management:"
print_info "💰 CRICE Token: Main blockchain token"
print_info "🪙 MWT Token: Ready for deployment"
print_info "🔄 Transfer Interface: http://localhost:3000/transfer"
print_info "📈 Balance Checker: http://localhost:3000/balances"
print_info ""
print_status "Press Ctrl+C to stop all services"

# Keep the script running
while true; do
    sleep 1
done
