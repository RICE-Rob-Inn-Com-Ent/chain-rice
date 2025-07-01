#!/bin/bash

# ChainRice Web Platform Startup Script
# This script starts the web frontend (cafe interface) with Vite

set -e

echo "🚀 Starting ChainRice Web Platform (Cafe Interface)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if required files exist
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi

if [ ! -d "web-frontend" ]; then
    print_error "web-frontend directory not found."
    exit 1
fi

# Function to check if a port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        print_warning "Port $port is already in use. Please stop the service using this port first."
        return 1
    fi
    return 0
}

# Check required ports
print_status "Checking port availability..."
check_port 3000 || exit 1
check_port 8080 || exit 1
check_port 26657 || exit 1

# Create .env file for web frontend if it doesn't exist
if [ ! -f "web-frontend/.env" ]; then
    print_status "Creating .env file for web frontend..."
    cat > web-frontend/.env << EOF
VITE_API_URL=http://localhost:8080
VITE_BLOCKCHAIN_RPC_URL=http://localhost:26657
VITE_CHAIN_ID=chainrice-local
VITE_APP_NAME=ChainRice Cafe
VITE_APP_VERSION=1.0.0
EOF
    print_success "Created web-frontend/.env"
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "web-frontend/node_modules" ]; then
    print_status "Installing web frontend dependencies..."
    cd web-frontend
    npm install
    cd ..
    print_success "Dependencies installed"
fi

# Start the entire stack with Docker Compose
print_status "Starting ChainRice stack with Docker Compose..."
docker-compose up -d postgres redis blockchain backend

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Check if services are running
print_status "Checking service status..."
if docker-compose ps | grep -q "Up"; then
    print_success "Backend services are running"
else
    print_error "Failed to start backend services"
    docker-compose logs
    exit 1
fi

# Start web frontend in development mode
print_status "Starting web frontend in development mode..."
cd web-frontend

# Start Vite development server
print_status "Starting Vite development server..."
npm run dev &

# Store the PID
WEB_PID=$!

# Wait a moment for the server to start
sleep 3

# Check if the server started successfully
if kill -0 $WEB_PID 2>/dev/null; then
    print_success "Web frontend started successfully!"
    echo ""
    echo "🌐 Web Interface (Cafe): http://localhost:3000"
    echo "🔗 API Documentation: http://localhost:8080/api-docs"
    echo "⛓️  Blockchain RPC: http://localhost:26657"
    echo "🗄️  Database: localhost:5432"
    echo ""
    echo "Press Ctrl+C to stop all services"
    
    # Function to cleanup on exit
    cleanup() {
        print_status "Stopping services..."
        kill $WEB_PID 2>/dev/null || true
        cd ..
        docker-compose down
        print_success "All services stopped"
        exit 0
    }
    
    # Set trap to cleanup on script exit
    trap cleanup SIGINT SIGTERM
    
    # Keep the script running
    wait $WEB_PID
else
    print_error "Failed to start web frontend"
    cd ..
    docker-compose down
    exit 1
fi 