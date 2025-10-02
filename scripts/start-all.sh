#!/bin/bash
# Start All Services Script
# Simple script to start all services without hot reload

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

print_status "🚀 Starting All Rice-Dev Services"
print_status "================================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "Please run this script from the rice-dev root directory"
    exit 1
fi

# Start services in background
print_info "Starting services..."

# Python FastAPI Bot Core
if [ -f "bots/core/main.py" ]; then
    print_info "Starting Bot Core API..."
    cd bots/core && uvicorn main:app --host 0.0.0.0 --port 8000 &
    cd ../..
fi

# Python FastAPI Connection Service
if [ -f "libs/connection/FastAPI/main.py" ]; then
    print_info "Starting FastAPI Connection Service..."
    cd libs/connection/FastAPI && uvicorn main:app --host 0.0.0.0 --port 8001 &
    cd ../../..
fi

# Go Backend Service
if [ -f "libs/backend/main.go" ]; then
    print_info "Starting Go Backend Service..."
    cd libs/backend && go run main.go &
    cd ../..
fi

# Java/JVM Connection Service
if [ -f "libs/connection/JVM/pom.xml" ]; then
    print_info "Starting JVM Connection Service..."
    cd libs/connection/JVM && mvn spring-boot:run -Dspring-boot.run.arguments='--server.port=8081' &
    cd ../../..
fi

# .NET Connection Service
if [ -f "libs/connection/.NET/ConnectionDotNet.csproj" ]; then
    print_info "Starting .NET Connection Service..."
    cd libs/connection/.NET && dotnet run --urls http://0.0.0.0:8082 &
    cd ../../..
fi

# PHP Connection Service
if [ -f "libs/connection/PHP/composer.json" ]; then
    print_info "Starting PHP Connection Service..."
    cd libs/connection/PHP && php -S 0.0.0.0:8083 &
    cd ../../..
fi

# TypeScript Frontend Services
if [ -f "libs/frontend/ts/package.json" ]; then
    print_info "Starting TypeScript Frontend Services..."
    cd libs/frontend/ts
    
    # Start Angular if available
    if [ -d "angular" ]; then
        cd angular && npm run start &
        cd ..
    fi
    
    # Start Next.js if available
    if [ -d "next" ]; then
        cd next && npm run dev &
        cd ..
    fi
    
    # Start Nuxt if available
    if [ -d "nuxt" ]; then
        cd nuxt && npm run dev &
        cd ..
    fi
    
    # Start Svelte if available
    if [ -d "svelte" ]; then
        cd svelte && npm run dev &
        cd ..
    fi
    
    cd ../../..
fi

# Flutter Frontend
if [ -f "libs/frontend/dart/pubspec.yaml" ]; then
    print_info "Starting Flutter Frontend..."
    cd libs/frontend/dart && flutter run -d web-server --web-port 3003 &
    cd ../../..
fi

# Julia Model Service
if [ -f "bots/models/main.jl" ]; then
    print_info "Starting Julia Model Service..."
    cd bots/models && julia main.jl &
    cd ../..
fi

# Rust Contract Service
if [ -f "libs/contract/rust/Cargo.toml" ]; then
    print_info "Starting Rust Contract Service..."
    cd libs/contract/rust && cargo run &
    cd ../../..
fi

print_status "All services started!"
print_info "Service URLs:"
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

print_status "Press Ctrl+C to stop all services"

# Wait for user interrupt
wait

