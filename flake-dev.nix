{
  description = "Rice-Dev ChainRice Development Environment with Docker and Real Blockchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        chainrice-dev = pkgs.mkShell {
          name = "chainrice-dev";
          
          packages = with pkgs; [
            # Core tools
            git
            curl
            jq
            openssl
            pkg-config
            
            # Node.js for ChainRice frontend
            nodejs_20
            nodePackages.npm
            nodePackages.yarn
            nodePackages.pnpm
            nodePackages.concurrently
            
            # Go for blockchain
            go_1_23
            gopls
            delve
            
            # Rust for smart contracts
            rustc
            cargo
            rust-analyzer
            
            # Blockchain tools
            foundry
            solc
            
            # Docker and containerization
            docker
            docker-compose
            podman
            
            # Development utilities
            htop
            vim
            which
            unzip
            parallel
            
            # Additional blockchain tools
            cosmos-sdk
            tendermint
            wasmd
          ];

          shellHook = ''
            # Environment setup
            export LC_ALL=C.UTF-8
            export LANG=C.UTF-8
            
            # Node.js environment
            export NPM_CONFIG_PREFIX="$PWD/.npm-global"
            mkdir -p "$NPM_CONFIG_PREFIX/bin"
            export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
            
            # Go environment
            export GOPATH="$PWD/.gopath"
            export GOBIN="$GOPATH/bin"
            export PATH="$GOBIN:$PATH"
            
            # Rust environment
            export CARGO_HOME="$PWD/.cargo"
            export RUSTUP_HOME="$PWD/.rustup"
            export PATH="$CARGO_HOME/bin:$PATH"
            
            # Blockchain environment
            export CHAINRICE_HOME="$PWD/.chainrice"
            export CHAINRICE_CHAIN_ID="chainrice-1"
            export CHAINRICE_NODE="tcp://localhost:26657"
            
            # Docker environment
            export DOCKER_BUILDKIT=1
            export COMPOSE_DOCKER_CLI_BUILD=1
            
            # Create directories
            mkdir -p .npm-global .gopath .cargo .rustup .chainrice
            
            # Initialize ChainRice frontend
            if [ -f projects/chain-rice/package.json ]; then
              echo "📦 Installing ChainRice frontend dependencies..."
              cd projects/chain-rice
              npm install --silent || true
              cd ../..
            fi
            
            echo ""
            echo "🌾 CHAINRICE DEVELOPMENT ENVIRONMENT READY!"
            echo "=========================================="
            echo "📦 Node.js: $(node --version)"
            echo "🐹 Go: $(go version)"
            echo "🦀 Rust: $(rustc --version)"
            echo "🐳 Docker: $(docker --version)"
            echo "🔧 Cosmos SDK: Available"
            echo ""
            echo "Available commands:"
            echo "  ./scripts/start-chainrice-full.sh  - Start full ChainRice environment with real blockchain"
            echo "  ./scripts/start-blockchain-real.sh - Start real blockchain node"
            echo "  ./scripts/start-contracts-docker.sh - Start smart contracts with Docker"
            echo ""
          '';
        };

      in {
        devShells = {
          default = chainrice-dev;
          chainrice = chainrice-dev;
        };
      }
    );
}
