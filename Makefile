# ==============================================================================
# RICE-MONO MAKEFILE
# ==============================================================================
# Enterprise monorepo development automation
# ==============================================================================
#
# Quick Commands:
#   make deps-install  - Install all project dependencies
#   make deps-update   - Update all dependencies to latest versions
#   make dev-start     - Start development environment with hot reload
#   make dev-stop      - Stop all development containers
#
# Documentation: .helper/ROOT.md
# ==============================================================================

.PHONY: help deps-install deps-update dev-start dev-stop \
        blockchain-install blockchain-build blockchain-start blockchain-proto \
        blockchain-test blockchain-test-race blockchain-test-cover \
        blockchain-lint blockchain-lint-fix blockchain-clean blockchain-reset

# Default target - show help
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# ==============================================================================
# HELP
# ==============================================================================
help: ## Show this help message
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  $(GREEN)RICE-MONO MAKEFILE$(NC) - Enterprise Monorepo Automation  $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Available Commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Documentation:$(NC)"
	@echo "  • Root files guide:     .helper/ROOT.md"
	@echo "  • Full documentation:   README.md"
	@echo ""

# ==============================================================================
# DEPENDENCIES INSTALLATION
# ==============================================================================
deps-install: ## Install all project dependencies (Python, Rust, Node, Flutter, Swift, Solidity, Go/Blockchain)
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Installing Dependencies - Rice Monorepo                    $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""

	@echo "$(YELLOW)📦 [1/7] Python (Bot)$(NC)"
	@cd .bot && poetry install && echo "$(GREEN)✅ Python dependencies installed$(NC)"
	@echo ""

	@echo "$(YELLOW)🦀 [2/7] Rust (Smart Contracts)$(NC)"
	@cd .backend/contract/rust && cargo fetch && echo "$(GREEN)✅ Rust dependencies fetched$(NC)"
	@echo ""

	@echo "$(YELLOW)💎 [3/7] Solidity (Hardhat)$(NC)"
	@cd .backend/contract/solidity && npm install && echo "$(GREEN)✅ Solidity dependencies installed$(NC)"
	@echo ""

	@echo "$(YELLOW)🔗 [4/7] Blockchain (Cosmos SDK / Go)$(NC)"
	@cd .backend/token && go mod download && echo "$(GREEN)✅ Blockchain dependencies downloaded$(NC)"
	@echo ""

	@echo "$(YELLOW)🌐 [5/7] Frontend Web (Yarn Workspaces)$(NC)"
	@cd .frontend/web && yarn install && echo "$(GREEN)✅ Frontend dependencies installed$(NC)"
	@echo ""

	@echo "$(YELLOW)📱 [6/7] Flutter (Dart)$(NC)"
	@cd .frontend/flutter && flutter pub get && echo "$(GREEN)✅ Flutter dependencies installed$(NC)"
	@echo ""

	@echo "$(YELLOW)🍎 [7/7] iOS (Swift)$(NC)"
	@cd .frontend/ios && swift package resolve && echo "$(GREEN)✅ Swift dependencies resolved$(NC)"
	@echo ""

	@echo "$(GREEN)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║$(NC)  ✅ All dependencies installed successfully!                 $(GREEN)║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════════╝$(NC)"

# ==============================================================================
# DEPENDENCIES UPDATE
# ==============================================================================
deps-update: ## Update all dependencies to latest compatible versions
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Updating Dependencies - Rice Monorepo                      $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""

	@echo "$(YELLOW)📦 [1/7] Python (Bot) - Poetry Update$(NC)"
	@cd .bot && poetry update && echo "$(GREEN)✅ Python dependencies updated$(NC)"
	@echo ""

	@echo "$(YELLOW)🦀 [2/7] Rust (Smart Contracts) - Cargo Update$(NC)"
	@cd .backend/contract/rust && cargo update && echo "$(GREEN)✅ Rust dependencies updated$(NC)"
	@echo ""

	@echo "$(YELLOW)💎 [3/7] Solidity (Hardhat) - npm Update$(NC)"
	@cd .backend/contract/solidity && npm update && echo "$(GREEN)✅ Solidity dependencies updated$(NC)"
	@echo ""

	@echo "$(YELLOW)🔗 [4/7] Blockchain (Cosmos SDK / Go) - Go Get Update$(NC)"
	@cd .backend/token && go get -u ./... && go mod tidy && echo "$(GREEN)✅ Blockchain dependencies updated$(NC)"
	@echo ""

	@echo "$(YELLOW)🌐 [5/7] Frontend Web - Yarn Upgrade$(NC)"
	@cd .frontend/web && yarn upgrade && echo "$(GREEN)✅ Frontend dependencies updated$(NC)"
	@echo ""

	@echo "$(YELLOW)📱 [6/7] Flutter (Dart) - Pub Upgrade$(NC)"
	@cd .frontend/flutter && flutter pub upgrade && echo "$(GREEN)✅ Flutter dependencies upgraded$(NC)"
	@echo ""

	@echo "$(YELLOW)🍎 [7/7] iOS (Swift) - Swift Package Update$(NC)"
	@cd .frontend/ios && swift package update && echo "$(GREEN)✅ Swift dependencies updated$(NC)"
	@echo ""

	@echo "$(GREEN)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║$(NC)  ✅ All dependencies updated successfully!                   $(GREEN)║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════════╝$(NC)"

# ==============================================================================
# DEVELOPMENT ENVIRONMENT
# ==============================================================================
dev-start: ## Start development environment with hot reload (Docker Compose)
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Starting Development Environment - Rice Monorepo            $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🚀 Starting services:$(NC)"
	@echo "  • PostgreSQL    (port 5432)"
	@echo "  • Redis         (port 6379)"
	@echo "  • Kafka         (port 9092)"
	@echo "  • RabbitMQ      (port 5672, UI: 15672)"
	@echo "  • MinIO         (port 9000, UI: 9001)"
	@echo "  • Elasticsearch (port 9200)"
	@echo "  • Logstash      (port 5044)"
	@echo "  • Prometheus    (port 9090)"
	@echo "  • Grafana       (port 3000)"
	@echo "  • Traefik       (port 80, UI: 8080)"
	@echo ""
	@cd .devcontainer && docker-compose up -d --build
	@echo ""
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║$(NC)  ✅ Development environment is running!                      $(GREEN)║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🔗 Service URLs:$(NC)"
	@echo "  • Grafana Dashboard:  http://localhost:3000 (admin/admin)"
	@echo "  • RabbitMQ UI:        http://localhost:15672 (rice_user/rice_password)"
	@echo "  • MinIO Console:      http://localhost:9001 (rice_admin/rice_password_123)"
	@echo "  • Traefik Dashboard:  http://localhost:8080"
	@echo "  • Prometheus:         http://localhost:9090"
	@echo ""
	@echo "$(YELLOW)📊 View Logs:$(NC)"
	@echo "  cd .devcontainer && docker-compose logs -f [service-name]"
	@echo ""

dev-stop: ## Stop development environment and clean up containers
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Stopping Development Environment                             $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@cd .devcontainer && docker-compose down
	@echo ""
	@echo "$(GREEN)✅ Development environment stopped$(NC)"
	@echo ""
	@echo "$(YELLOW)💡 To remove volumes (databases, caches):$(NC)"
	@echo "  cd .devcontainer && docker-compose down -v"
	@echo ""

# ==============================================================================
# BLOCKCHAIN (Cosmos SDK)
# ==============================================================================

# Blockchain variables
BLOCKCHAIN_DIR := .backend/token
BLOCKCHAIN_APP := tokenchain
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
COMMIT := $(shell git log -1 --format='%H')
VERSION := $(shell git describe --exact-match 2>/dev/null || echo "$(BRANCH)-$(COMMIT)")

blockchain-install: ## Install blockchain binary (tokenchaind)
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Installing Cosmos SDK Blockchain Binary                      $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@cd $(BLOCKCHAIN_DIR) && go mod verify
	@cd $(BLOCKCHAIN_DIR) && go install -mod=readonly ./cmd/$(BLOCKCHAIN_APP)d
	@echo ""
	@echo "$(GREEN)✅ $(BLOCKCHAIN_APP)d installed to $(shell go env GOPATH)/bin/$(NC)"

blockchain-build: ## Build blockchain binary
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Building Cosmos SDK Blockchain                                $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@cd $(BLOCKCHAIN_DIR) && go build -o ./build/$(BLOCKCHAIN_APP)d ./cmd/$(BLOCKCHAIN_APP)d
	@echo ""
	@echo "$(GREEN)✅ Binary built: $(BLOCKCHAIN_DIR)/build/$(BLOCKCHAIN_APP)d$(NC)"

blockchain-start: ## Start blockchain development server (Ignite)
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Starting Cosmos SDK Blockchain (Development)                  $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🚀 Starting blockchain with Ignite...$(NC)"
	@echo ""
	@cd $(BLOCKCHAIN_DIR) && ignite chain serve

blockchain-proto: ## Generate Go code from protobuf definitions
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Generating Protobuf Code                                      $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@cd $(BLOCKCHAIN_DIR) && ignite generate proto-go --yes
	@echo ""
	@echo "$(GREEN)✅ Protobuf code generated$(NC)"

blockchain-test: ## Run blockchain unit tests
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Running Blockchain Unit Tests                                 $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@cd $(BLOCKCHAIN_DIR) && go test -mod=readonly -v -timeout 30m ./...
	@echo ""
	@echo "$(GREEN)✅ All tests passed$(NC)"

blockchain-test-race: ## Run blockchain tests with race detector
	@echo "$(YELLOW)🔍 Running tests with race detector...$(NC)"
	@cd $(BLOCKCHAIN_DIR) && go test -mod=readonly -v -race -timeout 30m ./...

blockchain-test-cover: ## Run blockchain tests with coverage report
	@echo "$(YELLOW)📊 Running tests with coverage...$(NC)"
	@cd $(BLOCKCHAIN_DIR) && go test -mod=readonly -v -timeout 30m -coverprofile=coverage.out -covermode=atomic ./...
	@cd $(BLOCKCHAIN_DIR) && go tool cover -html=coverage.out -o coverage.html
	@echo "$(GREEN)✅ Coverage report: $(BLOCKCHAIN_DIR)/coverage.html$(NC)"

blockchain-lint: ## Run linter on blockchain code
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Linting Blockchain Code                                       $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@cd $(BLOCKCHAIN_DIR) && go tool github.com/golangci/golangci-lint/cmd/golangci-lint run ./... --timeout 15m
	@echo ""
	@echo "$(GREEN)✅ Linting complete$(NC)"

blockchain-lint-fix: ## Run linter and auto-fix issues
	@echo "$(YELLOW)🔧 Running linter with auto-fix...$(NC)"
	@cd $(BLOCKCHAIN_DIR) && go tool github.com/golangci/golangci-lint/cmd/golangci-lint run ./... --fix --timeout 15m

blockchain-clean: ## Clean blockchain build artifacts
	@echo "$(YELLOW)🧹 Cleaning blockchain build artifacts...$(NC)"
	@cd $(BLOCKCHAIN_DIR) && rm -rf build/ coverage.out coverage.html
	@echo "$(GREEN)✅ Cleaned$(NC)"

blockchain-reset: ## Reset blockchain data (WARNING: deletes all chain data)
	@echo "$(RED)⚠️  WARNING: This will delete all blockchain data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd $(BLOCKCHAIN_DIR) && ignite chain clean; \
		echo "$(GREEN)✅ Blockchain data reset$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

.PHONY: blockchain-install blockchain-build blockchain-start blockchain-proto \
        blockchain-test blockchain-test-race blockchain-test-cover \
        blockchain-lint blockchain-lint-fix blockchain-clean blockchain-reset
