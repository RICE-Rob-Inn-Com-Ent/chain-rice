# 📁 Root Folders Reference - Rice Monorepo

> Complete architectural guide to monorepo directory structure

**Last Updated**: October 2025 | **Maintainer**: @mrDinkelman

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Application Layer](#-application-layer)
- [Infrastructure Layer](#️-infrastructure-layer)
- [Documentation & Schema](#-documentation--schema)
- [Development Tools](#️-development-tools)
- [Navigation Guide](#-navigation-guide)

---

## 🎯 Overview

Rice Monorepo uses **dot-prefix organization** (`.backend/`, `.frontend/`, etc.) for clear visual separation:

```text
.backend/     → Smart contracts, blockchain, services
.frontend/    → Web & mobile applications
.bot/         → Python automation & AI
.schema/      → Protocol Buffer definitions
.dev/         → Infrastructure as Code
.devcontainer/→ Development environment
.github/      → CI/CD & automation
.doc/         → Documentation
.vscode/      → IDE configuration
```

**Philosophy**:

- **Dot-prefix folders**: First-class components (`.backend/`, `.frontend/`)
- **No prefix**: Root configuration files
- **Clear separation**: Each folder has single responsibility
- **Scalable**: Easy to add new components

---

## 💻 Application Layer

### `.backend/` - Backend Services & Smart Contracts

**Languages**: Rust 🦀, Solidity ⛓️, Go 🔵

**Purpose**: All backend logic, smart contracts, and blockchain services

**Structure**:

```text
.backend/
├── contract/
│   ├── rust/             # CosmWasm smart contracts (Cosmos SDK)
│   │   ├── Cargo.toml    # Rust dependencies
│   │   ├── src/lib.rs    # Contract logic
│   │   ├── .clippy.toml  # Linter config
│   │   └── .rustfmt.toml # Formatter config
│   │
│   └── solidity/         # Ethereum smart contracts (Hardhat)
│       ├── contracts/    # Solidity contracts (*.sol)
│       ├── hardhat.config.js
│       ├── .solhintrc.json  # Linter config
│       └── package.json
│
├── db/                   # Database service (Go)
│   ├── go.mod
│   ├── cmd/server/
│   └── README.md
│
├── token/                # Token chain (Cosmos SDK)
│   ├── app/              # Application logic
│   ├── cmd/tokenchaind/  # Chain binary
│   ├── x/token/          # Token module
│   ├── go.mod
│   └── config.yml
│
├── .golangci.yml         # Go linter config (all Go projects)
└── Dockerfile            # Backend container image
```

**Tech Stack**:

- **CosmWasm**: Rust-based smart contracts for Cosmos
- **Hardhat**: Ethereum development environment
- **Cosmos SDK**: Blockchain application framework
- **gRPC**: Inter-service communication

**Entry Points**:

- Rust contracts: `.backend/contract/rust/src/lib.rs`
- Solidity: `.backend/contract/solidity/contracts/`
- Database service: `.backend/db/cmd/server/`
- Token chain: `.backend/token/cmd/tokenchaind/`

**Development**:

```bash
# Rust contract
cd .backend/contract/rust
cargo build
cargo test
cargo clippy

# Solidity contract
cd .backend/contract/solidity
npm install
npx hardhat compile
npx hardhat test

# Go services
cd .backend/db
go build ./...
go test ./...
```

**CI/CD**:

- Build: `ci-build.yml`
- Test: `ci-test.yml`
- Lint: Clippy, solhint, golangci-lint
- Security: Slither (Solidity), cargo-deny (Rust)

---

### `.frontend/` - Web & Mobile Applications

**Languages**: TypeScript ✨, Dart 🎯, Kotlin ☕, Swift 🍎

**Purpose**: All user-facing applications across platforms

**Structure**:

```text
.frontend/
├── web/                  # Web frameworks (TypeScript)
│   ├── angular/          # Angular component library
│   ├── next/             # Next.js (React) library
│   ├── nuxt/             # Nuxt.js (Vue) library
│   ├── svelte/           # Svelte library
│   ├── shared/           # Shared utilities & types
│   ├── package.json      # Root package.json
│   ├── .eslintrc.js      # ESLint config (all web)
│   └── tsconfig.json     # TypeScript config
│
├── flutter/              # Cross-platform app (Dart)
│   ├── lib/              # Dart source code
│   ├── pubspec.yaml      # Dependencies
│   ├── analysis_options.yaml  # Dart analyzer config
│   └── BUILD.bazel
│
├── android/              # Native Android app (Kotlin)
│   ├── gradle.properties
│   └── BUILD.bazel
│
└── ios/                  # Native iOS app (Swift)
    ├── Package.swift
    └── BUILD.bazel
```

**Tech Stack**:

- **Web**: Angular 17, Next.js 14, Nuxt 3, Svelte 4
- **Mobile**: Flutter 3.24, Kotlin (Android), Swift (iOS)
- **Shared**: TypeScript, Tailwind CSS
- **Build**: Bazel for all platforms

**Entry Points**:

- Angular: `.frontend/web/angular/index.ts`
- Next.js: `.frontend/web/next/index.ts`
- Flutter: `.frontend/flutter/lib/main.dart`
- Shared utils: `.frontend/web/shared/`

**Development**:

```bash
# Web development
cd .frontend/web
npm install
npm run dev:next     # Next.js dev server
npm run lint         # ESLint
npm run format       # Prettier

# Flutter development
cd .frontend/flutter
flutter pub get
flutter run
flutter analyze
```

**CI/CD**:

- Lint: ESLint, Prettier, TSC, flutter analyze
- Test: Jest (web), Flutter test
- Build: Production builds for all platforms

---

### `.bot/` - Python Automation & AI

**Language**: Python 🐍 3.12+

**Purpose**: AI integrations, automation scripts, data processing

**Structure**:

```text
.bot/
├── core/                 # Core bot logic
│   ├── __init__.py
│   ├── main.py           # Main entry point
│   ├── test_basic.py     # Unit tests
│   ├── test_mock.py      # Mock tests
│   └── test_simple.py    # Simple tests
│
├── integration/          # External service integrations
│   ├── __init__.py
│   ├── openai.py         # OpenAI GPT integration
│   ├── openai_mock.py    # OpenAI mocks
│   ├── huggingface.py    # HuggingFace models
│   ├── huggingface_mock.py
│   ├── test_openai.py    # Integration tests
│   └── test_huggingface.py
│
├── pyproject.toml        # Poetry dependencies & tool configs
├── poetry.lock           # Dependency lock file
├── ruff.toml             # Ruff linter config
├── pytest.ini            # Test configuration
├── Dockerfile            # Bot container image
└── BUILD.bazel           # Bazel build
```

**Tech Stack**:

- **Package Manager**: Poetry
- **Linting**: Ruff (ultra-fast, replaces Flake8/Pylint)
- **Formatting**: Black, isort
- **Type Checking**: mypy
- **Testing**: pytest
- **AI**: OpenAI API, HuggingFace Transformers

**Entry Point**: `.bot/core/main.py`

**Development**:

```bash
cd .bot
poetry install          # Install dependencies
poetry shell            # Activate virtual environment

# Development
python core/main.py

# Testing
pytest                  # All tests
pytest core/            # Unit tests only
pytest integration/     # Integration tests only

# Quality
ruff check .            # Lint
ruff format .           # Format
black .                 # Format (alternative)
mypy core integration   # Type check
```

**CI/CD**:

- Lint: Ruff, Black, isort, mypy
- Security: Bandit
- Coverage: pytest-cov (target: 80%+)

---

## 🏗️ Infrastructure Layer

### `.dev/` - Infrastructure as Code

**Languages**: HCL (Terraform), YAML (K8s/Ansible)

**Purpose**: Production infrastructure, cloud resources, orchestration

**Structure**:

```text
.dev/
├── terraform/            # Cloud infrastructure (AWS/GCP/Azure)
│   ├── main.tf           # Root configuration
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── terraform.lock.hcl
│   └── modules/          # Reusable modules
│       ├── calc/         # Calculation module
│       ├── ci/           # CI/CD resources
│       ├── db/           # Database resources
│       ├── job/          # Job scheduler
│       ├── secrets/      # Secret management
│       └── trigger/      # Event triggers
│
├── k8s/                  # Kubernetes & Helm
│   ├── Chart.yaml        # Helm chart metadata
│   └── templates/        # K8s manifests
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── namespace.yaml
│       ├── argocd-application.yaml
│       └── argocd-project.yaml
│
└── ansible/              # Configuration management
    └── requirements.yml  # Ansible Galaxy requirements
```

**Tech Stack**:

- **IaC**: Terraform 1.7+
- **Orchestration**: Kubernetes 1.29+, Helm 3.14+
- **GitOps**: ArgoCD
- **Config Mgmt**: Ansible

**Development**:

```bash
# Terraform
cd .dev/terraform
terraform init
terraform plan
terraform apply

# Kubernetes
cd .dev/k8s
helm lint .
helm template .
kubectl apply -f templates/

# Ansible
cd .dev/ansible
ansible-playbook playbook.yml
```

**CI/CD**:

- Lint: tflint, tfsec, helm lint
- Security: tfsec, Checkov
- Validation: terraform validate

---

### `.devcontainer/` - Development Containers

**Purpose**: Consistent development environment across all machines

**Structure**:

```text
.devcontainer/
├── Dockerfile            # Multi-language dev container
├── docker-compose.yml    # All development services
├── devcontainer.json     # VSCode devcontainer config
├── config/               # Service configurations
│   ├── grafana/
│   ├── prometheus/
│   ├── logstash/
│   ├── loki/
│   └── traefik/
├── init-scripts/         # Initialization scripts
│   ├── postgres/
│   └── mysql/
├── start-devcontainer.sh
├── QUICKSTART.md
├── README.md
└── STATUS.txt
```

**Services Included**:

- **Databases**: PostgreSQL, MySQL, MongoDB
- **Caching**: Redis
- **Message Queues**: Kafka, RabbitMQ
- **Search**: Elasticsearch
- **Storage**: MinIO (S3-compatible)
- **Monitoring**: Prometheus, Grafana, Loki
- **Proxy**: Traefik
- **Logging**: Logstash

**Features**:

- ✅ All languages pre-installed (Python, Go, Rust, Node.js)
- ✅ All tools configured (Bazel, Docker, kubectl, terraform)
- ✅ VSCode extensions auto-installed
- ✅ Port forwarding configured
- ✅ Volume mounts for persistence

**Usage**:

```bash
# Open in VSCode/Cursor
code .
# VSCode will prompt: "Reopen in Container"

# Or manually
docker-compose up -d
```

**Official Docs**: [Dev Containers](https://containers.dev/)

---

### `.github/` - CI/CD & Automation

**Purpose**: GitHub Actions workflows, issue/PR templates, repository configuration

**Structure**:

```text
.github/
├── workflows/            # 15 automated workflows
│   ├── ci-build.yml      # Build verification
│   ├── ci-test.yml       # Test execution
│   ├── ci-lint.yml       # 14 parallel lint jobs ⭐
│   ├── ci-typecheck.yml  # Type checking
│   ├── ci-format.yml     # Format verification
│   ├── cd-release.yml    # Release automation
│   ├── cd-sync-subrepos.yml  # Subrepo sync
│   ├── sec-audit.yml     # Dependency audits
│   ├── sec-codeql.yml    # Static analysis (SAST)
│   ├── sec-trivy.yml     # Container scanning
│   ├── sec-gitleaks.yml  # Secret detection
│   ├── sonarcloud.yml    # Code quality
│   ├── codecov.yml       # Coverage reporting
│   ├── meta-stale.yml    # Stale issue cleanup
│   └── docs-deploy.yml   # Docs deployment
│
├── issue_template/       # Structured issue forms
│   ├── bug-report.yml    # Bug reporting
│   ├── feature-request.yml
│   ├── question.yml
│   └── config.yml        # Template configuration
│
├── CODEOWNERS            # Code review assignments
├── FUNDING.yml           # Sponsorship configuration
├── PULL_REQUEST_TEMPLATE.md  # PR template
└── README.md             # CI/CD documentation
```

**Workflow Categories**:

- **CI** (5): Build, Test, Lint, TypeCheck, Format
- **CD** (2): Release, Subrepo Sync
- **Security** (4): Audit, CodeQL, Trivy, GitLeaks
- **Utilities** (4): Stale, Docs, Coverage, SonarCloud

**Key Features**:

- 14 parallel lint jobs (Python, Go, TS, Rust, Solidity, Dart, etc.)
- Matrix builds (multiple Go components in parallel)
- Smart caching (dependencies, build artifacts)
- Security-first (4 security workflows)
- Conventional commits enforced

**Documentation**: See `.doc/helpers/github/WORKFLOWS.md` for complete guide

---

### `.vscode/` - IDE Configuration

**Purpose**: VSCode/Cursor settings, extensions, and configurations

**Structure**:

```text
.vscode/
├── settings.json         # Workspace settings
├── extensions.json       # 50+ recommended extensions
├── launch.json           # Debug configurations (all languages)
├── tasks.json            # Build/test/lint tasks
└── README.md             # VSCode setup guide
```

**Extensions by Category** (50+ total):

- **Essential**: Prettier, EditorConfig, ErrorLens, GitLens
- **Python**: Pylance, Black, Ruff, isort, Jupyter
- **Go**: Official Go extension
- **Rust**: rust-analyzer, LLDB debugger
- **TypeScript**: ESLint, Volar, Angular, Svelte
- **Dart**: Dart/Flutter official extensions
- **Solidity**: Solidity support, hardhat
- **Infra**: Docker, Kubernetes, Terraform, Ansible
- **Quality**: SonarLint, Coverage Gutters
- **AI**: GitHub Copilot, Copilot Chat

**Settings Highlights**:

- Format on save: Enabled
- Auto-fix on save: Enabled (ESLint, Ruff)
- Real-time linting: All languages
- Integrated terminal: Optimized for monorepo

**Documentation**: See `.doc/helpers/vscode/` for detailed guides

---

## 📦 Documentation & Schema

### `.doc/` - Official Documentation

**Purpose**: All project documentation, API specs, and developer guides

**Structure**:

```text
.doc/
├── docs/                 # Core documentation
│   ├── README.md         # Project overview
│   ├── ARCHITECTURE.md   # System architecture
│   ├── CHANGELOG.md      # Version history (278 lines)
│   ├── CONTRIBUTING.md   # Contribution guidelines
│   ├── SECURITY.md       # Security policy
│   ├── LICENSE.md        # Apache 2.0 license
│   ├── CODE_OF_CONDUCT.md# Community standards
│   └── TODO.md           # Roadmap & backlog
│
├── helpers/              # Developer reference guides
│   ├── README.md         # Navigation hub
│   ├── ROOT_FILES.md     # This file's companion
│   ├── ROOT_FOLDERS.md   # This file (you are here!)
│   │
│   ├── github/           # GitHub-specific guides
│   │   ├── WORKFLOWS.md  # All 15 workflows explained
│   │   ├── ISSUE_TEMPLATE.md
│   │   ├── PULL_REQUEST_TEMPLATE_GUIDE.md
│   │   ├── CODEOWNERS.md
│   │   └── FUNDING.md
│   │
│   └── vscode/           # VSCode guides
│       ├── EXTENSIONS.md # 50+ extensions guide
│       ├── SETTINGS.md   # Settings explained
│       ├── LAUNCH.md     # Debug configs
│       └── TASKS.md      # VSCode tasks
│
├── api/                  # API documentation (OpenAPI)
│   ├── ai.json           # AI/Bot API spec
│   ├── db.json           # Database API spec
│   └── token.json        # Token chain API spec
│
├── openapi.json          # Unified API documentation
├── mkdocs.yml            # Documentation site config
└── index.tpl             # Template for doc generation
```

**Documentation Philosophy**:

1. **Comprehensive**: Cover all aspects
2. **Structured**: Clear hierarchy
3. **Cross-referenced**: Links between docs
4. **Examples**: Real-world code samples
5. **Up-to-date**: Maintained with code

**Documentation Site**:

- Built with: MkDocs
- Deployed to: GitHub Pages
- Updated: On every push to main
- URL: [To be configured]

---

### `.schema/` - Protocol Buffer Definitions

**Language**: Protocol Buffers (proto3)

**Purpose**: Service contracts, API definitions, shared data types

**Structure** (728+ proto files):

```text
.schema/
├── BUILD.bazel           # Bazel build for proto generation
│
├── asset/                # 135 files - Asset management
│   ├── accounting/       # Invoicing, ledger, tax
│   ├── crm_hr/           # CRM, HR, support, loyalty
│   ├── farm/             # Farm management
│   ├── health/           # Healthcare, appointments, pharmacy
│   ├── payments/         # Payment processing
│   ├── storage/          # File storage
│   └── subscriptions/    # Subscription management
│
├── auth/                 # 11 files - Authentication
│   ├── enums/            # Auth states, token types
│   ├── messages/         # User, session data
│   └── services/         # Auth service definitions
│
├── bot/                  # 16 files - Bot/AI services
│   ├── enums/            # Model types, statuses
│   ├── messages/         # Predictions, training jobs
│   └── services/         # AI service definitions
│
├── common/               # 20 files - Shared types
│   ├── enums/            # Countries, currencies, languages
│   ├── messages/         # Timestamp, location, money
│   └── services/         # Common services
│
├── config/               # 24 files - Configuration
│   ├── feature-flags/
│   ├── localization/
│   ├── preferences/
│   ├── settings/
│   └── themes/
│
├── connection/           # 47 files - External connections
│   ├── edi/              # EDI transactions
│   ├── external-apis/    # API gateways
│   ├── telecom/          # Telecom services
│   └── webhooks/         # Webhook management
│
├── content/              # 41 files - Content management
│   ├── ads/              # Advertising
│   ├── analytics/        # Analytics
│   ├── campaigns/        # Marketing campaigns
│   ├── influencer/       # Influencer marketing
│   ├── leads/            # Lead generation
│   ├── loyalty/          # Loyalty programs
│   ├── seo/              # SEO optimization
│   ├── sms/              # SMS messaging
│   └── social/           # Social media
│
├── game/                 # 100 files - Gaming platform
│   ├── achievements/     # Achievements, rewards
│   ├── ar-vr/            # AR/VR features
│   ├── game-core/        # Core game logic
│   ├── game-economy/     # In-game economy
│   ├── leaderboards/     # Rankings, scores
│   ├── marketplace/      # Item marketplace
│   ├── matchmaking/      # Player matching
│   ├── metaverse/        # Metaverse worlds
│   ├── nft-assets/       # NFT integration
│   ├── play-to-earn/     # P2E mechanics
│   ├── social/           # Social features
│   └── sports/           # Sports games
│
├── store/                # 24 files - E-commerce
│   ├── enums/            # Product, order statuses
│   ├── messages/         # Products, orders, payments
│   └── services/         # Store services
│
└── token/                # 310 files - Token chain
    ├── third_party/      # External deps (Cosmos SDK, IBC)
    ├── enums/
    ├── messages/
    └── services/
```

**Tech Stack**:

- **Protocol Buffers**: proto3 syntax
- **Code Generation**: Buf, protoc
- **Languages**: Go, Python, TypeScript, Rust
- **gRPC**: Service-to-service communication

**Development**:

```bash
cd .schema

# Format
buf format -w

# Lint
buf lint

# Check breaking changes
buf breaking --against '.git#branch=main'

# Generate code
buf generate
```

**CI/CD**:

- Lint: buf lint
- Format: buf format --diff
- Breaking changes: buf breaking (PRs only)

---

## 🛠️ Development Tools

### `.bazelignore`

**Purpose**: Directories Bazel should skip during analysis

**Ignored**:

- `node_modules/`
- `.git/`
- `bazel-*` (output directories)
- Virtual environments (`.venv/`, `venv/`)
- Build outputs (`dist/`, `build/`, `target/`)

**Why**: Improves Bazel performance by excluding non-source directories

---

### `.bazelrc`

**Purpose**: Bazel runtime configuration

**Key Settings**:

- Build cache: Local + remote (optional)
- Output format: Colored, verbose errors
- Test output: Stream results
- Platform: Auto-detect (Linux, macOS, Windows)
- Remote execution: Disabled (local builds)

**Performance**:

- Disk cache: `~/.cache/bazel`
- Remote cache: Optional (BuildBuddy, etc.)
- Parallel jobs: Auto (CPU count)

---

### `.gitignore`

**Purpose**: Exclude files from version control

**Categories**:

- **Build Outputs**: `dist/`, `build/`, `target/`, `bazel-*/`
- **Dependencies**: `node_modules/`, `vendor/`, `deps/`
- **IDE**: `.vscode/`, `.idea/`, `.DS_Store`, `*.swp`
- **Compiled**: `*.pyc`, `__pycache__/`, `*.so`, `*.wasm`
- **Logs**: `*.log`, `logs/`
- **Env Files**: `.env`, `.env.local`
- **Secrets**: `*.key`, `*.pem`, `secrets.yml`
- **Caches**: `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`

**Shared Across Team**: Committed to repository

---

### `.gitattributes`

**Purpose**: Git file handling attributes

**Key Configurations**:

- Line endings: LF for shell scripts, auto for others
- Binary detection: Images, fonts, WASM
- Merge strategies: Union for CHANGELOG
- Diff behavior: Custom for proto, JSON
- Linguist: Language detection hints

**Examples**:

```text
*.sh text eol=lf
*.proto linguist-language=Protocol Buffer
*.bzl linguist-language=Starlark
*.wasm binary
```

---

## 📚 Documentation Files

### `README.md`

**Purpose**: Project homepage - first thing visitors see

**Sections**:

1. **Hero**: Tagline, badges, quick value prop
2. **Features**: Key capabilities
3. **Tech Stack**: All technologies (8 languages!)
4. **Quick Start**: Get running in 5 minutes
5. **Structure**: Monorepo organization
6. **Documentation**: Links to detailed guides
7. **Contributing**: How to help
8. **License**: Apache 2.0

**Length**: ~400 lines (comprehensive but scannable)

**Audience**: Everyone (developers, users, contributors)

---

### `.all-contributorsrc`

**Purpose**: All Contributors bot configuration

**What it tracks**:

- 💻 Code contributions
- 📖 Documentation
- 🐛 Bug reports
- 💡 Ideas
- 🎨 Design
- 🔧 Tools
- And 20+ other contribution types

**Usage**:

```bash
# Add contributor
npx all-contributors-cli add username code,doc

# Update README
npx all-contributors-cli generate
```

**Displays**: Contributors section in README with avatars

**Official Docs**: [All Contributors](https://allcontributors.org/)

---

## 🔐 Security & Compliance

### `.snyk`

**Purpose**: Snyk security scanner configuration

**Scans**:

- Dependencies (Python, npm, Go, Rust, etc.)
- Docker images
- Infrastructure as Code (Terraform, K8s)
- Application code

**Policies**:

- Fail on: High + Critical vulnerabilities
- Ignore: Documented exceptions only
- Auto-fix: Enabled where possible

---

### `.licensrc.json`

**Purpose**: License header enforcement

**License**: Apache License 2.0

**Applied To**: All source files (`.py`, `.go`, `.rs`, `.ts`, `.js`, `.sol`)

**Excludes**: Tests, generated files, vendor

---

## 🔄 Configuration Files (Misc)

### `.prettierignore`

**Purpose**: Files Prettier should not format

**Ignored**: `node_modules/`, `dist/`, `*.min.js`, generated files

---

### `.prettierrc.js`

**Purpose**: Prettier configuration (JavaScript/TypeScript formatter)

**Settings**: 120 char width, single quotes, 2-space indent

---

### `.npmrc`

**Purpose**: npm configuration

**Settings**: Save exact versions, no legacy peer deps

---

### `.releaserc.js`

**Purpose**: Semantic-release configuration for automated releases

**Features**: Auto versioning, changelog generation, GitHub releases

---

## 🎯 Navigation Guide

### By Development Phase

**🚀 First Time Setup**:

1. Read: `README.md`
2. Setup: `Makefile` → `make deps-install`
3. Environment: `.devcontainer/` or local setup
4. IDE: `rice-dev.code-workspace`
5. Hooks: `make pre-commit-install`

**💻 Daily Development**:

1. Start: `make dev-start`
2. Code: Use `.vscode/` configured editor
3. Commit: Pre-commit auto-fixes in ~1s
4. Push: CI/CD validates in 3-5min

**📦 Adding Dependencies**:

1. Python: Edit `.bot/pyproject.toml` → `poetry add package`
2. Go: `go get package` → `go mod tidy`
3. Node: `npm install package`
4. Rust: Edit `Cargo.toml` → `cargo update`
5. Bazel: Edit `MODULE.bazel`

**🏗️ Infrastructure Changes**:

1. Local: `.devcontainer/docker-compose.yml`
2. Cloud: `.dev/terraform/`
3. K8s: `.dev/k8s/templates/`

**🔍 Understanding System**:

1. Architecture: `.doc/docs/ARCHITECTURE.md`
2. APIs: `.schema/` proto files
3. Workflows: `.github/workflows/` + `.doc/helpers/github/WORKFLOWS.md`

---

### By File Type

**Build & Packaging**:

- `MODULE.bazel`, `Makefile`, `.bazelrc`, `.bazelignore`

**Code Quality**:

- `.pre-commit-config.yaml`, `.commitlintrc.js`, `.editorconfig`

**Linting**:

- `.markdownlint.json`, `.yamllint`, `.prettierrc.js`, `.prettierignore`

**Security**:

- `.secrets.baseline`, `.snyk`, `.licensrc.json`

**CI/CD**:

- `.github/workflows/*.yml`, `renovate.json`

**Monitoring**:

- `.codecov.yml`, `sonar-project.properties`

**Development**:

- `rice-dev.code-workspace`, `.envrc`, `.tool-versions`

**Documentation**:

- `README.md`, `.all-contributorsrc`

---

## 📊 Quick Reference Matrix

| File                       | Primary Purpose    | Modified By | Auto-Updated              |
| -------------------------- | ------------------ | ----------- | ------------------------- |
| `MODULE.bazel`             | Bazel dependencies | Developers  | Renovate Bot              |
| `Makefile`                 | Command shortcuts  | Maintainers | Manual                    |
| `.pre-commit-config.yaml`  | Pre-commit hooks   | Maintainers | `pre-commit autoupdate`   |
| `.commitlintrc.js`         | Commit format      | Maintainers | Manual                    |
| `.codecov.yml`             | Coverage targets   | Maintainers | Manual                    |
| `sonar-project.properties` | Quality gates      | Maintainers | Manual                    |
| `renovate.json`            | Dependency updates | Maintainers | Renovate Bot              |
| `rice-dev.code-workspace`  | VSCode workspace   | Developers  | Manual                    |
| `.github/workflows/*.yml`  | CI/CD pipelines    | DevOps      | Manual                    |
| `.secrets.baseline`        | Secret whitelist   | Anyone      | `detect-secrets`          |
| `README.md`                | Project docs       | Anyone      | Manual + Contributors bot |

---

## 💡 Pro Tips

### 1. Pre-Commit Performance

**Why is it fast?** (~1-2s instead of 30-60s)

- Only auto-fixes formatting (Black, Prettier, etc.)
- Heavy linting moved to CI/CD (Ruff, ESLint, mypy)
- VSCode extensions provide real-time feedback
- Smart excludes (vendor, generated, deps)

**Result**: Developer commits frequently without friction!

### 2. Conventional Commits Benefits

Good commits enable:

- Automatic changelog generation (`CHANGELOG.md`)
- Semantic versioning (major.minor.patch)
- Better code review
- Git history browsing
- Release notes automation

### 3. Renovate Bot Strategy

**Weekly Updates** (Mondays):

- Dependencies grouped by scope
- Auto-merge: patch/minor with passing tests
- Manual review: major versions

**Security Updates**:

- Immediate PR creation
- High priority
- Auto-merge if tests pass

### 4. Coverage Targets

**80% is the goal**, but:

- Critical paths: Aim for 95%+
- Utilities: 80% is fine
- Tests themselves: Don't test tests!
- Generated code: Excluded

### 5. Multi-Root Workspace

**Benefits**:

- Scoped search (faster)
- Per-workspace extensions
- Organized file tree
- Better IntelliSense

**Usage**: Always open `rice-dev.code-workspace`, not root folder

---

## 🆘 Troubleshooting

### Q: Which files should I never modify?

**A**: Lock files and generated files:

- `poetry.lock`, `package-lock.json`, `Cargo.lock`, `go.sum`
- `bazel-*` directories
- `*.generated.*`, `*_pb.*`
- `.git/` internals

### Q: Pre-commit is slow on my machine?

**A**: Should be ~1-2s. If slower:

```bash
# Clean cache
make pre-commit-clean
make pre-commit-install

# Check what's running
pre-commit run --verbose
```

### Q: How do I add a new dependency?

**A**: Depends on language:

```bash
# Python (.bot/)
cd .bot && poetry add package-name

# Go (.backend/)
cd .backend/db && go get package && go mod tidy

# Node (.frontend/web/)
cd .frontend/web && npm install package

# Rust (.backend/contract/rust/)
cd .backend/contract/rust && cargo add package
```

Then commit the lock file!

### Q: CI/CD failing but works locally?

**A**: Check:

1. Same language versions (`.tool-versions`)
2. Lock files committed
3. Environment variables (CI vs local)
4. Test flakiness (time-dependent, random)

Run same commands as CI:

```bash
# Example for Python
cd .bot
ruff check .
mypy core integration
pytest
```

---

Built with 💎 by CODE GENIUSES

_Every file serves a purpose. Every configuration is battle-tested. Every detail is intentional._

Rice Monorepo - Where quality meets velocity
