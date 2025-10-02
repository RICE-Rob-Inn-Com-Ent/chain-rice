# Rice-Dev Monorepo Development Environment

A comprehensive unified development environment for the Rice-Dev monorepo, supporting multiple languages, frameworks, and services with hot reload and concurrent execution.

## 🚀 Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) installed
- Git
- Basic understanding of the monorepo structure

### Enter Development Environment

```bash
# Enter the unified monorepo development environment
nix develop

# Or use the specific environment
nix develop .#monorepo
```

### Start All Services

```bash
# Start all services with hot reload
./scripts/dev-services.sh

# Start all services without hot reload
./scripts/start-all.sh

# Start with hot reload only
./scripts/dev-watch.sh
```

## 🏗️ Architecture

The monorepo contains the following components:

### 🤖 AI & Bot Development
- **Python Bot Core** (`bots/core/`) - Main AI bot with PyTorch, Transformers, FastAPI
- **Julia Models** (`bots/models/`) - Machine learning models in Julia
- **Bot Integration** (`bots/integration/`) - Integration services

### ⚙️ Backend Services
- **Go Backend** (`libs/backend/`) - Cosmos SDK blockchain backend
- **Rust Contracts** (`libs/contract/rust/`) - Smart contracts
- **Solidity Contracts** (`libs/contract/solidity/`) - EVM smart contracts

### 🔗 Connection Bridges
- **FastAPI Bridge** (`libs/connection/FastAPI/`) - Python web service
- **JVM Bridge** (`libs/connection/JVM/`) - Java/Spring Boot service
- **.NET Bridge** (`libs/connection/.NET/`) - C# service
- **PHP Bridge** (`libs/connection/PHP/`) - PHP service
- **BEAM Bridge** (`libs/connection/BEAM/`) - Elixir/Erlang service

### 🎨 Frontend Applications
- **TypeScript Frontend** (`libs/frontend/ts/`) - Angular, Next.js, Nuxt, Svelte
- **Flutter Frontend** (`libs/frontend/dart/`) - Mobile/web app
- **Kotlin Frontend** (`libs/frontend/kotlin/`) - Android app
- **Swift Frontend** (`libs/frontend/swift/`) - iOS app

### 🛠️ DevOps & Infrastructure
- **Terraform** (`tools/terraform/`) - Infrastructure as code
- **Kubernetes** (`tools/k8s/`) - Container orchestration
- **Ansible** (`tools/ansible/`) - Configuration management

## 📦 Package Management

The environment automatically initializes dependencies for all package managers:

- **Python**: Poetry + pip
- **Go**: Go modules
- **Node.js**: npm, yarn, pnpm
- **Rust**: Cargo
- **Java**: Maven
- **PHP**: Composer
- **.NET**: NuGet
- **Julia**: Pkg
- **Dart/Flutter**: pub
- **Kotlin**: Gradle

## 🔧 Available Tools

### Core Development Tools
- **Bazel** - Build system
- **Docker** - Containerization
- **Git** - Version control
- **Protobuf** - Protocol buffers
- **gRPC** - RPC framework

### Language-Specific Tools
- **Python**: black, ruff, pytest, jupyter
- **Go**: gopls, delve, golangci-lint
- **Rust**: rust-analyzer, cargo
- **Java**: Maven, Gradle
- **Node.js**: ESLint, Prettier, TypeScript
- **PHP**: PHPUnit, PHP CS Fixer
- **.NET**: dotnet CLI
- **Julia**: Julia REPL, IJulia
- **Dart/Flutter**: flutter CLI, dart CLI

### DevOps Tools
- **Terraform** - Infrastructure
- **Kubernetes** - kubectl, helm, kustomize
- **Ansible** - Configuration management
- **Docker** - Container management
- **Cloud CLIs** - AWS, GCP, Azure

## 🌐 Service Ports

| Service | Port | Description |
|---------|------|-------------|
| Bot Core API | 8000 | Main AI bot service |
| FastAPI Connection | 8001 | Python web service |
| Go Backend | 8080 | Blockchain backend |
| JVM Connection | 8081 | Java service |
| .NET Connection | 8082 | C# service |
| PHP Connection | 8083 | PHP service |
| Angular Frontend | 4200 | Angular app |
| Next.js Frontend | 3000 | React app |
| Nuxt Frontend | 3001 | Vue app |
| Svelte Frontend | 3002 | Svelte app |
| Flutter Frontend | 3003 | Flutter web |
| Julia Models | 8004 | ML models |
| Rust Contracts | 8005 | Smart contracts |
| Kafka | 9092 | Message broker |
| Redis | 6379 | Cache/database |
| PostgreSQL | 5432 | Database |

## 🔥 Hot Reload

The development environment supports hot reload for:

- **Python**: uvicorn --reload
- **Go**: air (if installed)
- **Rust**: cargo watch
- **Node.js**: nodemon
- **TypeScript**: ts-node --watch
- **Flutter**: flutter run --hot

## 🚀 Development Commands

### Bazel Commands
```bash
# Build all targets
bazel build //...

# Test all targets
bazel test //...

# Run specific target
bazel run //path/to:target

# Clean build cache
bazel clean --expunge
```

### Service Management
```bash
# Start all services
./scripts/start-all.sh

# Start with hot reload
./scripts/dev-services.sh

# Start hot reload only
./scripts/dev-watch.sh
```

### Package Management
```bash
# Python
poetry install
pip install -r requirements.txt

# Go
go mod download
go mod tidy

# Node.js
npm install
yarn install
pnpm install

# Rust
cargo build
cargo test

# Java
mvn clean install
mvn dependency:resolve

# PHP
composer install
composer update

# .NET
dotnet restore
dotnet build

# Julia
julia --project=. -e "using Pkg; Pkg.instantiate()"

# Flutter
flutter pub get
flutter pub upgrade
```

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**: Check if ports are already in use
2. **Permission issues**: Ensure scripts are executable (`chmod +x`)
3. **Missing dependencies**: Run `nix develop` to enter the environment
4. **CUDA issues**: Ensure NVIDIA drivers are installed

### Environment Variables

Key environment variables set by the Nix environment:

- `PYTHONNOUSERSITE=1` - Prevents user site packages
- `GOPATH` - Go workspace path
- `JAVA_HOME` - Java installation path
- `CARGO_HOME` - Rust cargo cache
- `COMPOSER_HOME` - PHP Composer cache
- `PUB_CACHE` - Dart/Flutter package cache

### Logs

Service logs are available in `/tmp/`:
- `/tmp/*.log` - Service output logs
- `/tmp/*.pid` - Process ID files

## 📚 Additional Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Bazel Documentation](https://bazel.build/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `nix develop`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.