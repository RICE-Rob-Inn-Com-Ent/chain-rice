# 🚀 RICE-DEV Monorepo

Unified development environment for the rice-dev project with Nix + Bazel integration.

## 🎯 Quick Start

### 1. Enter Monorepo Development Environment

```bash
# Enter the monorepo shell with all tools
nix develop .#monorepo

# Or use Bazel alias
bazel run //:dev
```

### 2. Start All Services

```bash
# Start all services with hot reload
./scripts/dev-watch.sh

# Or start all services without watch mode
./scripts/start-all.sh

# Or start all services concurrently in one shell (recommended)
./scripts/run-all-concurrently.sh
```

### 3. Build Everything

```bash
# Build all targets
./scripts/build-all.sh

# Or use Bazel directly
bazel run //:build
```

### 4. Test Everything

```bash
# Run all tests
./scripts/test-all.sh

# Or use Bazel directly
bazel run //:test
```

## 🛠️ Available Services

### Frontend Services
- **Next.js**: http://localhost:3000
- **Angular**: http://localhost:4200  
- **Nuxt**: http://localhost:3001

### Backend Services
- **Go Backend**: http://localhost:8080
- **FastAPI**: http://localhost:8000
- **BEAM/Elixir**: http://localhost:4000

### Bot Services
- **Core Bot**: http://localhost:5000
- **Integration Bot**: http://localhost:5001

### Blockchain Services
- **Rust Blockchain**: http://localhost:9000
- **Solidity Contracts**: http://localhost:9001

## 🔧 Development Commands

### Individual Service Development

```bash
# Enter monorepo shell
nix develop .#monorepo

# Build specific service
bazel build //libs/frontend/ts/next/...
bazel build //libs/backend/...
bazel build //bots/core/...

# Run specific service
bazel run //libs/frontend/ts/next:dev
bazel run //libs/backend:dev
bazel run //bots/core:dev

# Test specific service
bazel test //libs/frontend/ts/next/...
bazel test //libs/backend/...
bazel test //bots/core/...
```

### Hot Reload Development

```bash
# Start with hot reload
bazel run //libs/frontend/ts/next:dev --watch
bazel run //libs/backend:dev --watch
bazel run //bots/core:dev --watch
```

## 📦 Available Tools

The monorepo shell includes:

- **Python**: FastAPI, AI libraries, data science tools
- **Go**: Backend development, blockchain tools
- **Node.js**: Frontend frameworks, build tools
- **Rust**: Blockchain contracts, performance tools
- **Java**: JVM bridge development
- **Elixir/Erlang**: BEAM platform development
- **Dart/Flutter**: Mobile development
- **Terraform**: Infrastructure as Code
- **Kubernetes**: Container orchestration
- **Docker**: Containerization
- **Bazel**: Build system
- **Protobuf**: gRPC communication

## 🚀 Environment Features

### Automatic Setup
- All dependencies installed automatically
- Environment variables configured
- Tool paths set up correctly
- Cache directories created

### Hot Reload Support
- File watching enabled
- Automatic rebuilds
- Live service updates
- Development-friendly logging

### Unified Development
- Single shell for all technologies
- Consistent tool versions
- Shared environment variables
- Integrated build system

## 📝 Logs

All service logs are available in the `logs/` directory:

```bash
# Follow all logs
tail -f logs/*.log

# Follow specific service
tail -f logs/nextjs.log
tail -f logs/go-backend.log
tail -f logs/bot-core.log
```

## 🛑 Stopping Services

```bash
# Stop all services (Ctrl+C in terminal)
# Or kill specific services
pkill -f "bazel run"

# Clean up
rm -rf logs/*.pid
```

## 🔍 Troubleshooting

### Common Issues

1. **Nix not installed**: Install Nix first
2. **Permission denied**: Make scripts executable with `chmod +x scripts/*.sh`
3. **Port conflicts**: Check if ports are already in use
4. **Build failures**: Run `bazel clean` and try again

### Debug Commands

```bash
# Check Nix flake
nix flake check

# Validate Bazel configuration
bazel query //...

# Check service status
ps aux | grep bazel

# View build logs
bazel build //... --verbose_failures
```

## 📚 Additional Resources

- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [Bazel Documentation](https://bazel.build/docs)
- [Project Architecture](./ARCHITECTURE.md)
- [Contributing Guide](./CONTRIBUTING.md)
