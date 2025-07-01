#!/bin/bash

# ChainRice Complete Ecosystem Startup Script
# This script starts the entire ChainRice platform including web, mobile, and blockchain

set -e

echo "🌟 Starting ChainRice Complete Ecosystem..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_web() {
    echo -e "${CYAN}[WEB]${NC} $1"
}

print_mobile() {
    echo -e "${PURPLE}[MOBILE]${NC} $1"
}

print_blockchain() {
    echo -e "${YELLOW}[BLOCKCHAIN]${NC} $1"
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

# Function to check if a port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        print_warning "Port $port is already in use. Please stop the service using this port first."
        return 1
    fi
    return 0
}

# Check all required ports
print_status "Checking port availability..."
check_port 3000 || exit 1
check_port 8080 || exit 1
check_port 8081 || exit 1
check_port 26657 || exit 1
check_port 5432 || exit 1
check_port 6379 || exit 1

# Create environment files
print_status "Setting up environment files..."

# Web frontend .env
if [ ! -f "web-frontend/.env" ]; then
    cat > web-frontend/.env << EOF
VITE_API_URL=http://localhost:8080
VITE_BLOCKCHAIN_RPC_URL=http://localhost:26657
VITE_CHAIN_ID=chainrice-local
VITE_APP_NAME=ChainRice Cafe
VITE_APP_VERSION=1.0.0
EOF
    print_success "Created web-frontend/.env"
fi

# Mobile backend .env
if [ ! -f "mobile-backend/.env" ]; then
    cat > mobile-backend/.env << EOF
PORT=8081
DATABASE_URL=postgresql://postgres:password@localhost:5432/chainrice_mobile
REDIS_URL=redis://localhost:6379
BLOCKCHAIN_RPC_URL=http://localhost:26657
JWT_SECRET=your-super-secret-jwt-key-mobile
NODE_ENV=development
EOF
    print_success "Created mobile-backend/.env"
fi

# Backend .env
if [ ! -f "backend/.env" ]; then
    cat > backend/.env << EOF
PORT=8080
DATABASE_URL=postgresql://postgres:password@localhost:5432/chainrice
REDIS_URL=redis://localhost:6379
BLOCKCHAIN_RPC_URL=http://localhost:26657
JWT_SECRET=your-super-secret-jwt-key
NODE_ENV=development
EOF
    print_success "Created backend/.env"
fi

# Install dependencies
print_status "Installing dependencies..."

# Web frontend dependencies
if [ ! -d "web-frontend/node_modules" ]; then
    print_status "Installing web frontend dependencies..."
    cd web-frontend
    npm install
    cd ..
    print_success "Web frontend dependencies installed"
fi

# Mobile backend dependencies
if [ ! -d "mobile-backend/node_modules" ]; then
    print_status "Installing mobile backend dependencies..."
    cd mobile-backend
    npm install
    cd ..
    print_success "Mobile backend dependencies installed"
fi

# Backend dependencies
if [ ! -d "backend/node_modules" ]; then
    print_status "Installing backend dependencies..."
    cd backend
    npm install
    cd ..
    print_success "Backend dependencies installed"
fi

# Start all services with Docker Compose
print_status "Starting ChainRice ecosystem with Docker Compose..."
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 15

# Check if services are running
print_status "Checking service status..."
if docker-compose ps | grep -q "Up"; then
    print_success "All backend services are running"
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
sleep 5

# Check if the server started successfully
if kill -0 $WEB_PID 2>/dev/null; then
    print_success "Web frontend started successfully!"
else
    print_error "Failed to start web frontend"
    cd ..
    docker-compose down
    exit 1
fi

cd ..

# Display comprehensive status
echo ""
echo "🌟 ChainRice Ecosystem is now running!"
echo ""
print_web "Web Platform (Cafe Interface):"
echo "   🌐 Web Interface: http://localhost:3000"
echo "   🔗 API Documentation: http://localhost:8080/api-docs"
echo "   📊 Health Check: http://localhost:8080/health"
echo ""

print_mobile "Mobile Platform (Games):"
echo "   📱 Mobile Backend API: http://localhost:8081"
echo "   📱 Mobile API Health: http://localhost:8081/health"
echo "   🤖 Android Project: mobile/android/"
echo "   🍎 iOS Project: mobile/ios/ChainRiceMobile.xcodeproj"
echo ""

print_blockchain "Blockchain Services:"
echo "   ⛓️  Blockchain RPC: http://localhost:26657"
echo "   🔗 REST API: http://localhost:1317"
echo "   📡 WebSocket: ws://localhost:26657/websocket"
echo "   📊 Blockchain Explorer: http://localhost:26657/status"
echo ""

echo "🗄️  Database Services:"
echo "   🐘 PostgreSQL: localhost:5432"
echo "   🔴 Redis: localhost:6379"
echo ""

echo "🔧 Development Tools:"
echo "   📝 API Testing: Use Postman or curl to test endpoints"
echo "   🐳 Docker Management: docker-compose logs [service]"
echo "   🔍 Service Monitoring: docker-compose ps"
echo ""

echo "📱 Mobile Development Setup:"
echo "   🤖 Android: Open mobile/android/ in Android Studio"
echo "   🍎 iOS: Open mobile/ios/ChainRiceMobile.xcodeproj in Xcode"
echo ""

echo "🧪 Testing:"
echo "   🧪 Run Tests: ./scripts/run-tests.sh"
echo "   📊 Test Coverage: ./scripts/test-coverage.sh"
echo ""

# Function to cleanup on exit
cleanup() {
    print_status "Stopping ChainRice ecosystem..."
    kill $WEB_PID 2>/dev/null || true
    docker-compose down
    print_success "All services stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

print_status "ChainRice ecosystem is running. Press Ctrl+C to stop all services."
print_status "Keep this terminal open to monitor the services."

# Keep the script running and monitor services
while true; do
    sleep 30
    # Check if services are still running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Some services stopped unexpectedly"
        docker-compose ps
        break
    fi
    
    # Check if web frontend is still running
    if ! kill -0 $WEB_PID 2>/dev/null; then
        print_error "Web frontend stopped unexpectedly"
        break
    fi
    
    print_status "All services are running normally..."
done 