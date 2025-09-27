# 🏗️ rice-dev Architecture

## Multi-language development environment with Nix and Bazel integration

## Overview

rice-dev is a unified development environment that combines Nix package management with Bazel build system to provide isolated, reproducible development environments for multiple programming languages and frameworks.

## Core Components

### 1. Nix Flake System

- **flake.nix**: Central configuration defining all development environments
- **flake.lock**: Locked dependencies for reproducible builds
- **Development Shells**: Isolated environments for different technologies

### 2. Bazel Integration

- **Custom Rules**: Nix-aware Bazel rules for shell management
- **Toolchain Integration**: Language-specific toolchains from Nix
- **Build System**: Incremental builds with Nix package isolation

### 3. Project Structure

```text
rice-dev/
├── flake.nix              # Nix flake configuration
├── .bazelrc               # Base Bazel configuration
├── .bazelrc.nix           # Nix-specific Bazel settings
├── rules/                 # Bazel rules for Nix integration
│   ├── nix.bzl           # Core Nix rules
│   ├── go_toolchain.bzl   # Go toolchain integration
│   ├── python_toolchain.bzl # Python toolchain integration
│   ├── rust_toolchain.bzl # Rust toolchain integration
│   ├── proto_toolchain.bzl # Protobuf toolchain integration
│   └── BUILD.bazel        # Rules BUILD file
├── libs/                  # Shared libraries
│   ├── backend/          # Backend services
│   ├── frontend/         # Frontend applications
│   ├── contract/         # Smart contracts
│   └── proto/            # Protobuf definitions
├── bots/                 # AI bots and models
└── projects/             # Main projects
```

## Development Environments

### AI & Bot Development

- **bots-core**: Python environment for AI
- **bots-integration**: External AI integrations
- **bots-models**: Julia for heavy mathematical models
- **bots-reports**: Analytics and reporting

### Backend Development

- **go-backend**: Go with CosmosSDK/Tendermint
- **dotnet-bridge**: .NET bridge service
- **beam-bridge**: Erlang/Elixir bridge service
- **python-bridge**: FastAPI bridge service
- **jvm-bridge**: Java bridge service
- **php-bridge**: PHP bridge service

### Blockchain & Smart Contracts

- **rust-cosmos**: Rust (CosmWasm) for blockchain smart contracts
- **solidity-evm**: Solidity for EVM-compatible chains

### Frontend Development

- **dart-flutter**: Multiplatform
- **kotlin**: Android
- **swift**: iOS/macOS
- **ts-angular**: Angular web
- **ts-next**: Next.js web
- **ts-nuxt**: Nuxt.js web
- **ts-shared**: TypeScript shared libraries

### DevOps & Infrastructure

- **ansible**: Ansible automation
- **k8s**: Kubernetes management
- **terraform**: Infrastructure as Code
- **bazel-dev**: Bazel development tools

## Integration Architecture

### Nix-Bazel Bridge

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nix Flake     │    │   Bazel Rules   │    │   Development   │
│                 │    │                 │    │   Environment   │
│ • Shells        │◄──►│ • nix_shell     │◄──►│ • Isolated      │
│ • Packages      │    │ • nix_build     │    │ • Reproducible  │
│ • Dependencies  │    │ • nix_test      │    │ • Consistent    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Toolchain Flow

```text
Developer Command → Bazel Rule → Nix Shell → Tool Execution
     ↓                ↓           ↓            ↓
bazel run //:go → nix_shell → nix develop → go build
```

## Key Features

### 1. Isolation

- Each development environment is completely isolated
- No dependency conflicts between projects
- Clean, reproducible builds

### 2. Reproducibility

- Locked dependencies via flake.lock
- Deterministic builds across machines
- Version consistency

### 3. Performance

- Nix binary cache for fast package installation
- Bazel incremental builds
- Parallel execution where possible

### 4. Flexibility

- Easy to add new development environments
- Language-agnostic approach
- Cross-platform support

## Configuration Layers

### Layer 1: Nix Flake

- Defines available development environments
- Manages package dependencies
- Sets up environment variables

### Layer 2: Bazel Rules

- Provides Bazel integration with Nix
- Manages build targets
- Handles toolchain selection

### Layer 3: Development Shells

- Isolated runtime environments
- Language-specific tooling
- Development tools and utilities

## Benefits

1. **Consistency**: Same dependencies across Nix and Bazel
2. **Isolation**: Each shell has its own dependencies
3. **Reproducibility**: Exact package versions
4. **Speed**: Nix caching + Bazel incremental builds
5. **Flexibility**: Easy to add new environments

## Roadmap

Detailed project development plan can be found in [TODO.md](./TODO.md) - there are described all 12 development phases, from basic architecture to global scaling.

### Key Directions

- **Security**: Zero Trust Architecture, GDPR compliance, SOC 2
- **Blockchain**: Multi-chain support, Zero Knowledge Proofs, DeFi integration  
- **Bridges**: Legacy systems, Cloud providers, Development tools
- **Frontend**: Universal component library for all frameworks
- **AI/ML**: MLOps pipeline, LLM integration, automated code generation
