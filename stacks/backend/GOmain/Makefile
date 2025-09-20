# ChainRice Go Services Makefile

.PHONY: help build test clean deps blockchain accounting-api tax-api shared

# Default target
help:
	@echo "ChainRice Go Services - Available targets:"
	@echo ""
	@echo "  build          - Build all services"
	@echo "  test           - Run all tests"
	@echo "  clean          - Clean build artifacts"
	@echo "  deps           - Download dependencies for all modules"
	@echo ""
	@echo "  blockchain     - Build blockchain service"
	@echo "  accounting-api - Build accounting API service"
	@echo "  tax-api        - Build tax API service"
	@echo "  shared         - Build shared components"
	@echo ""
	@echo "  run-blockchain     - Run blockchain service"
	@echo "  run-accounting-api - Run accounting API service"
	@echo "  run-tax-api        - Run tax API service"
	@echo ""

# Build all services
build: blockchain accounting-api tax-api

# Run all tests
test:
	@echo "Running tests for shared module..."
	cd shared && go test ./...
	@echo "Running tests for blockchain module..."
	cd blockchain && go test ./...
	@echo "Running tests for accounting-api module..."
	cd accounting-api && go test ./...
	@echo "Running tests for tax-api module..."
	cd tax-api && go test ./...

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf blockchain/build
	rm -rf accounting-api/build
	rm -rf tax-api/build
	rm -f *.db

# Download dependencies
deps:
	@echo "Downloading dependencies for shared module..."
	cd shared && go mod tidy
	@echo "Downloading dependencies for blockchain module..."
	cd blockchain && go mod tidy
	@echo "Downloading dependencies for accounting-api module..."
	cd accounting-api && go mod tidy
	@echo "Downloading dependencies for tax-api module..."
	cd tax-api && go mod tidy

# Build blockchain service
blockchain:
	@echo "Building blockchain service..."
	cd blockchain && go build -o build/chainrice cmd/main.go

# Build accounting API service
accounting-api:
	@echo "Building accounting API service..."
	cd accounting-api && go build -o build/accounting-api cmd/accounting-api/main.go

# Build tax API service
tax-api:
	@echo "Building tax API service..."
	cd tax-api && go build -o build/tax-api cmd/tax-api/main.go

# Build shared components
shared:
	@echo "Building shared components..."
	cd shared && go build ./...

# Run blockchain service
run-blockchain: blockchain
	@echo "Starting blockchain service..."
	cd blockchain && ./build/chainrice start

# Run accounting API service
run-accounting-api: accounting-api
	@echo "Starting accounting API service..."
	cd accounting-api && ./build/accounting-api

# Run tax API service
run-tax-api: tax-api
	@echo "Starting tax API service..."
	cd tax-api && ./build/tax-api

# Run all services
run-all: run-blockchain run-accounting-api run-tax-api

# Development mode - run all services with hot reload
dev:
	@echo "Starting all services in development mode..."
	@echo "Blockchain: http://localhost:1317"
	@echo "Accounting API: http://localhost:8002"
	@echo "Tax API: http://localhost:8003"
	@echo ""
	@echo "Press Ctrl+C to stop all services"
	@echo ""
	@trap 'kill 0' EXIT; \
		make run-blockchain & \
		make run-accounting-api & \
		make run-tax-api & \
		wait

# Install dependencies and build
install: deps build

# Full clean and rebuild
rebuild: clean deps build

# Check code quality
lint:
	@echo "Running linter for shared module..."
	cd shared && golangci-lint run
	@echo "Running linter for blockchain module..."
	cd blockchain && golangci-lint run
	@echo "Running linter for accounting-api module..."
	cd accounting-api && golangci-lint run
	@echo "Running linter for tax-api module..."
	cd tax-api && golangci-lint run

# Format code
fmt:
	@echo "Formatting code..."
	cd shared && go fmt ./...
	cd blockchain && go fmt ./...
	cd accounting-api && go fmt ./...
	cd tax-api && go fmt ./...

# Generate protobuf files
proto:
	@echo "Generating protobuf files..."
	# Add protobuf generation commands here

# Docker commands
docker-build:
	@echo "Building Docker images..."
	docker build -t chainrice/blockchain ./blockchain
	docker build -t chainrice/accounting-api ./accounting-api
	docker build -t chainrice/tax-api ./tax-api

docker-run:
	@echo "Running services with Docker Compose..."
	docker-compose up -d

docker-stop:
	@echo "Stopping Docker services..."
	docker-compose down