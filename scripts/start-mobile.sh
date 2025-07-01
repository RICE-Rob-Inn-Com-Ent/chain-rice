#!/bin/bash

# ChainRice Mobile Platform Startup Script
# This script starts the mobile backend and provides instructions for mobile app development

set -e

echo "🎮 Starting ChainRice Mobile Platform (Games)..."

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

# Start the backend services with Docker Compose
print_status "Starting ChainRice mobile backend services..."
docker-compose up -d postgres redis blockchain mobile-backend

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Check if services are running
print_status "Checking service status..."
if docker-compose ps | grep -q "Up"; then
    print_success "Mobile backend services are running"
else
    print_error "Failed to start mobile backend services"
    docker-compose logs
    exit 1
fi

# Display mobile development information
echo ""
print_mobile "Mobile Platform Setup Complete!"
echo ""
echo "📱 Mobile Backend API: http://localhost:8081"
echo "⛓️  Blockchain RPC: http://localhost:26657"
echo "🗄️  Database: localhost:5432"
echo ""

# Check for Android development environment
print_status "Checking Android development environment..."
if command -v adb &> /dev/null; then
    print_success "Android Debug Bridge (ADB) found"
    if adb devices | grep -q "device$"; then
        print_success "Android device/emulator connected"
        echo "📱 Connected Android devices:"
        adb devices
    else
        print_warning "No Android device/emulator connected"
        echo "💡 To connect an Android device:"
        echo "   1. Enable Developer Options on your device"
        echo "   2. Enable USB Debugging"
        echo "   3. Connect via USB or start an emulator"
    fi
else
    print_warning "Android Debug Bridge (ADB) not found"
    echo "💡 Install Android Studio to get ADB"
fi

# Check for iOS development environment
print_status "Checking iOS development environment..."
if command -v xcodebuild &> /dev/null; then
    print_success "Xcode found"
    if xcrun simctl list devices | grep -q "Booted"; then
        print_success "iOS simulator running"
        echo "📱 Running iOS simulators:"
        xcrun simctl list devices | grep "Booted"
    else
        print_warning "No iOS simulator running"
        echo "💡 To start an iOS simulator:"
        echo "   1. Open Xcode"
        echo "   2. Go to Xcode > Open Developer Tool > Simulator"
        echo "   3. Or run: xcrun simctl boot 'iPhone 15'"
    fi
else
    print_warning "Xcode not found"
    echo "💡 Install Xcode from the Mac App Store for iOS development"
fi

echo ""
print_mobile "Mobile Development Instructions:"
echo ""

# Android instructions
echo "🤖 Android (Kotlin) Development:"
echo "   1. Open Android Studio"
echo "   2. Open the project: mobile/android/"
echo "   3. Sync Gradle files"
echo "   4. Run the app on device/emulator"
echo "   5. API Base URL: http://10.0.2.2:8081 (emulator) or http://localhost:8081 (device)"
echo ""

# iOS instructions
echo "🍎 iOS (Swift) Development:"
echo "   1. Open Xcode"
echo "   2. Open the project: mobile/ios/ChainRiceMobile.xcodeproj"
echo "   3. Select your target device/simulator"
echo "   4. Build and run the project"
echo "   5. API Base URL: http://localhost:8081"
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

print_status "Mobile backend is running. Press Ctrl+C to stop all services."
print_status "Keep this terminal open while developing mobile apps."

# Keep the script running
while true; do
    sleep 10
    # Check if services are still running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Services stopped unexpectedly"
        break
    fi
done 