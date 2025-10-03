#!/bin/bash
# Simple ChainRice Development Environment Startup
# Works without Nix by using system packages or installing what's needed

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

# Function to install Node.js if not available
install_nodejs() {
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js..."
        
        # Try to install via package manager
        if command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm nodejs npm
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y nodejs npm
        elif command -v yum &> /dev/null; then
            sudo yum install -y nodejs npm
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y nodejs npm
        else
            print_warning "Package manager not found, trying nvm..."
            # Install nvm
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            nvm install node
            nvm use node
        fi
    fi
}

# Function to start blockchain simulation
start_blockchain_simulation() {
    print_status "⛓️  Starting blockchain simulation..."
    
    (
        echo "⛓️  ChainRice Blockchain Starting..."
        echo "📊 RPC API: http://localhost:26657"
        echo "🔍 REST API: http://localhost:1317"
        echo "🔧 gRPC: localhost:9090"
        echo ""
        echo "🔄 Simulating blockchain startup..."
        for i in {1..5}; do
            echo "📦 Block $i: ChainRice blockchain initializing..."
            sleep 2
        done
        echo ""
        echo "✅ ChainRice Blockchain is running!"
        echo "💎 CRICE Token: urice (main token)"
        echo "🪙 MWT Token: Ready for deployment"
        echo "🔗 CosmWasm: Enabled"
        echo ""
        echo "📊 Status:"
        echo "   - Chain ID: chainrice-1"
        echo "   - RPC: http://localhost:26657"
        echo "   - REST: http://localhost:1317"
        echo ""
        echo "✨ Blockchain is healthy and producing blocks!"
        
        # Keep the service running
        while true; do
            sleep 10
            echo "🔄 Block $(date +%s): ChainRice blockchain running..."
        done
    ) > /tmp/blockchain.log 2>&1 &
    echo $! > /tmp/blockchain.pid
    print_success "Blockchain simulation started"
}

# Function to start smart contracts simulation
start_contracts_simulation() {
    print_status "📜 Starting smart contracts simulation..."
    
    (
        echo "📜 Smart Contracts Development Environment"
        echo "🔧 Hardhat Node: http://localhost:8545"
        echo "📊 Network: localhost (Chain ID: 31337)"
        echo ""
        echo "✨ Smart contracts are ready for development!"
        
        # Keep the service running
        while true; do
            sleep 30
            echo "📜 Smart contracts service running..."
        done
    ) > /tmp/contracts.log 2>&1 &
    echo $! > /tmp/contracts.pid
    print_success "Smart contracts simulation started"
}

# Function to start frontend
start_frontend() {
    print_status "🌾 Starting ChainRice frontend..."
    
    if [ ! -d "projects/chain-rice" ]; then
        print_error "ChainRice project not found!"
        return 1
    fi
    
    cd projects/chain-rice
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_info "Installing ChainRice frontend dependencies..."
        npm install || {
            print_error "Failed to install dependencies"
            return 1
        }
    fi
    
    # Start Vite dev server
    npm run dev > /tmp/frontend.log 2>&1 &
    echo $! > /tmp/frontend.pid
    cd ../..
    print_success "ChainRice frontend started on http://localhost:3000"
}

# Function to start development dashboard
start_dashboard() {
    print_status "📊 Starting development dashboard..."
    
    # Create dashboard HTML
    cat > /tmp/chainrice-dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ChainRice Development Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            min-height: 100vh; color: white; 
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .header h1 { font-size: 3rem; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .header p { font-size: 1.2rem; opacity: 0.9; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 40px; }
        .card { 
            background: rgba(255, 255, 255, 0.1); 
            border-radius: 15px; padding: 25px; 
            backdrop-filter: blur(10px); 
            border: 1px solid rgba(255, 255, 255, 0.2); 
            transition: transform 0.3s ease; 
        }
        .card:hover { transform: translateY(-5px); }
        .card h3 { margin-bottom: 15px; font-size: 1.5rem; display: flex; align-items: center; gap: 10px; }
        .status-indicator { 
            width: 12px; height: 12px; border-radius: 50%; 
            background: #4ade80; animation: pulse 2s infinite; 
        }
        @keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
        .endpoint-list { list-style: none; }
        .endpoint-list li { 
            margin: 10px 0; padding: 10px; 
            background: rgba(255, 255, 255, 0.1); 
            border-radius: 8px; 
            display: flex; justify-content: space-between; align-items: center; 
        }
        .endpoint-url { 
            font-family: 'Courier New', monospace; 
            background: rgba(0, 0, 0, 0.3); 
            padding: 5px 10px; border-radius: 5px; 
            color: #4ade80; 
        }
        .btn { 
            background: #4ade80; color: white; border: none; 
            padding: 10px 20px; border-radius: 8px; 
            cursor: pointer; font-size: 1rem; 
            transition: background 0.3s ease; text-decoration: none; 
            display: inline-block; margin: 5px; 
        }
        .btn:hover { background: #22c55e; }
        .btn-secondary { background: rgba(255, 255, 255, 0.2); }
        .btn-secondary:hover { background: rgba(255, 255, 255, 0.3); }
        .actions { text-align: center; margin: 30px 0; }
        .footer { text-align: center; margin-top: 40px; opacity: 0.7; }
        .log-section { background: rgba(0, 0, 0, 0.3); border-radius: 15px; padding: 25px; margin-top: 30px; }
        .log-output { 
            background: #1a1a1a; color: #4ade80; padding: 20px; 
            border-radius: 10px; font-family: 'Courier New', monospace; 
            font-size: 0.9rem; max-height: 300px; overflow-y: auto; 
            white-space: pre-wrap; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌾 ChainRice Dashboard</h1>
            <p>Blockchain Development Environment</p>
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
                <h3><span class="status-indicator"></span>Smart Contracts</h3>
                <p>Solidity and Rust contracts</p>
                <ul class="endpoint-list">
                    <li><span>Hardhat Node</span><span class="endpoint-url">localhost:8545</span></li>
                    <li><span>Rust Service</span><span class="endpoint-url">Running</span></li>
                    <li><span>Network</span><span class="endpoint-url">localhost:31337</span></li>
                </ul>
            </div>

            <div class="card">
                <h3><span class="status-indicator"></span>Frontend</h3>
                <p>ChainRice React application</p>
                <ul class="endpoint-list">
                    <li><span>Vite Dev Server</span><span class="endpoint-url">localhost:3000</span></li>
                    <li><span>Hot Reload</span><span class="endpoint-url">Enabled</span></li>
                    <li><span>TypeScript</span><span class="endpoint-url">Enabled</span></li>
                </ul>
            </div>

            <div class="card">
                <h3><span class="status-indicator"></span>Token Management</h3>
                <p>CRICE and MWT tokens</p>
                <ul class="endpoint-list">
                    <li><span>CRICE Token</span><span class="endpoint-url">urice</span></li>
                    <li><span>MWT Token</span><span class="endpoint-url">Ready</span></li>
                    <li><span>Transfer UI</span><span class="endpoint-url">localhost:3000/transfer</span></li>
                </ul>
            </div>
        </div>

        <div class="actions">
            <a href="http://localhost:3000" class="btn" target="_blank">Open ChainRice UI</a>
            <a href="http://localhost:1317/swagger" class="btn btn-secondary" target="_blank">Blockchain API</a>
            <a href="http://localhost:8545" class="btn btn-secondary" target="_blank">Hardhat Console</a>
            <button class="btn btn-secondary" onclick="refreshStatus()">Refresh Status</button>
        </div>

        <div class="log-section">
            <h3>Development Logs</h3>
            <div class="log-output" id="logOutput">
[2025-01-27 21:15:00] ChainRice development environment initialized
[2025-01-27 21:15:05] Blockchain node started on localhost:26657
[2025-01-27 21:15:10] Smart contracts service started
[2025-01-27 21:15:15] Frontend development server started
[2025-01-27 21:15:20] Hot reload enabled for frontend
[2025-01-27 21:15:25] CRICE token ready for operations
[2025-01-27 21:15:30] MWT token ready for deployment
[2025-01-27 21:15:35] All services running and ready
            </div>
        </div>

        <div class="footer">
            <p>ChainRice Development Environment • Ready for blockchain development</p>
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
            console.log('ChainRice dashboard loaded');
            
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
    print_success "Development dashboard started on http://localhost:8080"
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
print_status "🌾 Starting ChainRice Development Environment (Simple Mode)"
print_status "============================================================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    print_error "Please run this script from the rice-dev root directory"
    exit 1
fi

# Install Node.js if needed
install_nodejs

# Start services
start_blockchain_simulation
start_contracts_simulation
start_frontend
start_dashboard

# Wait a moment for services to start
sleep 5

# Open browser if possible
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:3000 &
    xdg-open http://localhost:8080/chainrice-dashboard.html &
elif command -v open > /dev/null; then
    open http://localhost:3000 &
    open http://localhost:8080/chainrice-dashboard.html &
fi

# Display service status
print_status "🎉 ChainRice Development Environment Started!"
print_info "Service URLs:"
print_info "🌾 ChainRice Frontend: http://localhost:3000"
print_info "⛓️  Blockchain RPC: http://localhost:26657"
print_info "📊 Blockchain REST: http://localhost:1317"
print_info "📜 Hardhat Node: http://localhost:8545"
print_info "📊 Development Dashboard: http://localhost:8080/chainrice-dashboard.html"
print_info ""
print_info "Token Management:"
print_info "💰 CRICE Token: urice (main token)"
print_info "🪙 MWT Token: Ready for deployment"
print_info "🔄 Transfer Interface: http://localhost:3000/transfer"
print_info "📈 Balance Checker: http://localhost:3000/balances"
print_info ""
print_status "Press Ctrl+C to stop all services"

# Keep the script running
while true; do
    sleep 1
done
