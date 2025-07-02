#!/bin/bash

# Start only the web frontend service
echo "🌐 Starting Web Frontend service..."

# Start web frontend and its dependencies
docker-compose up --build web-frontend backend postgres redis -d

echo "✅ Web Frontend started!"
echo ""
echo "🔗 Web Frontend: http://localhost:3000"
echo "🔗 Backend API:  http://localhost:8000"
echo ""
echo "📋 To view logs: docker-compose logs -f web-frontend"