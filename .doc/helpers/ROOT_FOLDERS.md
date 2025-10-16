# 📁 Root Folders Guide

Complete reference for all directories in the repository root

---

## 📋 Table of Contents

- [Application Folders](#application-folders)
- [Infrastructure & DevOps](#infrastructure--devops)
- [Documentation & Schema](#documentation--schema)
- [Quick Navigation](#quick-navigation)

---

## Application Folders

### `.backend/`

**Contains**: Smart contracts, blockchain services, and backend infrastructure
**Languages**: Rust, Solidity, Go

**Structure**:

```text
.backend/
├── contract/
│   ├── rust/          # CosmWasm smart contracts (Cosmos SDK)
│   └── solidity/      # Ethereum smart contracts (Hardhat)
├── db/                # Database service (Go)
└── token/             # Token chain service (Cosmos SDK)
```

**Key Technologies**:

- **Rust Contracts**: CosmWasm for Cosmos blockchain
- **Solidity Contracts**: Hardhat framework for Ethereum
- **Database**: Go-based database service
- **Token Chain**: Custom Cosmos SDK blockchain

**Key Files**:

- Rust: `Cargo.toml`, `src/lib.rs`
- Solidity: `package.json`, `hardhat.config.js`, `contracts/*.sol`
- Go: `go.mod`, `go.work`, `cmd/`

**Documentation**: See project-specific READMEs in subdirectories

---

### `.frontend/`

**Contains**: All user-facing applications (web and mobile)
**Languages**: TypeScript, Dart, Kotlin, Swift

**Structure**:

```text
.frontend/
├── web/               # Web frameworks
│   ├── angular/       # Angular libs
│   ├── next/          # Next.js libs
│   ├── nuxt/          # Nuxt.js libs
│   └── svelte/        # Svelte libs
├── android/           # Kotlin/Android native app
├── ios/               # Swift/iOS native app
└── flutter/           # Flutter cross-platform app
```

**Key Technologies**:

- **Web**: Angular, Next.js, Nuxt.js, Svelte (all TypeScript-based)
- **Android**: Kotlin with Gradle
- **iOS**: Swift with Swift Package Manager
- **Cross-platform**: Flutter/Dart

**Key Files**:

- Web: `package.json`, `tsconfig.json`, framework-specific configs
- Flutter: `pubspec.yaml`, `analysis_options.yaml`
- iOS: `Package.swift`
- Android: `gradle.properties`, `gradlew`

**Documentation**: See framework-specific documentation in subdirectories

---

### `.bot/`

**Contains**: Python automation, AI integrations, and bot services
**Language**: Python 3.11+

**Structure**:

```text
.bot/
├── core/              # Core bot logic and utilities
│   ├── main.py
│   └── test_*.py      # Core tests
├── integration/       # External service integrations
│   ├── openai.py      # OpenAI integration
│   ├── huggingface.py # HuggingFace integration
│   └── test_*.py      # Integration tests
├── pyproject.toml     # Poetry dependencies
└── poetry.lock        # Dependency lock file
```

**Key Technologies**:

- **Package Manager**: Poetry
- **Testing**: pytest
- **Linting**: Ruff
- **AI Integrations**: OpenAI, HuggingFace

**Key Files**:

- `pyproject.toml` - Python dependencies and project metadata
- `poetry.lock` - Lock file for reproducible builds
- `ruff.toml` - Python linter configuration
- `pytest.ini` - Testing configuration
- `Dockerfile` - Container image definition

**Documentation**: Check inline docstrings and test files

---

## Infrastructure & DevOps

### `.dev/`

**Contains**: Infrastructure as Code (IaC) and DevOps tooling
**Languages**: HCL (Terraform), YAML (Kubernetes/Ansible)

**Structure**:

```text
.dev/
├── terraform/         # Cloud infrastructure
│   ├── main.tf
│   ├── modules/       # Reusable Terraform modules
│   │   ├── calc/
│   │   ├── ci/
│   │   ├── db/
│   │   ├── job/
│   │   ├── secrets/
│   │   └── trigger/
│   └── terraform.lock.hcl
├── k8s/               # Kubernetes manifests & Helm charts
│   ├── Chart.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── namespace.yaml
│       ├── argocd-application.yaml
│       └── argocd-project.yaml
└── ansible/           # Configuration management
    └── requirements.yml
```

**Key Technologies**:

- **Infrastructure**: Terraform (AWS, GCP, Azure)
- **Orchestration**: Kubernetes + Helm
- **GitOps**: ArgoCD
- **Config Management**: Ansible

**Key Files**:

- Terraform: `main.tf`, `variables.tf`, `outputs.tf`, `terraform.lock.hcl`
- Kubernetes: `Chart.yaml`, YAML manifests in `templates/`
- Ansible: `requirements.yml`

**Documentation**: See Terraform module READMEs and Helm chart documentation

---

### `.devcontainer/`

**Contains**: Docker-based development environment configuration
**Languages**: Dockerfile, YAML, Shell

**Structure**:

```text
.devcontainer/
├── Dockerfile             # Multi-language dev container image
├── docker-compose.yml     # All development services
├── devcontainer.json      # VS Code dev container config
└── README.md              # Setup and usage guide
```

**Services Included**:

- **Databases**: PostgreSQL, MongoDB
- **Caching**: Redis
- **Message Queues**: Kafka, RabbitMQ
- **Storage**: MinIO (S3-compatible)
- **Monitoring**: Prometheus, Grafana
- **Search**: Elasticsearch
- **Reverse Proxy**: Traefik

**Key Technologies**:

- **Container Runtime**: Docker Compose
- **IDE Integration**: VS Code Dev Containers
- **Multi-language Support**: Python, Node.js, Go, Rust, and more

**Key Files**:

- `Dockerfile` - Development container image
- `docker-compose.yml` - Service orchestration
- `devcontainer.json` - VS Code integration
- `README.md` - Comprehensive setup guide

**Documentation**: See `.devcontainer/README.md`

---

### `.github/`

**Contains**: GitHub Actions workflows and repository templates
**Language**: YAML

**Structure**:

```text
.github/
├── workflows/             # CI/CD pipelines
│   ├── ci-build.yml       # Build verification
│   ├── ci-lint.yml        # Code quality checks
│   ├── ci-test.yml        # Test execution
│   ├── cd-release.yml     # Release automation
│   ├── cd-sync-subrepos.yml  # Monorepo sync
│   ├── sec-audit.yml      # Security audits
│   ├── sec-codeql.yml     # Code security analysis
│   └── meta-stale.yml     # Stale issue management
├── issue_template/        # Issue templates
│   ├── bug-report.yml
│   ├── feature-request.yml
│   ├── question.yml
│   └── config.yml
├── PULL_REQUEST_TEMPLATE.md
├── CODEOWNERS             # Code ownership rules
└── FUNDING.yml            # Sponsorship info
```

**Key Workflows**:

- **CI**: Build, lint, test automation
- **CD**: Automated releases and deployments
- **Security**: CodeQL analysis, dependency audits
- **Maintenance**: Stale issue cleanup

**Key Files**:

- `CODEOWNERS` - Define code review responsibilities
- `FUNDING.yml` - Set up project sponsorship
- Workflow files - Automated CI/CD pipelines

**Documentation**: See individual workflow files for details

---

## Documentation & Schema

### `.doc/`

**Contains**: Official project documentation
**Format**: Markdown, JSON, YAML

**Structure**:

```text
.doc/
├── docs/                  # Core documentation
│   ├── README.md          # Project overview
│   ├── ARCHITECTURE.md    # System design
│   ├── CHANGELOG.md       # Version history
│   ├── CONTRIBUTING.md    # Contribution guide
│   ├── SECURITY.md        # Security policy
│   ├── LICENSE.md         # Apache 2.0 license
│   ├── CODE_OF_CONDUCT.md # Community guidelines
│   └── TODO.md            # Project roadmap
├── helpers/               # Developer guides
│   ├── ROOT_FILES.md      # Root files documentation
│   └── ROOT_FOLDERS.md    # Root folders documentation (this file)
├── api/                   # API documentation
│   ├── ai.json
│   ├── db.json
│   └── token.json
├── openapi.json           # OpenAPI specification
├── mkdocs.yml             # Documentation site config
└── index.tpl              # Documentation template
```

**Key Technologies**:

- **Documentation**: Markdown
- **API Specs**: JSON, OpenAPI
- **Site Generator**: MkDocs

**Key Files**:

- `docs/*.md` - Core project documentation
- `helpers/*.md` - Developer reference guides
- `api/*.json` - API documentation
- `mkdocs.yml` - Documentation site configuration

**Documentation**: Self-documented structure

---

### `.schema/`

**Contains**: Protocol Buffer definitions for service contracts
**Language**: Protocol Buffers (proto3)

**Structure**:

```text
.schema/
├── asset/         # 135 proto files - Asset definitions
├── auth/          # 11 proto files - Authentication
├── bot/           # 16 proto files - Bot services
├── common/        # 20 proto files - Common types
├── config/        # 24 proto files - Configuration
├── connection/    # 47 proto files - Connection management
├── content/       # 41 proto files - Content types
├── game/          # 100 proto files - Game logic
├── store/         # 24 proto files - Store services
└── token/         # 310 proto files - Token chain definitions
    └── third_party/  # External proto dependencies
```

**Key Technologies**:

- **Protocol Buffers**: proto3 syntax
- **gRPC**: Service definitions
- **Third-party Deps**: Google APIs, IBC, Cosmos SDK

**Key Files**:

- `BUILD.bazel` - Bazel build configuration
- `*.proto` - Protocol Buffer definitions
- `*.yaml` - Proto generation configs

**Total Files**: 728+ proto files across all domains

**Documentation**: See proto file comments and generated documentation

---

## Quick Navigation

### 📊 Folder Summary

| Folder           | Purpose                     | Primary Languages               |
| ---------------- | --------------------------- | ------------------------------- |
| `.backend/`      | Smart contracts & services  | Rust, Solidity, Go              |
| `.frontend/`     | Web & mobile applications   | TypeScript, Dart, Kotlin, Swift |
| `.bot/`          | Python automation & AI      | Python                          |
| `.dev/`          | Infrastructure as Code      | HCL, YAML                       |
| `.devcontainer/` | Development environment     | Dockerfile, YAML                |
| `.github/`       | CI/CD & automation          | YAML                            |
| `.doc/`          | Documentation               | Markdown, JSON                  |
| `.schema/`       | Protocol Buffer definitions | Protocol Buffers                |

---

### 🔗 Key Entry Points

**Backend Development**:

- Start here: `.backend/contract/rust/` or `.backend/contract/solidity/`
- Database: `.backend/db/`
- Token chain: `.backend/token/`

**Frontend Development**:

- Web: `.frontend/web/[framework]/`
- Mobile: `.frontend/android/` or `.frontend/ios/`
- Cross-platform: `.frontend/flutter/`

**Bot Development**:

- Start here: `.bot/core/main.py`
- Integrations: `.bot/integration/`

**Infrastructure**:

- Cloud: `.dev/terraform/`
- Kubernetes: `.dev/k8s/`
- Local dev: `.devcontainer/`

**Documentation**:

- Project docs: `.doc/docs/`
- Developer guides: `.doc/helpers/`
- API specs: `.doc/api/`

---

### 💡 Tips

1. **Starting a New Feature**:

   - Backend: Check `.backend/` for relevant service
   - Frontend: Choose framework in `.frontend/web/`
   - Schema changes: Update `.schema/` first

2. **Setting Up Development**:

   - Use `.devcontainer/` for consistent environment
   - Follow `.doc/docs/CONTRIBUTING.md` for guidelines
   - Check `.github/workflows/` for CI requirements

3. **Understanding the System**:

   - Architecture: `.doc/docs/ARCHITECTURE.md`
   - API contracts: `.schema/` proto files
   - Service interactions: Check proto service definitions

4. **Working with Infrastructure**:
   - Local: `.devcontainer/docker-compose.yml`
   - Production: `.dev/terraform/` and `.dev/k8s/`
   - Monitoring: Check `.dev/k8s/templates/` for observability

---

### 🆘 Troubleshooting

**Problem**: Don't know where to start
**Solution**: Read `.doc/docs/README.md` and `.doc/docs/ARCHITECTURE.md`

**Problem**: Need to understand data models
**Solution**: Check `.schema/` proto files for the relevant domain

**Problem**: CI/CD pipeline failing
**Solution**: Check `.github/workflows/` and review workflow logs

**Problem**: Dev environment not working
**Solution**: See `.devcontainer/README.md` and run `docker-compose up`

---

Built with ❤️ by the Rice-Dev team

Last updated: October 2025
