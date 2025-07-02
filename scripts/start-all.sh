#!/bin/bash

# Start all services with Docker Compose
echo "🚀 Starting all Meowtopia services..."

# Build and start all services
docker-compose up --build -d

echo "✅ All services started!"
echo ""
echo "📊 Service URLs:"
echo "🔗 Blockchain RPC:    http://localhost:26657"
echo "🔗 Blockchain API:    http://localhost:1317"
echo "🔗 Backend API:       http://localhost:8000"
echo "🔗 Web Frontend:      http://localhost:3000"
echo "🔗 PostgreSQL:        localhost:5432"
echo "🔗 Redis:             localhost:6379"
echo ""
echo "📋 To view logs: docker-compose logs -f"
echo "🛑 To stop all:  docker-compose down"
echo "🔄 To restart:   docker-compose restart"