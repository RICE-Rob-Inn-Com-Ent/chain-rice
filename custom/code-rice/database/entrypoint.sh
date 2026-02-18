#!/bin/sh
# Entrypoint for code-rice-database with autopatch support
set -e

cd /app
echo "🚀 Starting Code-Rice Database Service"
echo "======================================="

if [ -f /tmp/.autopatch-trigger ]; then
    echo "🔄 Autopatch triggered - rebuilding Go service..."
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

echo "📦 Starting database service..."
echo ""
exec ./database-service







































