# Chain Rice Go Backend Makefile

.PHONY: help build run clean test mod-tidy blockchain accounting

# Default target
help:
	@echo "Chain Rice Go Backend - Available commands:"
	@echo "  build      - Build all modules and main application"
	@echo "  run        - Run the main application"
	@echo "  blockchain - Run blockchain service only"
	@echo "  accounting - Run accounting service only"
	@echo "  test       - Run tests for all modules"
	@echo "  clean      - Clean build artifacts"
	@echo "  mod-tidy   - Tidy go modules"
	@echo "  help       - Show this help message"

# Build all modules and main application
build:
	@echo "Building Chain Rice Go Backend..."
	@mkdir -p build
	@go mod tidy
	@go build -o build/chain-rice main.go
	@cd blockchain && go mod tidy && go build -o ../build/blockchain .
	@cd accounting && go mod tidy && go build -o ../build/accounting .
	@chmod +x build/*
	@echo "Build complete! Binaries available in build/ directory"

# Run the main application
run: build
	@echo "Starting Chain Rice application..."
	@./build/chain-rice

# Run blockchain service only
blockchain: build
	@echo "Starting blockchain service..."
	@./build/blockchain

# Run accounting service only
accounting: build
	@echo "Starting accounting service..."
	@./build/accounting

# Run tests
test:
	@echo "Running tests..."
	@go test ./...

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -f *.db
	@echo "Clean complete!"

# Tidy go modules
mod-tidy:
	@echo "Tidying go modules..."
	@go mod tidy
	@cd blockchain && go mod tidy
	@cd accounting && go mod tidy
	@echo "Modules tidied!"

# Development mode with hot reload (requires air)
dev:
	@echo "Starting development mode with hot reload..."
	@air

# Install dependencies
deps:
	@echo "Installing dependencies..."
	@go mod download
	@cd blockchain && go mod download
	@cd accounting && go mod download
	@echo "Dependencies installed!"

# Format code
fmt:
	@echo "Formatting code..."
	@go fmt ./...
	@cd blockchain && go fmt ./...
	@cd accounting && go fmt ./...
	@echo "Code formatted!"

# Lint code
lint:
	@echo "Linting code..."
	@golangci-lint run ./...
	@cd blockchain && golangci-lint run ./...
	@cd accounting && golangci-lint run ./...
	@echo "Linting complete!"
