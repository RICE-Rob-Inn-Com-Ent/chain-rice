BRANCH ?= unknown
COMMIT ?= unknown
VERSION ?= dev
APPNAME := chain-rice

# do not override user values
ifeq (,$(VERSION))
  VERSION := $(shell git describe --exact-match 2>/dev/null)
  # if VERSION is empty, then populate it with branch name and raw commit hash
  ifeq (,$(VERSION))
    VERSION := $(BRANCH)-$(COMMIT)
  endif
endif

# Update the ldflags with the app, client & server names
ldflags = -X github.com/cosmos/cosmos-sdk/version.Name=$(APPNAME) \
	-X github.com/cosmos/cosmos-sdk/version.AppName=$(APPNAME) \
	-X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
	-X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT)

BUILD_FLAGS := -ldflags '$(ldflags)'

##############
###  Test  ###
##############

test-unit:
	@echo Running unit tests...
	@go test -mod=readonly -v -timeout 30m ./...

test-race:
	@echo Running unit tests with race condition reporting...
	@go test -mod=readonly -v -race -timeout 30m ./...

test-cover:
	@echo Running unit tests and creating coverage report...
	@go test -mod=readonly -v -timeout 30m -coverprofile=$(COVER_FILE) -covermode=atomic ./...
	@go tool cover -html=$(COVER_FILE) -o $(COVER_HTML_FILE)
	@rm $(COVER_FILE)

bench:
	@echo Running unit tests with benchmarking...
	@go test -mod=readonly -v -timeout 30m -bench=. ./...

test: govet govulncheck test-unit

.PHONY: test test-unit test-race test-cover bench

#################
###  Install  ###
#################

all: install

install:
	@echo "--> ensure dependencies have not been modified"
	@go mod verify
	@echo "--> installing $(APPNAME)"
	@go install $(BUILD_FLAGS) -mod=readonly ./cmd/chainrice

.PHONY: all install

##################
###  Protobuf  ###
##################

# Use this target if you do not want to use Ignite for generating proto files

proto-deps:
	@echo "Installing proto deps"
	@echo "Proto deps present, run 'go tool' to see them"

proto-gen:
	@echo "Generating protobuf files..."
	@ignite generate proto-go --yes

.PHONY: proto-gen

#################
###  Linting  ###
#################

lint:
	@echo "--> Running linter"
	@go tool github.com/golangci/golangci-lint/cmd/golangci-lint run ./... --timeout 15m

lint-fix:
	@echo "--> Running linter and fixing issues"
	@go tool github.com/golangci/golangci-lint/cmd/golangci-lint run ./... --fix --timeout 15m

.PHONY: lint lint-fix

###################
### Development ###
###################

govet:
	@echo Running go vet...
	@go vet ./...

govulncheck:
	@echo Running govulncheck...
	@go tool golang.org/x/vuln/cmd/govulncheck@latest
	@govulncheck ./...

.PHONY: govet govulncheck check setup prepare windows-setup dev linux windows mac build-all up down down-no-clean restart logs open status clean clean-images web help senior-ops astro-vision

###################
### Setup & Prep ###
###################

# Check system requirements
check:
	@echo "🔍 Checking system requirements..."
	@if [ -f "scripts/setup/check-system.sh" ]; then \
		chmod +x scripts/setup/check-system.sh && \
		./scripts/setup/check-system.sh; \
	elif [ -f "scripts/setup/check-system.ps1" ]; then \
		powershell -ExecutionPolicy Bypass -File scripts/setup/check-system.ps1; \
	elif [ -f "scripts/setup/check-system.bat" ]; then \
		scripts/setup/check-system.bat; \
	else \
		echo "❌ System check script not found"; \
		exit 1; \
	fi

# Setup development environment
setup:
	@echo "🛠️ Setting up development environment..."
	@if [ -f "scripts/setup/setup-environment.sh" ]; then \
		chmod +x scripts/setup/setup-environment.sh && \
		./scripts/setup/setup-environment.sh; \
	elif [ -f "scripts/setup/setup-environment.ps1" ]; then \
		powershell -ExecutionPolicy Bypass -File scripts/setup/setup-environment.ps1; \
	elif [ -f "scripts/setup/setup-environment.bat" ]; then \
		scripts/setup/setup-environment.bat; \
	else \
		echo "❌ Setup script not found"; \
		exit 1; \
	fi

# Prepare environment (check + setup)
prepare: check setup
	@echo "✅ Environment preparation completed!"

# Quick setup for Windows users
windows-setup:
	@echo "🪟 Setting up for Windows..."
	@if [ -f "scripts/setup/setup-environment.bat" ]; then \
		scripts/setup/setup-environment.bat; \
	else \
		echo "❌ Windows setup script not found"; \
		exit 1; \
	fi

.PHONY: check setup prepare windows-setup

###################
### Development ###
###################

# Development environment (with auto-setup)
dev: prepare
	@echo "🚀 Starting complete development environment..."
	./scripts/dev/start-dev.sh

# Run additional demo apps profile
apps:
	@echo "🚀 Starting additional senior apps (senior-ops, astro-vision)..."
	docker compose --profile apps up -d --build
	@echo "🌐 Open: senior-ops http://localhost:8088/health, astro-vision http://localhost:8089/health"

# Platform-specific builds
linux:
	@echo "🐧 Building for Linux platforms..."
	./scripts/platforms/build-linux.sh

windows:
	@echo "🪟 Building for Windows platforms..."
	./scripts/platforms/build-windows.sh

mac:
	@echo "🍎 Building for macOS platforms..."
	./scripts/platforms/build-mac.sh

build-all: prepare
	@echo "🌍 Building for all platforms..."
	./scripts/platforms/build-all.sh

# Docker operations (with auto-setup)
up: prepare
	@echo "🚀 Starting services..."
	./scripts/docker/docker-helper.sh up

down:
	@echo "🛑 Stopping services..."
	./scripts/docker/docker-helper.sh down
	@echo "🧹 Cleaning Docker cache..."
	@docker system prune -f --volumes || true
	@echo "✅ Docker cache cleaned!"

down-no-clean:
	@echo "🛑 Stopping services (keeping cache)..."
	./scripts/docker/docker-helper.sh down

restart:
	@echo "🔄 Restarting services..."
	./scripts/docker/docker-helper.sh restart

logs:
	@echo "📝 Showing logs..."
	./scripts/logs/colored-logs.sh

# Utilities
open:
	@echo "🌐 Opening development interfaces..."
	./scripts/utils/open-interfaces.sh

status:
	@echo "📊 Service status..."
	./scripts/docker/docker-helper.sh status

clean:
	@echo "🧹 Cleaning Docker cache and volumes..."
	@docker system prune -a --volumes -f
	@echo "✅ Docker cache and volumes cleaned!"

clean-images:
	@echo "🧹 Cleaning Docker images only..."
	@docker image prune -a -f
	@echo "✅ Docker images cleaned!"

# Web development (with auto-setup)
web: prepare
	@echo "Starting ChainRice Web Platform (Cafe Interface)..."
	./scripts/dev/start-web.sh

# Convenience targets for local runs
senior-ops:
	@echo "🏁 Building & running senior-ops (Docker)"
	docker compose up -d --build senior-ops
	@echo "Health: http://localhost:8088/health"

astro-vision:
	@echo "🏁 Building & running astro-vision (Docker)"
	docker compose up -d --build astro-vision-api astro-vision-worker astro-vision-redis
	@echo "Health: http://localhost:8089/health"

# Help command
help:
	@echo "🚀 Chain Rice Development Commands"
	@echo ""
	@echo "🛠️  Setup & Preparation:"
	@echo "  make check        - Check system requirements"
	@echo "  make setup        - Setup development environment"
	@echo "  make prepare      - Check + setup (recommended first run)"
	@echo "  make windows-setup - Quick setup for Windows users"
	@echo ""
	@echo "📋 Development:"
	@echo "  make dev          - Start complete development environment (auto-setup)"
	@echo "  make web          - Start web services only (auto-setup)"
	@echo "  make up           - Start services (auto-setup)"
	@echo "  make down         - Stop services and clean Docker cache"
	@echo "  make down-no-clean - Stop services (keep cache)"
	@echo "  make restart      - Restart services"
	@echo "  make logs         - View colored logs"
	@echo "  make status       - Show service status"
	@echo "  make open         - Open all development interfaces"
	@echo ""
	@echo "🏗️  Platform Builds:"
	@echo "  make linux        - Build for Linux platforms"
	@echo "  make windows      - Build for Windows platforms"
	@echo "  make mac          - Build for macOS platforms"
	@echo "  make build-all    - Build for all platforms (auto-setup)"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  make test         - Run Go tests"
	@echo "  make test-unit    - Run unit tests"
	@echo "  make test-race    - Run tests with race detection"
	@echo "  make lint         - Run linter"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean        - Clean Docker cache and volumes"
	@echo "  make clean-images - Clean Docker images only"
	@echo ""
	@echo "📚 Documentation:"
	@echo "  See docs/DEVELOPMENT.md for detailed setup instructions"
	@echo ""
	@echo "💡 Quick Start:"
	@echo "  make prepare      - First time setup"
	@echo "  make dev          - Start everything"