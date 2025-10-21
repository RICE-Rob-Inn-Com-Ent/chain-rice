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

.PHONY: help prepare asdf-install asdf-plugins deps-install deps-update dev-start dev-stop \
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
	@echo "$(YELLOW)🚀 Quick Start (First Time Setup):$(NC)"
	@echo "  $(GREEN)make prepare$(NC)          - Complete development environment setup"
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
# FIRST TIME SETUP
# ==============================================================================
prepare: ## Complete setup for new developers (asdf + all dependencies + pre-commit)
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  $(GREEN)RICE-MONO COMPLETE SETUP$(NC) - New Developer Onboarding     $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)This will install:$(NC)"
	@echo "  1. asdf version manager (if not installed)"
	@echo "  2. All asdf plugins (Rust, Go, Node.js, Python, etc.)"
	@echo "  3. All tools from .tool-versions"
	@echo "  4. All project dependencies"
	@echo "  5. Pre-commit hooks"
	@echo ""
	@read -p "Continue? [Y/n] " -n 1 -r; \
	echo; \
	if [[ ! $$REPLY =~ ^[Nn]$$ ]]; then \
		$(MAKE) asdf-install && \
		$(MAKE) asdf-plugins && \
		$(MAKE) deps-install && \
		$(MAKE) pre-commit-install && \
		echo "" && \
		echo "$(GREEN)╔════════════════════════════════════════════════════════════════╗$(NC)" && \
		echo "$(GREEN)║$(NC)  ✅ Setup Complete! Environment is ready for development!    $(GREEN)║$(NC)" && \
		echo "$(GREEN)╚════════════════════════════════════════════════════════════════╝$(NC)" && \
		echo "" && \
		echo "$(YELLOW)🎯 Next Steps:$(NC)" && \
		echo "  1. Restart your shell or run: $(GREEN)source ~/.bashrc$(NC)" && \
		echo "  2. Start dev environment: $(GREEN)make dev-start$(NC)" && \
		echo "  3. Read documentation: $(GREEN)README.md$(NC)" && \
		echo "" && \
		echo "$(YELLOW)📝 Important Notes:$(NC)" && \
		echo "  • Add to ~/.bashrc: $(GREEN)source ~/.asdf/asdf.sh$(NC)" && \
		echo "  • Verify installation: $(GREEN)asdf list$(NC)" && \
		echo ""; \
	else \
		echo "$(YELLOW)Setup cancelled$(NC)"; \
	fi

asdf-install: ## Install asdf version manager
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Installing asdf Version Manager                               $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if command -v asdf >/dev/null 2>&1; then \
		echo "$(GREEN)✅ asdf is already installed$(NC)"; \
		asdf --version; \
	else \
		echo "$(YELLOW)📦 Installing asdf...$(NC)"; \
		git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0 && \
		echo "" && \
		echo "$(GREEN)✅ asdf installed successfully!$(NC)" && \
		echo "" && \
		echo "$(YELLOW)⚠️  Please add to your ~/.bashrc:$(NC)" && \
		echo "  . ~/.asdf/asdf.sh" && \
		echo "  . ~/.asdf/completions/asdf.bash" && \
		echo "" && \
		echo "$(YELLOW)Then restart your shell or run:$(NC) source ~/.bashrc"; \
	fi

asdf-plugins: ## Install all asdf plugins from .tool-versions
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Installing asdf Plugins                                       $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if ! command -v asdf >/dev/null 2>&1; then \
		echo "$(RED)❌ asdf not found! Run: make asdf-install$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)📦 Installing plugins and tools from .tool-versions...$(NC)"
	@echo ""
	@cat .tool-versions | grep -v "^#" | grep -v "^$$" | while read -r plugin version; do \
		if [ -n "$$plugin" ]; then \
			echo "$(YELLOW)  • $$plugin $$version$(NC)"; \
			asdf plugin add $$plugin 2>/dev/null || true; \
		fi; \
	done
	@echo ""
	@echo "$(YELLOW)🔨 Installing all tool versions (this may take 10-30 minutes)...$(NC)"
	@asdf install
	@echo ""
	@echo "$(GREEN)✅ All asdf plugins and tools installed!$(NC)"
	@echo ""
	@echo "$(YELLOW)Verify installation:$(NC)"
	@asdf current

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

	@echo "$(YELLOW)🌐 [5/8] Frontend Next.js (Yarn)$(NC)"
	@cd .frontend/next && yarn install && echo "$(GREEN)✅ Frontend dependencies installed$(NC)"
	@echo ""

	@echo "$(YELLOW)📱 [6/8] Flutter (Dart)$(NC)"
	@cd .frontend/flutter && flutter pub get && echo "$(GREEN)✅ Flutter dependencies installed$(NC)"
	@echo ""

	@echo "$(YELLOW)🖥️  [7/8] Project Web (npm)$(NC)"
	@cd .project/web && npm install && echo "$(GREEN)✅ Project web dependencies installed$(NC)"
	@echo ""

	@echo "$(YELLOW)🍎 [8/8] iOS (Swift)$(NC)"
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

	@echo "$(YELLOW)🌐 [5/8] Frontend Next.js - Yarn Upgrade$(NC)"
	@cd .frontend/next && yarn upgrade && echo "$(GREEN)✅ Frontend dependencies updated$(NC)"
	@echo ""

	@echo "$(YELLOW)📱 [6/8] Flutter (Dart) - Pub Upgrade$(NC)"
	@cd .frontend/flutter && flutter pub upgrade && echo "$(GREEN)✅ Flutter dependencies upgraded$(NC)"
	@echo ""

	@echo "$(YELLOW)🖥️  [7/8] Project Web - npm Update$(NC)"
	@cd .project/web && npm update && echo "$(GREEN)✅ Project web dependencies updated$(NC)"
	@echo ""

	@echo "$(YELLOW)🍎 [8/8] iOS (Swift) - Swift Package Update$(NC)"
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

# ==============================================================================
# PRE-COMMIT HOOKS
# ==============================================================================

.PHONY: pre-commit-install pre-commit-uninstall pre-commit-run pre-commit-run-all \
        pre-commit-update pre-commit-clean

pre-commit-install: ## Install pre-commit hooks
	@echo "$(BLUE)📦 Installing pre-commit hooks...$(NC)"
	@pre-commit install --install-hooks --hook-type pre-commit --hook-type commit-msg
	@echo "$(GREEN)✅ Pre-commit hooks installed$(NC)"

pre-commit-uninstall: ## Uninstall pre-commit hooks
	@echo "$(BLUE)🗑️  Uninstalling pre-commit hooks...$(NC)"
	@pre-commit uninstall --hook-type pre-commit --hook-type commit-msg
	@echo "$(GREEN)✅ Pre-commit hooks uninstalled$(NC)"

pre-commit-run: ## Run pre-commit on staged files
	@echo "$(BLUE)🔍 Running pre-commit on staged files...$(NC)"
	@pre-commit run

pre-commit-run-all: ## Run pre-commit on all files
	@echo "$(BLUE)🔍 Running pre-commit on ALL files...$(NC)"
	@pre-commit run --all-files

pre-commit-update: ## Update pre-commit hook versions
	@echo "$(BLUE)⬆️  Updating pre-commit hooks...$(NC)"
	@pre-commit autoupdate
	@echo "$(GREEN)✅ Pre-commit hooks updated$(NC)"

pre-commit-clean: ## Clean pre-commit cache
	@echo "$(BLUE)🧹 Cleaning pre-commit cache...$(NC)"
	@pre-commit clean
	@rm -rf ~/.cache/pre-commit
	@echo "$(GREEN)✅ Pre-commit cache cleaned$(NC)"

# ==============================================================================
# PROJECT SWAP - Dynamic Project Management
# ==============================================================================
.PHONY: swap project-list project-status project-save project-sync-repos

project-status: ## Show current project status
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Current Project Status                                        $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if [ -f .project-active ]; then \
		active=$$(cat .project-active); \
		echo "$(GREEN)Active Project: $$active$(NC)"; \
		if [ -d .project/.git ]; then \
			cd .project && \
			echo "" && \
			echo "$(YELLOW)Git Status:$(NC)" && \
			git status -s || echo "  Clean working directory" && \
			echo "" && \
			echo "$(YELLOW)Remote URL:$(NC)" && \
			git remote get-url origin 2>/dev/null || echo "  No remote configured" && \
			echo "" && \
			echo "$(YELLOW)Current Branch:$(NC)" && \
			git branch --show-current 2>/dev/null || echo "  Not on any branch"; \
		fi; \
	else \
		echo "$(RED)No active project$(NC)"; \
	fi
	@echo ""

project-sync-repos: ## Auto-sync repository list from GitHub (uses gh CLI or GITHUB_TOKEN)
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Syncing Projects from GitHub                                  $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then \
		echo "$(GREEN)✅ Using GitHub CLI (shows private repos)$(NC)"; \
		echo "$(YELLOW)Fetching repositories from RICE-Rob-Inn-Com-Ent...$(NC)"; \
		echo ""; \
		gh repo list RICE-Rob-Inn-Com-Ent --limit 100 --json name,url,description,defaultBranchRef > /tmp/repos.json; \
		echo "{" > .project-repos.json.tmp; \
		echo '  "projects": {' >> .project-repos.json.tmp; \
		first=true; \
		cat /tmp/repos.json | jq -r '.[] | select(.name != "rice-mono") | "\(.name)|\(.url)|\(.description // "No description")|\(.defaultBranchRef.name // "main")"' | while IFS='|' read -r name url desc branch; do \
			if [ "$$first" = false ]; then echo "," >> .project-repos.json.tmp; fi; \
			first=false; \
			key=$$(echo "$$name" | tr '[:upper:]' '[:lower:]' | tr '-' '_'); \
			echo "    \"$$key\": {" >> .project-repos.json.tmp; \
			echo "      \"name\": \"$$name\"," >> .project-repos.json.tmp; \
			echo "      \"url\": \"$$url\"," >> .project-repos.json.tmp; \
			echo "      \"branch\": \"$$branch\"," >> .project-repos.json.tmp; \
			echo "      \"description\": \"$$desc\"" >> .project-repos.json.tmp; \
			echo -n "    }" >> .project-repos.json.tmp; \
			echo "  $(GREEN)✓$(NC) $$name"; \
		done; \
		echo "" >> .project-repos.json.tmp; \
		echo "  }" >> .project-repos.json.tmp; \
		echo "}" >> .project-repos.json.tmp; \
		mv .project-repos.json.tmp .project-repos.json; \
	elif [ -n "$$GITHUB_TOKEN" ]; then \
		echo "$(GREEN)✅ Using GITHUB_TOKEN (shows private repos)$(NC)"; \
		echo "$(YELLOW)Fetching repositories from RICE-Rob-Inn-Com-Ent...$(NC)"; \
		echo ""; \
		repos=$$(curl -s -H "Authorization: token $$GITHUB_TOKEN" "https://api.github.com/orgs/RICE-Rob-Inn-Com-Ent/repos?per_page=100"); \
		echo "{" > .project-repos.json.tmp; \
		echo '  "projects": {' >> .project-repos.json.tmp; \
		first=true; \
		echo "$$repos" | jq -r '.[] | select(.name != "rice-mono") | "\(.name)|\(.clone_url)|\(.description // "No description")|\(.default_branch)"' | while IFS='|' read -r name url desc branch; do \
			if [ "$$first" = false ]; then echo "," >> .project-repos.json.tmp; fi; \
			first=false; \
			key=$$(echo "$$name" | tr '[:upper:]' '[:lower:]' | tr '-' '_'); \
			echo "    \"$$key\": {" >> .project-repos.json.tmp; \
			echo "      \"name\": \"$$name\"," >> .project-repos.json.tmp; \
			echo "      \"url\": \"$$url\"," >> .project-repos.json.tmp; \
			echo "      \"branch\": \"$$branch\"," >> .project-repos.json.tmp; \
			echo "      \"description\": \"$$desc\"" >> .project-repos.json.tmp; \
			echo -n "    }" >> .project-repos.json.tmp; \
			echo "  $(GREEN)✓$(NC) $$name"; \
		done; \
		echo "" >> .project-repos.json.tmp; \
		echo "  }" >> .project-repos.json.tmp; \
		echo "}" >> .project-repos.json.tmp; \
		mv .project-repos.json.tmp .project-repos.json; \
	else \
		echo "$(RED)❌ Cannot access private repositories$(NC)"; \
		echo ""; \
		echo "$(YELLOW)To sync private repos, either:$(NC)"; \
		echo ""; \
		echo "  $(GREEN)Option 1: GitHub CLI (recommended)$(NC)"; \
		echo "    1. Install: curl -sL https://github.com/cli/cli/releases/download/v2.42.1/gh_2.42.1_linux_amd64.tar.gz | tar xz"; \
		echo "    2. Login: gh auth login"; \
		echo "    3. Run: make project-sync-repos"; \
		echo ""; \
		echo "  $(GREEN)Option 2: GitHub Token$(NC)"; \
		echo "    1. Create token: https://github.com/settings/tokens"; \
		echo "    2. Export: export GITHUB_TOKEN=ghp_xxxxx"; \
		echo "    3. Run: make project-sync-repos"; \
		echo ""; \
		echo "  $(GREEN)Option 3: Manual$(NC)"; \
		echo "    Edit .project-repos.json directly"; \
		echo ""; \
		exit 1; \
	fi; \
	echo ""; \
	echo "$(GREEN)✅ Synced repositories to .project-repos.json$(NC)"; \
	echo ""; \
	$(MAKE) project-list

project-list: ## List all configured projects
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Available Projects (from GitHub)                              $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if [ ! -f .project-repos.json ]; then \
		echo "$(YELLOW)No .project-repos.json found. Syncing from GitHub...$(NC)"; \
		$(MAKE) project-sync-repos; \
	fi
	@current=""; \
	if [ -f .project-active ]; then current=$$(cat .project-active); fi; \
	echo "$(YELLOW)Configured Projects:$(NC)"; \
	echo ""; \
	if command -v jq >/dev/null 2>&1; then \
		cat .project-repos.json | jq -r '.projects | to_entries[] | "\(.key)|\(.value.name)|\(.value.url)"' | \
		while IFS='|' read -r key name url; do \
			if [ "$$key" = "$$current" ]; then \
				echo "  $(GREEN)★ $$key$(NC) - $$name"; \
				echo "    $(GREEN)  ↳ $$url (ACTIVE)$(NC)"; \
			else \
				echo "  $(YELLOW)  $$key$(NC) - $$name"; \
				echo "      ↳ $$url"; \
			fi; \
			echo ""; \
		done; \
	else \
		echo "$(RED)jq not installed - install with: sudo pacman -S jq$(NC)"; \
		grep -o '"[^"]*": {' .project-repos.json | sed 's/": {//' | sed 's/"//g' | while read key; do \
			echo "  $$key"; \
		done; \
	fi

swap: ## Swap to a different project (make swap PROJECT=code_rice or interactive)
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)  Project Swap - Change Active Project                          $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if [ ! -f .project-repos.json ]; then \
		echo "$(RED)Error: .project-repos.json not found$(NC)"; \
		echo "$(YELLOW)Run: make project-sync-repos$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d .project/.git ]; then \
		echo "$(YELLOW)Initializing .project as git repository...$(NC)"; \
		cd .project && git init && git branch -m main 2>/dev/null || true; \
		echo "$(GREEN)✅ .project initialized$(NC)"; \
		echo ""; \
	fi
	@current="none"; \
	if [ -f .project-active ]; then current=$$(cat .project-active); fi; \
	echo "$(YELLOW)Current project: $$current$(NC)"; \
	echo ""; \
	cd .project && { \
		if [ -n "$$(git status --porcelain)" ]; then \
			echo "$(YELLOW)⚠️  Uncommitted changes detected!$(NC)"; \
			echo ""; \
			git status -s; \
			echo ""; \
			read -p "Commit and push changes? [Y/n] " -r; \
			if [[ ! $$REPLY =~ ^[Nn]$$ ]]; then \
				read -p "Commit message: " msg; \
				git add -A && \
				git commit -m "$$msg" && \
				git push origin $$(git branch --show-current) && \
				echo "$(GREEN)✅ Changes committed and pushed$(NC)"; \
			else \
				echo "$(RED)❌ Cannot swap with uncommitted changes$(NC)"; \
				exit 1; \
			fi; \
		else \
			echo "$(GREEN)✅ Working directory clean$(NC)"; \
			git push origin $$(git branch --show-current) 2>/dev/null || echo "$(YELLOW)Nothing to push$(NC)"; \
		fi; \
	}; \
	echo ""; \
	echo "$(YELLOW)Saving current project to cache...$(NC)"; \
	mkdir -p .project-cache/$$current; \
	rsync -a --delete .project/ .project-cache/$$current/ --exclude .git 2>/dev/null || cp -r .project/* .project-cache/$$current/ 2>/dev/null || true; \
	echo "$(GREEN)✅ Cached: .project-cache/$$current/$(NC)"; \
	echo ""; \
	if [ -n "$(PROJECT)" ]; then \
		selected="$(PROJECT)"; \
		echo "$(YELLOW)Selected project: $$selected$(NC)"; \
		if ! cat .project-repos.json | jq -e ".projects.$$selected" >/dev/null 2>&1; then \
			echo "$(RED)Error: Project '$$selected' not found in .project-repos.json$(NC)"; \
			echo ""; \
			echo "$(YELLOW)Available projects:$(NC)"; \
			cat .project-repos.json | jq -r '.projects | keys[]' | while read key; do \
				echo "  - $$key"; \
			done; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)Available projects:$(NC)"; \
		echo ""; \
		i=1; \
		declare -a keys; \
		declare -a names; \
		while IFS='|' read -r key name; do \
			keys[$$i]=$$key; \
			names[$$i]=$$name; \
			if [ "$$key" = "$$current" ]; then \
				echo "  $$i. $$key - $$name $(GREEN)(current)$(NC)"; \
			else \
				echo "  $$i. $$key - $$name"; \
			fi; \
			i=$$((i+1)); \
		done < <(cat .project-repos.json | jq -r '.projects | to_entries[] | "\(.key)|\(.value.name)"'); \
		max=$$((i-1)); \
		echo ""; \
		read -p "Select project number [1-$$max]: " choice; \
		if [ -z "$$choice" ] || [ "$$choice" -lt 1 ] || [ "$$choice" -gt "$$max" ]; then \
			echo "$(RED)Invalid choice$(NC)"; \
			exit 1; \
		fi; \
		selected=$${keys[$$choice]}; \
	fi; \
	url=$$(cat .project-repos.json | jq -r ".projects.$$selected.url"); \
	branch=$$(cat .project-repos.json | jq -r ".projects.$$selected.branch"); \
	echo ""; \
	echo "$(YELLOW)Switching to: $$selected$(NC)"; \
	echo "$(YELLOW)Repository: $$url$(NC)"; \
	echo "$(YELLOW)Branch: $$branch$(NC)"; \
	echo ""; \
	cd .project && { \
		git remote set-url origin $$url 2>/dev/null || git remote add origin $$url; \
		echo "$(YELLOW)Fetching from $$url...$(NC)"; \
		git fetch origin $$branch 2>/dev/null || true; \
		if [ -d ../.project-cache/$$selected ] && [ -n "$$(ls -A ../.project-cache/$$selected 2>/dev/null)" ]; then \
			echo "$(YELLOW)Restoring from cache...$(NC)"; \
			find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +; \
			rsync -a ../.project-cache/$$selected/ ./ --exclude .git 2>/dev/null || cp -r ../.project-cache/$$selected/* ./ 2>/dev/null || true; \
		fi; \
		git checkout $$branch 2>/dev/null || git checkout -b $$branch 2>/dev/null || true; \
		echo "$(YELLOW)Pulling latest changes...$(NC)"; \
		git pull origin $$branch 2>/dev/null || echo "$(YELLOW)⚠️  Pull failed - might be first time$(NC)"; \
		if [ ! -d ../.project-cache/$$selected ] || [ -z "$$(ls -A ../.project-cache/$$selected 2>/dev/null)" ]; then \
			echo "$(YELLOW)Caching fresh copy...$(NC)"; \
			mkdir -p ../.project-cache/$$selected; \
			rsync -a ./ ../.project-cache/$$selected/ --exclude .git 2>/dev/null || cp -r ./* ../.project-cache/$$selected/ 2>/dev/null || true; \
		fi; \
	}; \
	echo "$$selected" > .project-active; \
	echo ""; \
	echo "$(GREEN)╔════════════════════════════════════════════════════════════════╗$(NC)"; \
	echo "$(GREEN)║$(NC)  ✅ Switched to: $$selected                                     $(GREEN)║$(NC)"; \
	echo "$(GREEN)╚════════════════════════════════════════════════════════════════╝$(NC)"; \
	echo ""; \
	echo "$(YELLOW)Next steps:$(NC)"; \
	echo "  cd .project"; \
	echo "  git status"

project-save: ## Manually save current project to cache
	@if [ ! -f .project-active ]; then \
		echo "$(RED)No active project$(NC)"; \
		exit 1; \
	fi
	@current=$$(cat .project-active); \
	echo "$(YELLOW)Saving $$current to cache...$(NC)"; \
	mkdir -p .project-cache/$$current; \
	rsync -a --delete .project/ .project-cache/$$current/ --exclude .git 2>/dev/null || cp -r .project/* .project-cache/$$current/; \
	echo "$(GREEN)✅ Saved to .project-cache/$$current/$(NC)"
