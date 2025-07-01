# Meowtopia Smart Contracts Makefile

# Contract directories
CONTRACTS := mwt_token mwt_cat_nft mwt_dao mwt_groups mwt_ibc_bridge

# Build all contracts
build:
	@for contract in $(CONTRACTS); do \
		echo "Building $$contract..."; \
		cd $$contract && cargo build --release --target wasm32-unknown-unknown; \
		cd ..; \
	done

# Generate schemas for all contracts
schema:
	@for contract in $(CONTRACTS); do \
		echo "Generating schema for $$contract..."; \
		cd $$contract && cargo schema; \
		cd ..; \
	done

# Optimize WASM files
optimize:
	@for contract in $(CONTRACTS); do \
		echo "Optimizing $$contract..."; \
		docker run --rm -v "$(PWD)/$$contract":/code \
			--mount type=volume,source="$(notdir $(PWD))_cache",target=/code/target \
			--mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
			cosmwasm/rust-optimizer:0.12.13; \
	done

# Test all contracts
test:
	@for contract in $(CONTRACTS); do \
		echo "Testing $$contract..."; \
		cd $$contract && cargo test; \
		cd ..; \
	done

# Deploy contracts to local chain-rice node
deploy-local:
	@echo "Deploying contracts to local chain-rice node..."
	./scripts/deploy-local.sh

# Deploy contracts to testnet
deploy-testnet:
	@echo "Deploying contracts to testnet..."
	./scripts/deploy-testnet.sh

# Clean build artifacts
clean:
	@for contract in $(CONTRACTS); do \
		echo "Cleaning $$contract..."; \
		cd $$contract && cargo clean; \
		cd ..; \
	done

# Format code
fmt:
	@for contract in $(CONTRACTS); do \
		echo "Formatting $$contract..."; \
		cd $$contract && cargo fmt; \
		cd ..; \
	done

# Run clippy linter
clippy:
	@for contract in $(CONTRACTS); do \
		echo "Running clippy on $$contract..."; \
		cd $$contract && cargo clippy -- -D warnings; \
		cd ..; \
	done

# Generate documentation
doc:
	@for contract in $(CONTRACTS); do \
		echo "Generating docs for $$contract..."; \
		cd $$contract && cargo doc --no-deps; \
		cd ..; \
	done

.PHONY: build schema optimize test deploy-local deploy-testnet clean fmt clippy doc