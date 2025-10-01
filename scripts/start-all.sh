#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting RICE-DEV Monorepo - All Services"
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
echo "🎯 Starting all services..."

# Start services in background with proper logging
echo "🌐 Starting Frontend Services..."
nix develop .#monorepo --command bash -c "
    echo 'Starting Next.js frontend on port 3000...'
    bazel run //libs/frontend/ts/next:dev --watch > logs/nextjs.log 2>&1 &
    NEXTJS_PID=\$!
    
    echo 'Starting Angular frontend on port 4200...'
    bazel run //libs/frontend/ts/angular:dev --watch > logs/angular.log 2>&1 &
    ANGULAR_PID=\$!
    
    echo 'Starting Nuxt frontend on port 3001...'
    bazel run //libs/frontend/ts/nuxt:dev --watch > logs/nuxt.log 2>&1 &
    NUXT_PID=\$!
    
    echo 'Frontend services started!'
    echo \"NextJS PID: \$NEXTJS_PID\"
    echo \"Angular PID: \$ANGULAR_PID\"
    echo \"Nuxt PID: \$NUXT_PID\"
    
    # Wait for frontend services
    wait \$NEXTJS_PID \$ANGULAR_PID \$NUXT_PID
" &

echo "🔧 Starting Backend Services..."
nix develop .#monorepo --command bash -c "
    echo 'Starting Go backend on port 8080...'
    bazel run //libs/backend:dev --watch > logs/go-backend.log 2>&1 &
    GO_PID=\$!
    
    echo 'Starting FastAPI backend on port 8000...'
    bazel run //libs/connection/FastAPI:dev --watch > logs/fastapi.log 2>&1 &
    FASTAPI_PID=\$!
    
    echo 'Starting BEAM/Elixir backend on port 4000...'
    bazel run //libs/connection/BEAM:dev --watch > logs/beam.log 2>&1 &
    BEAM_PID=\$!
    
    echo 'Backend services started!'
    echo \"Go PID: \$GO_PID\"
    echo \"FastAPI PID: \$FASTAPI_PID\"
    echo \"BEAM PID: \$BEAM_PID\"
    
    # Wait for backend services
    wait \$GO_PID \$FASTAPI_PID \$BEAM_PID
" &

echo "🤖 Starting Bot Services..."
nix develop .#monorepo --command bash -c "
    echo 'Starting Core Bot service...'
    bazel run //bots/core:dev --watch > logs/bot-core.log 2>&1 &
    BOT_CORE_PID=\$!
    
    echo 'Starting Integration Bot service...'
    bazel run //bots/integration:dev --watch > logs/bot-integration.log 2>&1 &
    BOT_INTEGRATION_PID=\$!
    
    echo 'Bot services started!'
    echo \"Bot Core PID: \$BOT_CORE_PID\"
    echo \"Bot Integration PID: \$BOT_INTEGRATION_PID\"
    
    # Wait for bot services
    wait \$BOT_CORE_PID \$BOT_INTEGRATION_PID
" &

echo "⛓️ Starting Blockchain Services..."
nix develop .#monorepo --command bash -c "
    echo 'Starting Rust blockchain service...'
    bazel run //libs/contract/rust:dev --watch > logs/rust-blockchain.log 2>&1 &
    RUST_PID=\$!
    
    echo 'Starting Solidity contracts...'
    bazel run //libs/contract/solidity:dev --watch > logs/solidity.log 2>&1 &
    SOLIDITY_PID=\$!
    
    echo 'Blockchain services started!'
    echo \"Rust PID: \$RUST_PID\"
    echo \"Solidity PID: \$SOLIDITY_PID\"
    
    # Wait for blockchain services
    wait \$RUST_PID \$SOLIDITY_PID
" &

# Create logs directory
mkdir -p logs

echo ""
echo "🎉 All services are starting up!"
echo "================================"
echo ""
echo "📊 Service Status:"
echo "  Frontend Services:"
echo "    - Next.js:     http://localhost:3000"
echo "    - Angular:     http://localhost:4200"
echo "    - Nuxt:        http://localhost:3001"
echo ""
echo "  Backend Services:"
echo "    - Go Backend:  http://localhost:8080"
echo "    - FastAPI:     http://localhost:8000"
echo "    - BEAM/Elixir: http://localhost:4000"
echo ""
echo "  Bot Services:"
echo "    - Core Bot:    Running"
echo "    - Integration: Running"
echo ""
echo "  Blockchain Services:"
echo "    - Rust:        Running"
echo "    - Solidity:    Running"
echo ""
echo "📝 Logs are available in:"
echo "  - logs/nextjs.log"
echo "  - logs/angular.log"
echo "  - logs/nuxt.log"
echo "  - logs/go-backend.log"
echo "  - logs/fastapi.log"
echo "  - logs/beam.log"
echo "  - logs/bot-core.log"
echo "  - logs/bot-integration.log"
echo "  - logs/rust-blockchain.log"
echo "  - logs/solidity.log"
echo ""
echo "🛑 To stop all services: Ctrl+C"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all services..."
    pkill -f "bazel run" || true
    echo "✅ All services stopped."
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Wait for all background processes
wait
