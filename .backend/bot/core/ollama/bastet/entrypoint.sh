#!/bin/bash
set -e

echo "🐱 Bastet - Goddess of Vision awakening..."
echo "=================================="

# Start FastAPI server
echo "🚀 Starting Bastet API server..."
python /app/server.py

# Keep container running
tail -f /dev/null

