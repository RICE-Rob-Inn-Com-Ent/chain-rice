#!/bin/sh
set -e

echo "🚀 Starting Dual Frontend Server..."
echo "📦 Vite UI Kit   → http://localhost:3001"
echo "⚡ Next.js App   → http://localhost:3002"

# Start Vite dev server in background
cd /app/.frontend/web
yarn dev --host 0.0.0.0 --port ${VITE_PORT:-3001} &
VITE_PID=$!

# Start Next.js dev server in foreground
cd /app/.project/web
yarn dev --port ${NEXT_PORT:-3002}

# If Next.js exits, kill Vite too
kill $VITE_PID 2>/dev/null || true
