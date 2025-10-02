#!/bin/bash
# Development Services Startup Script
# Starts all services concurrently with hot reload

set -e

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
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"
}

print_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

# Function to check if a port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function to wait for a service to be ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=0
    
    print_info "Waiting for $service_name to be ready on port $port..."
    
    while [ $attempt -lt $max_attempts ]; do
        if check_port $port; then
            sleep 1
            attempt=$((attempt + 1))
        else
            print_status "$service_name is ready!"
            return 0
        fi
    done
    
    print_error "$service_name failed to start within $max_attempts seconds"
    return 1
}

# Function to start a service with hot reload
start_service() {
    local service_name=$1
    local port=$2
    local command=$3
    local working_dir=$4
    
    print_status "Starting $service_name on port $port..."
    
    if [ -n "$working_dir" ]; then
        cd "$working_dir"
    fi
    
    # Start the service in background
    eval "$command" > "/tmp/${service_name}.log" 2>&1 &
    local pid=$!
    
    # Store PID for cleanup
    echo $pid > "/tmp/${service_name}.pid"
    
    # Wait for service to be ready
    if wait_for_service "$service_name" "$port"; then
        print_status "$service_name started successfully (PID: $pid)"
    else
        print_error "$service_name failed to start"
        return 1
    fi
}

# Function to cleanup on exit
cleanup() {
    print_info "Shutting down all services..."
    
    # Kill all background processes
    for pid_file in /tmp/*.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                print_info "Stopping process $pid..."
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done
    
    # Clean up log files
    rm -f /tmp/*.log
    
    print_status "All services stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main execution
print_status "🚀 Starting Rice-Dev Monorepo Development Environment"
print_status "=================================================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    print_error "Please run this script from the rice-dev root directory"
    exit 1
fi

# Check if nix is available
if ! command -v nix &> /dev/null; then
    print_error "Nix is not installed or not in PATH"
    exit 1
fi

# Check if concurrently is available
if ! command -v concurrently &> /dev/null; then
    print_warning "concurrently not found, installing via npm..."
    npm install -g concurrently || {
        print_error "Failed to install concurrently"
        exit 1
    }
fi

# Start services concurrently
print_status "Starting all services with hot reload..."

# Start Python FastAPI Bot Core (Port 8000)
if [ -f "bots/core/main.py" ]; then
    start_service "bot-core" 8000 "uvicorn main:app --host 0.0.0.0 --port 8000 --reload" "bots/core"
fi

# Start Python FastAPI Connection Service (Port 8001)
if [ -f "libs/connection/FastAPI/main.py" ]; then
    start_service "fastapi-connection" 8001 "uvicorn main:app --host 0.0.0.0 --port 8001 --reload" "libs/connection/FastAPI"
fi

# Start Go Backend Service (Port 8080)
if [ -f "libs/backend/main.go" ]; then
    start_service "go-backend" 8080 "go run main.go" "libs/backend"
fi

# Start Java/JVM Connection Service (Port 8081)
if [ -f "libs/connection/JVM/pom.xml" ]; then
    start_service "jvm-connection" 8081 "mvn spring-boot:run -Dspring-boot.run.arguments='--server.port=8081'" "libs/connection/JVM"
fi

# Start .NET Connection Service (Port 8082)
if [ -f "libs/connection/.NET/ConnectionDotNet.csproj" ]; then
    start_service "dotnet-connection" 8082 "dotnet run --urls http://0.0.0.0:8082" "libs/connection/.NET"
fi

# Start PHP Connection Service (Port 8083)
if [ -f "libs/connection/PHP/composer.json" ]; then
    start_service "php-connection" 8083 "php -S 0.0.0.0:8083" "libs/connection/PHP"
fi

# Start TypeScript Frontend Services
if [ -f "libs/frontend/ts/package.json" ]; then
    # Angular Frontend (Port 4200)
    if [ -d "libs/frontend/ts/angular" ]; then
        start_service "angular-frontend" 4200 "npm run start" "libs/frontend/ts/angular"
    fi
    
    # Next.js Frontend (Port 3000)
    if [ -d "libs/frontend/ts/next" ]; then
        start_service "next-frontend" 3000 "npm run dev" "libs/frontend/ts/next"
    fi
    
    # Nuxt Frontend (Port 3001)
    if [ -d "libs/frontend/ts/nuxt" ]; then
        start_service "nuxt-frontend" 3001 "npm run dev" "libs/frontend/ts/nuxt"
    fi
    
    # Svelte Frontend (Port 3002)
    if [ -d "libs/frontend/ts/svelte" ]; then
        start_service "svelte-frontend" 3002 "npm run dev" "libs/frontend/ts/svelte"
    fi
fi

# Start Flutter Frontend (Port 3003)
if [ -f "libs/frontend/dart/pubspec.yaml" ]; then
    start_service "flutter-frontend" 3003 "flutter run -d web-server --web-port 3003" "libs/frontend/dart"
fi

# Start Julia Model Service (Port 8004)
if [ -f "bots/models/main.jl" ]; then
    start_service "julia-models" 8004 "julia main.jl" "bots/models"
fi

# Start Rust Contract Service (Port 8005)
if [ -f "libs/contract/rust/Cargo.toml" ]; then
    start_service "rust-contracts" 8005 "cargo run" "libs/contract/rust"
fi

# Start Kafka and Zookeeper
if command -v kafka-topics &> /dev/null; then
    print_status "Starting Kafka and Zookeeper..."
    
    # Start Zookeeper
    start_service "zookeeper" 2181 "zookeeper-server-start.sh config/zookeeper.properties" "."
    
    # Wait for Zookeeper
    sleep 5
    
    # Start Kafka
    start_service "kafka" 9092 "kafka-server-start.sh config/server.properties" "."
fi

# Start Redis (if available)
if command -v redis-server &> /dev/null; then
    start_service "redis" 6379 "redis-server" "."
fi

# Start PostgreSQL (if available)
if command -v postgres &> /dev/null; then
    start_service "postgres" 5432 "postgres -D /tmp/postgres_data" "."
fi

# Display service status
print_status "All services started! Service URLs:"
print_info "🤖 Bot Core API: http://localhost:8000"
print_info "🔗 FastAPI Connection: http://localhost:8001"
print_info "🐹 Go Backend: http://localhost:8080"
print_info "☕ JVM Connection: http://localhost:8081"
print_info "🔷 .NET Connection: http://localhost:8082"
print_info "🐘 PHP Connection: http://localhost:8083"
print_info "📱 Angular Frontend: http://localhost:4200"
print_info "⚛️  Next.js Frontend: http://localhost:3000"
print_info "🔥 Nuxt Frontend: http://localhost:3001"
print_info "🎯 Svelte Frontend: http://localhost:3002"
print_info "📱 Flutter Frontend: http://localhost:3003"
print_info "🔬 Julia Models: http://localhost:8004"
print_info "🦀 Rust Contracts: http://localhost:8005"
print_info "📨 Kafka: localhost:9092"
print_info "🔴 Redis: localhost:6379"
print_info "🐘 PostgreSQL: localhost:5432"

print_status "Press Ctrl+C to stop all services"

# Keep the script running
while true; do
    sleep 1
done

