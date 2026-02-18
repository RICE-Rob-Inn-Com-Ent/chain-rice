#!/bin/sh
# Entrypoint for ceramix-database with autopatch support

set -e

cd /app

echo "🚀 Starting Ceramix Database Service"
echo "====================================="

# Check if autopatch was triggered
if [ -f /tmp/.autopatch-trigger ]; then
    echo "🔄 Autopatch triggered - detected source/config changes"
    echo "   Rebuilding Go service..."
    
    # Rebuild if go.mod or source files changed
    if [ -f go.mod ]; then
        go mod download
        go build -o database-service .
    else
        go build -o database-service .
    fi
    
    rm -f /tmp/.autopatch-trigger
    echo "✅ Rebuild complete"
    echo ""
fi

# Start autopatch monitor in background
echo "🔧 Starting autopatcher..."
/autopatch.sh &
AUTOPATCH_PID=$!

cleanup() {
    echo ""
    echo "🛑 Shutting down..."
    kill $AUTOPATCH_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Start the service
echo "📦 Starting database service..."
echo ""

exec ./database-service







































