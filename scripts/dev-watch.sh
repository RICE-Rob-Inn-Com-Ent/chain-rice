#!/usr/bin/env bash
set -euo pipefail

echo "🔥 RICE-DEV Monorepo - Development Watch Mode"
echo "============================================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Error: Please run this script from the rice-dev root directory"
    exit 1
fi

# Check if Nix is available
if ! command -v nix >/dev/null 2>&1; then
    echo "❌ Error: Nix is not installed. Please install Nix first."
    exit 1
fi

echo "📦 Building all targets first..."
nix develop .#monorepo --command bazel build //...

echo ""
echo "🔥 Starting development with hot reload..."

# Create logs directory
mkdir -p logs

# Start all services with hot reload in the monorepo shell
nix develop .#monorepo --command bash -c "
    echo '🚀 Starting all services with hot reload...'
    
    # Function to start a service with hot reload
    start_service() {
        local name=\$1
        local target=\$2
        local port=\$3
        local log_file=\"logs/\$name.log\"
        
        echo \"Starting \$name on port \$port...\"
        bazel run \$target --watch > \"\$log_file\" 2>&1 &
        local pid=\$!
        echo \"\$name started with PID: \$pid\"
        echo \$pid > \"logs/\$name.pid\"
    }
    
    # Start Frontend Services
    start_service 'nextjs' '//libs/frontend/ts/next:dev' '3000'
    start_service 'angular' '//libs/frontend/ts/angular:dev' '4200'
    start_service 'nuxt' '//libs/frontend/ts/nuxt:dev' '3001'
    
    # Start Backend Services
    start_service 'go-backend' '//libs/backend:dev' '8080'
    start_service 'fastapi' '//libs/connection/FastAPI:dev' '8000'
    start_service 'beam' '//libs/connection/BEAM:dev' '4000'
    
    # Start Bot Services
    start_service 'bot-core' '//bots/core:dev' '5000'
    start_service 'bot-integration' '//bots/integration:dev' '5001'
    
    # Start Blockchain Services
    start_service 'rust-blockchain' '//libs/contract/rust:dev' '9000'
    start_service 'solidity' '//libs/contract/solidity:dev' '9001'
    
    echo ''
    echo '🎉 All services started with hot reload!'
    echo '====================================='
    echo ''
    echo '📊 Service URLs:'
    echo '  Frontend:'
    echo '    - Next.js:     http://localhost:3000'
    echo '    - Angular:     http://localhost:4200'
    echo '    - Nuxt:        http://localhost:3001'
    echo ''
    echo '  Backend APIs:'
    echo '    - Go Backend:  http://localhost:8080'
    echo '    - FastAPI:     http://localhost:8000'
    echo '    - BEAM/Elixir: http://localhost:4000'
    echo ''
    echo '  Bot Services:'
    echo '    - Core Bot:    http://localhost:5000'
    echo '    - Integration: http://localhost:5001'
    echo ''
    echo '  Blockchain:'
    echo '    - Rust:        http://localhost:9000'
    echo '    - Solidity:    http://localhost:9001'
    echo ''
    echo '📝 Logs:'
    echo '  - All logs are in the logs/ directory'
    echo '  - Use \"tail -f logs/<service>.log\" to follow specific service logs'
    echo '  - Use \"tail -f logs/*.log\" to follow all logs'
    echo ''
    echo '🛑 Press Ctrl+C to stop all services'
    echo ''
    
    # Function to cleanup on exit
    cleanup() {
        echo ''
        echo '🛑 Stopping all services...'
        
        # Kill all services by PID files
        for pid_file in logs/*.pid; do
            if [ -f \"\$pid_file\" ]; then
                local pid=\$(cat \"\$pid_file\")
                local service=\$(basename \"\$pid_file\" .pid)
                echo \"Stopping \$service (PID: \$pid)...\"
                kill \$pid 2>/dev/null || true
                rm \"\$pid_file\"
            fi
        done
        
        # Kill any remaining bazel processes
        pkill -f 'bazel run' 2>/dev/null || true
        
        echo '✅ All services stopped.'
        exit 0
    }
    
    # Set up signal handlers
    trap cleanup SIGINT SIGTERM
    
    # Keep the script running
    echo '🔥 Hot reload is active. Watching for changes...'
    while true; do
        sleep 1
    done
"
