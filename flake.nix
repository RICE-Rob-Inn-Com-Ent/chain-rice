{
  description = "rice-dev: Unified Nix dev shells (2025)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells = {
          # =============================================================================
          # AI & BOT DEVELOPMENT
          # =============================================================================
          bot-core = import ./bots/core/core.nix { inherit pkgs; };                    # AI models (PyTorch, TensorFlow, JAX, CUDA)
          bot-integration = import ./bots/integration/intergration.nix { inherit pkgs; }; # Bot APIs/SDKs/middleware
          bot-julia-models = import ./bots/models/models.nix { inherit pkgs; };         # Julia simulations/FinTech
          bot-finance-reporting = import ./bots/reports/report.nix { inherit pkgs; };   # Analytics/reporting/visualization

          # =============================================================================
          # BACKEND DEVELOPMENT
          # =============================================================================
          go-backend = import ./libs/backend/backend.nix { inherit pkgs; };            # Go + Cosmos SDK + gRPC

          # =============================================================================
          # CONNECTION BRIDGES
          # =============================================================================
          dotnet-bridge = import ./libs/connection/.NET/.net.nix { inherit pkgs; };    # .NET to Go backend
          beam-bridge = import ./libs/connection/BEAM/beam.nix { inherit pkgs; };      # Elixir/Erlang to Go backend
          python-fastapi-bridge = import ./libs/connection/FastAPI/fastapi.nix { inherit pkgs; }; # Python FastAPI bridges
          jvm-bridge = import ./libs/connection/JVM/jvm.nix { inherit pkgs; };        # Java/Kotlin to Go backend
          php-bridge = import ./libs/connection/PHP/php.nix { inherit pkgs; };         # PHP to Go backend

          # =============================================================================
          # BLOCKCHAIN & SMART CONTRACTS
          # =============================================================================
          rust-cosmos = import ./libs/contract/rust/rust.nix { inherit pkgs; };        # Rust + Cosmos SDK
          solidity-evm = import ./libs/contract/solidity/solidity.nix { inherit pkgs; }; # Solidity + EVM chains

          # =============================================================================
          # FRONTEND DEVELOPMENT
          # =============================================================================
          flutter-dart = import ./libs/frontend/dart/dart.nix { inherit pkgs; };      # Flutter/Dart mobile
          kotlin-android = import ./libs/frontend/kotlin/kotlin.nix { inherit pkgs; }; # Kotlin Android
          swift-ios = import ./libs/frontend/swift/swift.nix { inherit pkgs; };        # Swift iOS/macOS
          angular-frontend = import ./libs/frontend/ts/angular/angular.nix { inherit pkgs; }; # Angular + TypeScript
          next-frontend = import ./libs/frontend/ts/next/next.nix { inherit pkgs; };   # Next.js + React + TypeScript
          nuxt-frontend = import ./libs/frontend/ts/nuxt/nuxt.nix { inherit pkgs; };   # Nuxt + Vue + TypeScript
          ts-shared = import ./libs/frontend/ts/shared/shared.nix { inherit pkgs; };   # Shared TypeScript tooling

          # =============================================================================
          # DEVELOPMENT TOOLS
          # =============================================================================
          proto-tools = import ./libs/proto/proto.nix { inherit pkgs; };              # Protobuf multi-language compilation

          # =============================================================================
          # DEVOPS & INFRASTRUCTURE
          # =============================================================================
          ansible = import ./tools/ansible/ansible.nix { inherit pkgs; };              # Ansible automation
          k8s = import ./tools/k8s/k8s.nix { inherit pkgs; };                          # Kubernetes management
          terraform = import ./tools/terraform/terraform.nix { inherit pkgs; };        # Infrastructure as Code

          # =============================================================================
          # DEFAULT SHELL
          # =============================================================================
          default = pkgs.mkShell { packages = [ pkgs.git ]; };
        };
      }
    );
}
