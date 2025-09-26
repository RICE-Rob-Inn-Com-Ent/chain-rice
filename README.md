# 🚀 rice-dev: Unified Nix Development Environment

**Unified Nix dev shells with Bazel integration for multi-language development**

## 🎯 Quick Start

### 1. Install Nix

```bash
# Install Nix (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://nixos.org/nix/install | sh

# Reload shell or run:
source ~/.nix-profile/etc/profile.d/nix.sh
```

### 2. Clone the Project

```bash
git clone <your-repo-url> rice-dev
cd rice-dev
```

### 3. Start Development Mode

```bash
# Enter default Nix shell
nix develop

# Or use Bazel
bazel run //:dev
```

## 🛠️ Available Development Environments

### 🤖 AI & Bot Development
```bash
nix develop .#bot-core              # Minimal Python environment for AI
nix develop .#bot-integration       # Chat platform integrations
nix develop .#bot-julia-models      # Julia for mathematical modeling
nix develop .#bot-finance-reporting # Analytics and reporting
```

### 🔧 Backend Development
```bash
nix develop .#go-backend            # Go with Cosmos/Tendermint
nix develop .#dotnet-bridge         # .NET bridge services
nix develop .#beam-bridge           # Erlang/Elixir bridge
nix develop .#python-fastapi-bridge # Python FastAPI services
nix develop .#jvm-bridge            # Java bridge services
nix develop .#php-bridge            # PHP bridge services
```

### ⛓️ Blockchain & Smart Contracts
```bash
nix develop .#rust-cosmos           # Rust for blockchain development
nix develop .#solidity-evm          # Solidity for EVM-compatible chains
```

### 📱 Frontend Development
```bash
nix develop .#flutter-dart          # Flutter/Dart mobile development
nix develop .#kotlin-android        # Kotlin for Android
nix develop .#swift-ios              # Swift for iOS (macOS only)
nix develop .#angular-frontend      # Angular web applications
nix develop .#next-frontend          # Next.js applications
nix develop .#nuxt-frontend         # Nuxt.js applications
nix develop .#ts-shared             # TypeScript shared libraries
```

### 🚀 DevOps & Infrastructure
```bash
nix develop .#ansible               # Ansible automation
nix develop .#k8s                   # Kubernetes management
nix develop .#terraform             # Infrastructure as Code
nix develop .#bazel-dev             # Bazel development tools
```

## 🔨 Bazel Commands

### Basic Operations
```bash
# Enter default Nix shell
bazel run //:dev

# Build all targets with Nix
bazel run //:build

# Run tests with Nix
bazel run //:test
```

### Toolchain Commands
```bash
# Go toolchain
bazel run //:go_toolchain

# Python toolchain
bazel run //:python_toolchain

# Rust toolchain
bazel run //:rust_toolchain

# Protobuf toolchain
bazel run //:proto_toolchain
```

### Build Specific Targets
```bash
# Build Go backend
bazel run //:nix_build_go

# Build Python services
bazel run //:nix_build_python

# Build Rust contracts
bazel run //:nix_build_rust

# Build Protobuf files
bazel run //:nix_build_proto
```

## 🧪 Testing Integration

```bash
# Run full integration test
./test_nix_integration.sh
```

This script checks:
- ✅ Nix availability
- ✅ flake.nix validity
- ✅ Nix shells functionality
- ✅ Bazel integration
- ✅ Toolchain availability

## 📁 Project Structure

```
rice-dev/
├── flake.nix              # Nix flake with all development environments
├── .bazelrc               # Base Bazel configuration
├── .bazelrc.nix           # Nix-specific Bazel configuration
├── rules/                 # Bazel rules for Nix integration
│   ├── nix.bzl           # Core Nix rules
│   ├── go_toolchain.bzl  # Go toolchain integration
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

## 🎯 Key Benefits

1. **Consistency** - Same dependencies across Nix and Bazel
2. **Isolation** - Each shell has its own dependencies
3. **Reproducibility** - Exact package versions
4. **Speed** - Nix caching + Bazel incremental builds
5. **Flexibility** - Easy to add new environments

## 🔧 Configuration

### .bazelrc.nix
Contains Nix-specific settings for Bazel:
- Export Nix environment variables
- Configure toolchains for different languages
- Integrate with Nix store
- Optimize for Nix environment

### Bazel Rules
- **nix_shell** - Enter Nix development shell
- **nix_build** - Build targets in Nix shell
- **nix_test** - Test in Nix shell
- **nix_toolchain** - Use toolchain from Nix

## 🚨 Troubleshooting

### Nix Issues
```bash
# Clear Nix cache
nix-collect-garbage -d

# Rebuild flake
nix flake update
```

### Bazel Issues
```bash
# Clear Bazel cache
bazel clean --expunge

# Rebuild all targets
bazel build //...
```

### Integration Issues
```bash
# Check .bazelrc.nix
bazel query //... --config=nix

# Test specific shell
nix develop .#shell-name --command bazel build //target
```

## 📚 Additional Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Detailed architecture overview
- [CONTRIBUTING.md](./CONTRIBUTING.md) - Development guidelines
- [test_nix_integration.sh](./test_nix_integration.sh) - Integration testing script

## 🎉 Ready for Development!

Now you can:
- ✅ Use Nix packages in Bazel
- ✅ Have isolated development environments
- ✅ Quickly switch between toolchains
- ✅ Automatically test integration
- ✅ Scale project with new languages/technologies

**Project ready for productive development! 🚀**