# Chain Rice Smart Contracts Makefile
# Provides convenient commands for generating and managing smart contracts

.PHONY: help generate-cw20 generate-dao generate-nft build test clean deploy

# Default target
help:
	@echo "🌾 Chain Rice Smart Contracts"
	@echo "=============================="
	@echo ""
	@echo "Available commands:"
	@echo "  generate-cw20 NAME     Generate CW20 token contract"
	@echo "  generate-dao NAME      Generate DAO governance contract"
	@echo "  generate-nft NAME      Generate NFT collection contract"
	@echo "  build                  Build all contracts"
	@echo "  test                   Run all tests"
	@echo "  clean                  Clean build artifacts"
	@echo "  deploy                 Deploy contracts (requires setup)"
	@echo ""
	@echo "Examples:"
	@echo "  make generate-cw20 rice-token"
	@echo "  make generate-dao rice-dao"
	@echo "  make generate-nft rice-nfts"

# Generate CW20 Token Contract
generate-cw20:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Please specify contract name: make generate-cw20 NAME=my-token"; \
		exit 1; \
	fi
	@echo "🚀 Generating CW20 Token Contract: $(NAME)"
	@./scripts/generate_contract.sh -n $(NAME) -t cw20

# Generate DAO Contract
generate-dao:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Please specify contract name: make generate-dao NAME=my-dao"; \
		exit 1; \
	fi
	@echo "🏛️ Generating DAO Contract: $(NAME)"
	@./scripts/generate_contract.sh -n $(NAME) -t dao

# Generate NFT Contract
generate-nft:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Please specify contract name: make generate-nft NAME=my-nft"; \
		exit 1; \
	fi
	@echo "🎨 Generating NFT Contract: $(NAME)"
	@./scripts/generate_contract.sh -n $(NAME) -t nft

# Build all contracts
build:
	@echo "🔨 Building all contracts..."
	@for contract in contracts/*/; do \
		if [ -d "$$contract" ]; then \
			echo "Building $$contract"; \
			cd "$$contract" && cargo build --release && cd ../..; \
		fi; \
	done
	@echo "✅ All contracts built successfully!"

# Run tests for all contracts
test:
	@echo "🧪 Running tests for all contracts..."
	@for contract in contracts/*/; do \
		if [ -d "$$contract" ]; then \
			echo "Testing $$contract"; \
			cd "$$contract" && cargo test && cd ../..; \
		fi; \
	done
	@echo "✅ All tests passed!"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@for contract in contracts/*/; do \
		if [ -d "$$contract" ]; then \
			echo "Cleaning $$contract"; \
			cd "$$contract" && cargo clean && cd ../..; \
		fi; \
	done
	@echo "✅ Cleanup complete!"

# Deploy contracts (placeholder)
deploy:
	@echo "🚀 Deploy contracts to blockchain"
	@echo "⚠️ This requires proper blockchain setup and configuration"
	@echo "📚 See deployment documentation for details"

# Quick setup for development
setup:
	@echo "⚙️ Setting up development environment..."
	@mkdir -p contracts
	@mkdir -p scripts
	@echo "✅ Development environment ready!"

# List all contracts
list:
	@echo "📋 Available contracts:"
	@for contract in contracts/*/; do \
		if [ -d "$$contract" ]; then \
			echo "  📁 $$(basename $$contract)"; \
		fi; \
	done

# Generate example contracts
examples: generate-cw20 generate-dao generate-nft
	@echo "🎯 Generating example contracts..."
	@$(MAKE) generate-cw20 NAME=rice-token
	@$(MAKE) generate-dao NAME=rice-dao
	@$(MAKE) generate-nft NAME=rice-nfts
	@echo "✅ Example contracts generated!"
