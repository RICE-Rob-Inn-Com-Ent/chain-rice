# 🏗️ Rice-Mono Architecture

## Enterprise polyglot monorepo with Bazel build system

---

## Overview

Rice-mono is an enterprise-grade monorepo that combines multiple programming languages, frameworks, and technologies using Bazel as the unified build system. It provides a complete infrastructure for building blockchain applications, AI bots, and multi-platform frontends.

---

## Core Technologies

### Build System

- **Bazel with Bzlmod** - Modern dependency management and build system
- **Production-grade configuration** - Optimized for multi-language builds
- **Incremental builds** - Fast iteration cycles
- **Remote caching support** - Distributed build acceleration

### Container Orchestration

- **Docker & Docker Compose** - Local development
- **Kubernetes with Helm** - Production deployment
- **Multi-stage builds** - Optimized container images

### Infrastructure as Code

- **Terraform** - Cloud infrastructure management
- **Ansible** - Configuration management
- **Modular design** - Reusable infrastructure components

---

## Project Structure

```text
rice-mono/
├── backend/                 # Backend services
│   ├── contract/
│   │   ├── rust/          # Rust smart contracts (CosmWasm)
│   │   └── solidity/      # Solidity contracts + Hardhat + ZK proofs
│   ├── db/                # Database schemas & migrations
│   └── token/             # Token services
│
├── bots/                   # Python AI automation
│   ├── core/              # Core bot logic
│   ├── integration/       # AI integrations (OpenAI, HuggingFace)
│   ├── pyproject.toml     # Poetry dependencies
│   └── BUILD.bazel        # Bazel build rules
│
├── frontend/              # Multi-platform frontends
│   ├── android/          # Kotlin Android app
│   ├── dart/             # Flutter cross-platform
│   ├── ios/              # Swift iOS app
│   └── node/             # JavaScript/TypeScript
│       ├── angular/      # Angular framework
│       ├── next/         # Next.js (React)
│       ├── nuxt/         # Nuxt (Vue)
│       ├── svelte/       # Svelte framework
│       └── shared/       # Shared libraries
│
├── proto/                 # Protocol Buffers (424+ files)
│   ├── asset/            # Asset-related protos
│   ├── auth/             # Authentication
│   ├── bot/              # Bot services
│   ├── common/           # Shared definitions
│   ├── config/           # Configuration
│   ├── connection/       # Connection management
│   ├── content/          # Content services
│   ├── game/             # Game-related
│   ├── store/            # Store services
│   └── token/            # Token services
│
├── dev/                   # DevOps & Infrastructure
│   ├── ansible/          # Ansible playbooks
│   ├── k8s/              # Kubernetes Helm charts
│   └── terraform/        # Terraform modules
│
├── .config/               # Configuration files
│   ├── .bazelrc          # Bazel configuration
│   ├── .yamllint         # YAML linting
│   ├── taplo.toml        # TOML formatting
│   └── sonar-project.properties
│
├── helpers/               # Developer documentation
│   ├── BAZEL.md          # Build system guide
│   ├── PYTHON.md         # Python development
│   ├── RUST.md           # Rust development
│   └── ... (15 total)
│
├── rules/                 # Custom Bazel rules
│   └── *.bzl             # Build rule definitions
│
└── scripts/               # Utility scripts
    └── workspace_status.sh
```

---

## Technology Stack

### Backend Technologies

#### Rust (Backend/Contracts)

- **CosmWasm** - Cosmos blockchain smart contracts
- **High performance** - System-level programming
- **Type safety** - Compile-time guarantees

#### Solidity (EVM Contracts)

- **Hardhat** - Development framework
- **Zero-Knowledge Proofs** - Circom circuits with snarkjs
- **EVM compatible** - Ethereum and compatible chains

### AI & Automation

#### Python Bots

- **Poetry** - Dependency management
- **FastAPI** - High-performance API framework
- **OpenAI Integration** - GPT models
- **HuggingFace** - ML model hub
- **pytest** - Testing framework

### Frontend Applications

#### Web Frameworks

- **Angular** - Enterprise TypeScript framework
- **Next.js** - React framework with SSR
- **Nuxt** - Vue framework with SSR
- **Svelte** - Compiler-based framework
- **Shared Libraries** - Common TypeScript utilities

#### Mobile Platforms

- **Kotlin** - Android native with Jetpack Compose
- **Swift** - iOS native with SwiftUI
- **Flutter/Dart** - Cross-platform mobile

### Infrastructure

#### DevOps Tools

- **Docker** - Containerization
- **Kubernetes** - Container orchestration
- **Helm** - Kubernetes package manager
- **Terraform** - Infrastructure as Code
- **Ansible** - Configuration management

#### Databases

- **PostgreSQL** - Primary database
- **Redis** - Caching layer

#### Protocols

- **gRPC** - RPC framework
- **Protocol Buffers** - Serialization (424+ proto files)

---

## Build System Architecture

### Bazel Configuration

```text
┌─────────────────────────────────────────────────┐
│              .config/.bazelrc                   │
│  • Performance optimization (caching, workers)  │
│  • Multi-language support                       │
│  • Build profiles (debug, release, ci)          │
│  • Platform configs (Linux, macOS, Windows)     │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌────────┐   ┌────────┐   ┌────────┐
   │ Python │   │  Rust  │   │  Node  │
   │ rules  │   │ rules  │   │ rules  │
   └────────┘   └────────┘   └────────┘
```

### Build Profiles

- **fastbuild** - Fast local development
- **debug** - Debug builds with symbols
- **release** - Production optimized builds
- **ci** - CI/CD optimized builds
- **clippy** - Rust linting
- **android** - Android builds
- **ios** - iOS builds

### Key Features

1. **Disk Caching** - ~/.cache/bazel/ for fast rebuilds
2. **Persistent Workers** - Java & TypeScript compilation
3. **Parallel Execution** - 75% CPU/RAM utilization
4. **Incremental Builds** - Only rebuild changed targets
5. **Remote Caching** - Ready for distributed builds

---

## Service Architecture

### Backend Service Architecture

```text
┌──────────────────────────────────────────────┐
│           Client Applications                │
└────────────┬─────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────┐
│           API Gateway / Ingress              │
└────────────┬─────────────────────────────────┘
             │
    ┌────────┼────────┐
    ▼        ▼        ▼
┌────────┐ ┌────────┐ ┌────────┐
│  Rust  │ │Solidity│ │ Python │
│Services│ │Contract│ │  Bots  │
└────┬───┘ └────┬───┘ └────┬───┘
     │          │          │
     └──────────┼──────────┘
                ▼
     ┌──────────────────────┐
     │    PostgreSQL        │
     │    Redis Cache       │
     └──────────────────────┘
```

### gRPC Communication

All services communicate via gRPC using Protocol Buffers:

- **Type Safety** - Strongly-typed APIs
- **Performance** - Efficient binary serialization
- **Multi-Language** - Code generation for all languages
- **Versioning** - Clear API versioning (v1, v2)

---

## Deployment Architecture

### Development

```text
Developer Machine
├── Docker Compose
│   ├── Backend services
│   ├── Bots
│   ├── PostgreSQL
│   ├── Redis
│   └── NGINX
└── Local testing
```

### Production (Kubernetes)

```text
┌─────────────────────────────────────────┐
│         Kubernetes Cluster              │
│                                         │
│  ┌──────────────┐  ┌──────────────┐   │
│  │   Ingress    │  │   Services   │   │
│  │   (NGINX)    │  │              │   │
│  └──────┬───────┘  └──────────────┘   │
│         │                              │
│  ┌──────┴────────┐                    │
│  │  Deployments  │                    │
│  │  • Backend    │                    │
│  │  • Bots       │                    │
│  │  • Frontend   │                    │
│  └───────────────┘                    │
│                                         │
│  ┌───────────────┐                    │
│  │  StatefulSets │                    │
│  │  • PostgreSQL │                    │
│  │  • Redis      │                    │
│  └───────────────┘                    │
└─────────────────────────────────────────┘
```

---

## Development Workflow

### 1. Local Development

```bash
# Build with Bazel
bazel build //...

# Run with Docker Compose
docker-compose up

# Run tests
bazel test //...
```

### 2. Testing

```bash
# Python tests
cd bots/ && poetry run pytest

# Rust tests
cd backend/contract/rust/ && cargo test

# Node.js tests
cd frontend/node/ && npm test

# Solidity tests
cd backend/contract/solidity/ && npx hardhat test
```

### 3. Deployment

```bash
# Build containers
docker build -t rice/backend backend/
docker build -t rice/bots bots/

# Deploy to Kubernetes
helm install rice-mono dev/k8s/ -f values.yaml

# Infrastructure
cd dev/terraform/ && terraform apply
```

---

## Key Design Principles

### 1. Isolation

- Each service is independently buildable
- Clear boundaries between components
- Minimal shared dependencies

### 2. Reproducibility

- Bazel ensures deterministic builds
- Locked dependencies (poetry.lock, Cargo.lock, package-lock.json)
- Version-controlled configurations

### 3. Performance

- Incremental builds with Bazel
- Disk caching for fast iterations
- Parallel test execution
- Optimized container images

### 4. Flexibility

- Multiple language support
- Framework-agnostic approach
- Cloud-provider agnostic
- Easy to add new services

### 5. Security

- Sandboxed builds
- Dependency scanning
- No secrets in code
- Kubernetes secrets management

---

## Integration Points

### Protocol Buffer Integration

- **Central contract** - 424+ proto files define all APIs
- **Code generation** - Automatic client/server code
- **Versioning** - Backward-compatible changes

### Build System Integration

- **Bazel** - Unified build for all languages
- **Hermetic builds** - Reproducible across machines
- **Caching** - Local and remote caching support

### Container Integration

- **Docker** - Development containers
- **Kubernetes** - Production orchestration
- **Helm** - Application packaging

### Infrastructure Integration

- **Terraform** - Cloud resources
- **Ansible** - Configuration management
- **GitOps** - Declarative infrastructure

---

## Scalability

### Horizontal Scaling

- Kubernetes autoscaling
- Load balancing via Ingress
- Stateless services
- Database connection pooling

### Vertical Scaling

- Resource limits in K8s
- Optimized memory usage
- Efficient algorithms
- Performance profiling

### Build Scaling

- Remote caching
- Distributed builds
- Parallel compilation
- Incremental builds

---

## Monitoring & Observability

### Logging

- Structured logging
- Centralized log aggregation
- Log levels (debug, info, warn, error)

### Metrics

- Prometheus metrics
- Grafana dashboards
- Custom business metrics

### Tracing

- Distributed tracing
- Request ID propagation
- Performance profiling

---

## Security Architecture

### Build Security

- Sandboxed builds
- No network access during build
- Reproducible builds
- Dependency verification

### Runtime Security

- Kubernetes security contexts
- Network policies
- RBAC for services
- Secrets management

### Code Security

- Dependency scanning
- Static analysis
- Security linting
- Automated updates

---

## Future Enhancements

- Remote execution for Bazel
- Multi-cloud deployment
- Service mesh (Istio)
- Advanced monitoring
- CI/CD automation
- Performance optimization

---

**Last Updated**: October 2025
**Architecture Version**: 2.0
