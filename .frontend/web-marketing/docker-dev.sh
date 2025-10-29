#!/bin/bash

echo "🚀 Starting Rice Marketing Site (Port 3002)..."
echo ""

# Build and start
docker-compose -f docker-compose.dev.yml up --build -d

echo ""
echo "✅ Marketing site starting on http://localhost:3002"
echo "📝 Logs: docker logs -f rice-marketing"
echo "🛑 Stop: docker-compose -f docker-compose.dev.yml down"

