# ChainRice Nix Development Environment Makefile
.PHONY: help dev dev-go dev-react dev-julia dev-python dev-infra build clean update check lint

# Default target
help: ## Show this help message
	@echo "ChainRice Nix Development Environment"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

# Development environments
dev: ## Enter the complete development environment
	nix develop

dev-go: ## Enter Go development environment
	nix develop .#go

dev-react: ## Enter React development environment  
	nix develop .#react

dev-nextjs: ## Enter Next.js development environment
	nix develop .#nextjs

dev-rust: ## Enter Rust development environment
	nix develop .#rust

dev-proto: ## Enter Protocol Buffers development environment
	nix develop .#proto

dev-julia: ## Enter Julia development environment
	nix develop .#julia

dev-python: ## Enter Python development environment
	nix develop .#python

dev-infra: ## Enter infrastructure development environment
	nix develop .#infra

# Build and test
build: ## Build all ChainRice components
	nix develop -c make -C ../../backend/go build

test: ## Run all tests
	nix develop .#go -c sh -c "cd ../../backend/go && go test ./..."
	nix develop .#react -c sh -c "cd ../../frontend/react && npm test"
	nix develop .#nextjs -c sh -c "cd ../../frontend/next && npm test"
	nix develop .#rust -c sh -c "cd ../../contracts/rust && cargo test"
	nix develop .#proto -c sh -c "cd ../../contracts/proto && buf lint"
	nix develop .#julia -c sh -c "cd ../../functions/julia && julia --project=. -e 'using Pkg; Pkg.test()'"
	nix develop .#python -c sh -c "cd ../../backend/python && python -m pytest"

# Maintenance
update: ## Update flake inputs
	nix flake update

check: ## Check flake configuration
	nix flake check

clean: ## Clean build artifacts and caches
	rm -rf ../../backend/go/build/*
	rm -rf ../../frontend/react/dist
	rm -rf ../../frontend/react/node_modules
	nix-collect-garbage

# Linting and formatting
lint: ## Lint all code
	nix develop .#go -c sh -c "cd ../../backend/go && golangci-lint run"
	nix develop .#react -c sh -c "cd ../../frontend/react && npm run lint"
	nix develop .#nextjs -c sh -c "cd ../../frontend/next && npm run lint"
	nix develop .#rust -c sh -c "cd ../../contracts/rust && cargo clippy"
	nix develop .#proto -c sh -c "cd ../../contracts/proto && buf lint"
	nix develop .#python -c sh -c "cd ../../backend/python && flake8 ."

format: ## Format all code
	nix develop .#go -c sh -c "cd ../../backend/go && goimports -w ."
	nix develop .#react -c sh -c "cd ../../frontend/react && npm run format"
	nix develop .#nextjs -c sh -c "cd ../../frontend/next && npm run format"
	nix develop .#rust -c sh -c "cd ../../contracts/rust && cargo fmt"
	nix develop .#proto -c sh -c "cd ../../contracts/proto && buf format -w"
	nix develop .#python -c sh -c "cd ../../backend/python && black ."

# Services
start-services: ## Start all ChainRice services
	nix develop -c make -C ../.. tax-web-open

stop-services: ## Stop all ChainRice services
	nix develop -c make -C ../.. tax-stop

status: ## Check service status
	nix develop -c make -C ../.. tax-status-simple

# Infrastructure
infra-init: ## Initialize infrastructure
	nix develop .#infra -c sh -c "cd ../terraform && terraform init"
	nix develop .#infra -c sh -c "cd ../ansible && ansible-galaxy collection install -r requirements.yml"

infra-plan: ## Plan infrastructure changes
	nix develop .#infra -c sh -c "cd ../terraform && terraform plan"

infra-apply: ## Apply infrastructure changes
	nix develop .#infra -c sh -c "cd ../terraform && terraform apply"

# Docker operations
docker-build: ## Build Docker images
	nix develop .#infra -c sh -c "cd ../docker && docker-compose build"

docker-up: ## Start Docker services
	nix develop .#infra -c sh -c "cd ../docker && docker-compose up -d"

docker-down: ## Stop Docker services
	nix develop .#infra -c sh -c "cd ../docker && docker-compose down"

# Database operations
db-migrate: ## Run database migrations
	nix develop .#go -c make -C ../../backend/go tax-db-migrate

db-seed: ## Seed database with sample data
	nix develop .#go -c make -C ../../backend/go tax-db-seed

db-reset: ## Reset database
	nix develop .#go -c make -C ../../backend/go tax-db-reset

# Development shortcuts
install: ## Install all dependencies
	nix develop .#go -c sh -c "cd ../../backend/go && go mod download"
	nix develop .#react -c sh -c "cd ../../frontend/react && npm install"
	nix develop .#nextjs -c sh -c "cd ../../frontend/next && npm install"
	nix develop .#rust -c sh -c "cd ../../contracts/rust && cargo fetch"
	nix develop .#proto -c sh -c "cd ../../contracts/proto && buf mod update"
	nix develop .#julia -c sh -c "cd ../../functions/julia && julia --project=. -e 'using Pkg; Pkg.instantiate()'"
	nix develop .#python -c sh -c "cd ../../backend/python && pip install -e ."

upgrade: ## Upgrade all dependencies
	nix develop .#go -c sh -c "cd ../../backend/go && go get -u ./..."
	nix develop .#react -c sh -c "cd ../../frontend/react && npm update"
	nix develop .#nextjs -c sh -c "cd ../../frontend/next && npm update"
	nix develop .#rust -c sh -c "cd ../../contracts/rust && cargo update"
	nix develop .#proto -c sh -c "cd ../../contracts/proto && buf mod update"
	nix develop .#julia -c sh -c "cd ../../functions/julia && julia --project=. -e 'using Pkg; Pkg.update()'"
	nix develop .#python -c sh -c "cd ../../backend/python && pip install --upgrade -e ."

# Information
info: ## Show environment information
	@echo "ChainRice Development Environment Information"
	@echo "==========================================="
	@echo "Nix Flake: $(shell pwd)/flake.nix"
	@echo "Project Root: $(shell realpath ../..)"
	@echo ""
	@echo "Available shells:"
	@echo "  • default - Complete development environment"
	@echo "  • go      - Go development (Cosmos SDK + Tax API)"
	@echo "  • react   - React frontend development"
	@echo "  • nextjs  - Next.js full-stack development"
	@echo "  • rust    - Rust smart contracts (CosmWasm)"
	@echo "  • proto   - Protocol Buffers with Buf"
	@echo "  • julia   - Julia functions development" 
	@echo "  • python  - Python backend services"
	@echo "  • infra   - Infrastructure tools"
	@echo ""
	@echo "Services:"
	@echo "  • React Frontend:  http://localhost:5173"
	@echo "  • Next.js Frontend: http://localhost:3000"
	@echo "  • Tax API:         http://localhost:8003"
	@echo "  • Blockchain:      http://localhost:1317"

# Debugging
debug: ## Debug Nix environment
	nix develop --verbose

shell-info: ## Show shell environment info
	nix develop -c env | grep -E "(CHAINRICE|NIX|GO|NODE|JULIA|PYTHON|DOCKER|TERRAFORM|ANSIBLE)" | sort
