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

.PHONY: govet govulncheck dev linux windows mac build-all up down restart logs open status web help

###################
### Development ###
###################

# Development environment
dev:
	@echo "🚀 Starting complete development environment..."
	./scripts/dev/start-dev.sh

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

build-all:
	@echo "🌍 Building for all platforms..."
	./scripts/platforms/build-all.sh

# Docker operations
up:
	@echo "🚀 Starting services..."
	./scripts/docker/docker-helper.sh up

down:
	@echo "🛑 Stopping services..."
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

# Legacy web command
web:
	@echo "Starting ChainRice Web Platform (Cafe Interface)..."
	./scripts/dev/start-web.sh

# Help command
help:
	@echo "🚀 Chain Rice Development Commands"
	@echo ""
	@echo "📋 Development:"
	@echo "  make dev          - Start complete development environment"
	@echo "  make up           - Start services"
	@echo "  make down         - Stop services"
	@echo "  make restart      - Restart services"
	@echo "  make logs         - View colored logs"
	@echo "  make status       - Show service status"
	@echo "  make open         - Open all development interfaces"
	@echo ""
	@echo "🏗️  Platform Builds:"
	@echo "  make linux        - Build for Linux platforms"
	@echo "  make windows      - Build for Windows platforms"
	@echo "  make mac          - Build for macOS platforms"
	@echo "  make build-all    - Build for all platforms"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  make test         - Run Go tests"
	@echo "  make test-unit    - Run unit tests"
	@echo "  make test-race    - Run tests with race detection"
	@echo "  make lint         - Run linter"
	@echo ""
	@echo "📚 Documentation:"
	@echo "  See docs/DEVELOPMENT.md for detailed setup instructions"