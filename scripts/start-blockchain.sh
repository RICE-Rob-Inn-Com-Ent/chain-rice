#!/bin/bash

# Start only the blockchain service
echo "⛓️  Starting Blockchain service..."

# Build and start blockchain
docker-compose up --build blockchain -d

echo "✅ Blockchain started!"
echo ""
echo "🔗 Blockchain RPC: http://localhost:26657"
echo "🔗 Blockchain API: http://localhost:1317"
echo "🔗 gRPC:          localhost:9090"
echo "🔗 gRPC-Web:      localhost:9091"
echo ""
echo "📋 To view logs: docker-compose logs -f blockchain"
echo ""
echo "🔧 Useful commands:"
echo "   Check status:     curl http://localhost:26657/status"
echo "   View validators:  curl http://localhost:26657/validators"