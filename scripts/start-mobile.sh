#!/bin/bash

# ChainRice Mobile Platform Startup Script
# This script starts the mobile backend and provides instructions for mobile app development

set -e

echo -e "${PURPLE}📱 Starting Mobile Backend for Development...${NC}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_mobile() {
    echo -e "${PURPLE}[MOBILE]${NC} $1"
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

if [ ! -d "mobile-backend" ]; then
    print_error "mobile-backend directory not found."
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
check_port 8081 || exit 1
check_port 26657 || exit 1

# Create .env file for mobile backend if it doesn't exist
if [ ! -f "mobile-backend/.env" ]; then
    print_status "Creating .env file for mobile backend..."
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

# Install dependencies if node_modules doesn't exist
if [ ! -d "mobile-backend/node_modules" ]; then
    print_status "Installing mobile backend dependencies..."
    cd mobile-backend
    npm install
    cd ..
    print_success "Dependencies installed"
fi

# Start only the backend needed for mobile dev
docker-compose up -d meowtopia-backend

print_success "Backend started for mobile development."

echo ""
print_mobile "Mobile Platform Setup Complete!"
echo ""
echo "📱 Backend API: http://localhost:8000"
echo ""

# Android instructions
echo "🤖 Android (Kotlin) Development:"
echo "   1. Open Android Studio"
echo "   2. Open the project: mobile/android/"
echo "   3. Sync Gradle files"
echo "   4. Run the app on device/emulator"
echo "   5. API Base URL: http://10.0.2.2:8000 (emulator) or http://localhost:8000 (device)"
echo ""

# iOS instructions
echo "🍎 iOS (Swift) Development:"
echo "   1. Open Xcode"
echo "   2. Open the project: mobile/ios/ChainRiceMobile.xcodeproj"
echo "   3. Select your target device/simulator"
echo "   4. Build and run the project"
echo "   5. API Base URL: http://localhost:8000"
echo ""

# Blockchain integration info
echo "⛓️  Blockchain Integration:"
echo "   - Chain ID: chainrice-local"
echo "   - RPC URL: http://localhost:26657"
echo "   - REST API: http://localhost:1317"
echo "   - WebSocket: ws://localhost:26657/websocket"
echo ""

# Function to cleanup on exit
cleanup() {
    print_status "Stopping mobile services..."
    docker-compose down
    print_success "Mobile services stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

print_status "Mobile backend is running. Press Ctrl+C to stop."

# Keep the script running
while true; do
    sleep 10
    # Check if services are still running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Services stopped unexpectedly"
        break
    fi
done

# Start blockchain and backend (required for mobile development)
echo -e "${BLUE}⛓️  Starting blockchain and backend services...${NC}"
docker-compose up -d chain-rice-blockchain meowtopia-backend

echo -e "${GREEN}✅ Mobile development environment started!${NC}\n"

echo -e "${YELLOW}🔗 Mobile Development Endpoints:${NC}"
echo -e "  🟢 Blockchain RPC:    http://localhost:26657"
echo -e "  🟢 Backend API:        http://localhost:8000"
echo -e "  🟢 Mobile Backend:     http://localhost:8000/api/mobile\n"

echo -e "${YELLOW}📱 Mobile Development Info:${NC}"
echo -e "  📱 Mobile app directory: ./meowtopia/frontend/mobile/"
echo -e "  📱 Game documentation:   ./meowtopia/frontend/mobile/game.md\n"

echo -e "${YELLOW}📋 Logs & Monitoring:${NC}"
echo -e "  📝 Blockchain logs:     docker-compose logs -f chain-rice-blockchain"
echo -e "  📝 Backend logs:        docker-compose logs -f meowtopia-backend\n"

echo -e "${YELLOW}🔧 Mobile Development Commands:${NC}"
echo -e "  📱 Check backend health: curl http://localhost:8000/health"
echo -e "  📱 Blockchain status:    curl http://localhost:26657/status\n"

# Open mobile development interfaces in browser
echo -e "${BLUE}🌐 Opening mobile development interfaces in browser...${NC}"
sleep 3  # Wait for services to be ready

# Open backend API docs for mobile development
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:8000/docs &
elif command -v open > /dev/null; then
    open http://localhost:8000/docs &
elif command -v start > /dev/null; then
    start http://localhost:8000/docs &
fi

# Open backend health check
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:8000/health &
elif command -v open > /dev/null; then
    open http://localhost:8000/health &
elif command -v start > /dev/null; then
    start http://localhost:8000/health &
fi

# Open blockchain status for mobile integration
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:26657/status &
elif command -v open > /dev/null; then
    open http://localhost:26657/status &
elif command -v start > /dev/null; then
    start http://localhost:26657/status &
fi

echo -e "${GREEN}✅ Mobile development interfaces opened in browser!${NC}\n"

# Show colored logs for mobile development
echo -e "${BLUE}📝 Showing color-coded mobile development logs...${NC}"
./scripts/colored-logs.sh mobile 