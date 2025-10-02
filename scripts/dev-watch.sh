#!/bin/bash
# Hot Reload Development Script
# Watches for file changes and restarts services automatically

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

# Check if nodemon is available
if ! command -v nodemon &> /dev/null; then
    print_info "Installing nodemon for hot reload..."
    npm install -g nodemon
fi

# Check if concurrently is available
if ! command -v concurrently &> /dev/null; then
    print_info "Installing concurrently..."
    npm install -g concurrently
fi

print_status "🔥 Starting Hot Reload Development Environment"
print_status "============================================="

# Create nodemon configurations for different services
cat > nodemon-python.json << EOF
{
  "watch": ["bots/", "libs/connection/FastAPI/"],
  "ext": "py",
  "ignore": ["*.pyc", "__pycache__/", ".git/", "node_modules/"],
  "exec": "python -c 'import sys; print(\"Python hot reload triggered\")'",
  "env": {
    "PYTHONPATH": ".",
    "PYTHONUNBUFFERED": "1"
  }
}
EOF

cat > nodemon-go.json << EOF
{
  "watch": ["libs/backend/"],
  "ext": "go",
  "ignore": [".git/", "node_modules/", "*.log"],
  "exec": "go run libs/backend/main.go",
  "env": {
    "GOPATH": "$PWD/.gopath",
    "GOBIN": "$PWD/.gopath/bin"
  }
}
EOF

cat > nodemon-rust.json << EOF
{
  "watch": ["libs/contract/rust/"],
  "ext": "rs",
  "ignore": [".git/", "node_modules/", "target/"],
  "exec": "cargo run",
  "cwd": "libs/contract/rust"
}
EOF

cat > nodemon-typescript.json << EOF
{
  "watch": ["libs/frontend/ts/"],
  "ext": "ts,tsx,js,jsx,vue",
  "ignore": [".git/", "node_modules/", "dist/", "build/"],
  "exec": "npm run dev",
  "cwd": "libs/frontend/ts"
}
EOF

# Start hot reload for all services
print_status "Starting hot reload for all services..."

concurrently \
  --names "Python,Go,Rust,TypeScript" \
  --prefix-colors "red,blue,green,yellow" \
  "nodemon --config nodemon-python.json" \
  "nodemon --config nodemon-go.json" \
  "nodemon --config nodemon-rust.json" \
  "nodemon --config nodemon-typescript.json"

# Cleanup
rm -f nodemon-*.json

