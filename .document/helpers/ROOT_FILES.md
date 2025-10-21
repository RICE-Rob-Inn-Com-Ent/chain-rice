# 📄 Root Files Reference - Rice Monorepo

> Complete guide to every configuration file in the repository root

**Last Updated**: October 2025 | **Maintainer**: @mrDinkelman

---

## 📋 Table of Contents

- [Build System](#️-build-system)
- [Code Quality & Linting](#-code-quality--linting)
- [Development Environment](#-development-environment)
- [CI/CD & Automation](#-cicd--automation)
- [Documentation](#-documentation)
- [Security](#️-security)
- [Quick Reference](#-quick-reference)

---

## 🏗️ Build System

### `MODULE.bazel`

**Purpose**: Bazel module definition using Bzlmod (modern dependency management)

**What it does**:

- Defines external dependencies and their versions
- Configures language toolchains (Python, Go, Rust, Node.js, etc.)
- Sets up build rules for the entire monorepo

**Languages Supported**:

- 🐍 Python 3.11+ (`rules_python`)
- 🔵 Go 1.22+ (`rules_go`)
- 🦀 Rust 1.76+ (`rules_rust`)
- ✨ Node.js 20+ (`aspect_rules_js`)
- ☕ Kotlin/Android (`rules_kotlin`)
- 🍎 Swift/iOS (`rules_swift`)
- 📦 Protocol Buffers (`rules_proto`)

**Usage**:

```bash
bazel build //...      # Build entire monorepo
bazel test //...       # Run all tests
bazel clean            # Clean build cache
```

**Official Docs**: [Bazel Modules (Bzlmod)](https://bazel.build/external/module)

---

### `Makefile`

**Purpose**: Developer-friendly command interface for common tasks

**What it does**:

- Simplifies complex commands into single `make` targets
- Provides colored output and help messages
- Wraps Bazel, Docker, and other tools

**Common Commands**:

```bash
make help              # Show all available commands
make deps-install      # Install all dependencies
make deps-update       # Update all dependencies
make dev-start         # Start dev containers
make dev-stop          # Stop dev containers
make pre-commit-install # Setup pre-commit hooks
make pre-commit-run    # Run pre-commit on staged files
```

**Categories**:

- 📦 Dependencies: `deps-install`, `deps-update`
- 🐳 Development: `dev-start`, `dev-stop`
- 🏗️ Build: Bazel build targets
- ✅ Quality: Pre-commit, linting, testing
- 🚀 Blockchain: Token chain management

**Official Docs**: [GNU Make Manual](https://www.gnu.org/software/make/manual/)

---

## 🔍 Code Quality & Linting

### `.pre-commit-config.yaml`

**Purpose**: Ultra-fast pre-commit hooks for code quality (~1-2 seconds)

**3-Layer Quality Strategy**:

1. **VSCode Extensions** → Real-time feedback (0ms)
2. **Pre-commit** → Auto-fix formatting (1-2s) ← THIS FILE
3. **CI/CD** → Comprehensive linting (3-5min)

**What Runs in Pre-Commit**:

- ✅ Auto-fix: Black, Prettier, gofmt, rustfmt, isort, shfmt, buildifier
- ✅ Syntax: YAML, JSON, TOML validation
- ✅ Security: detect-secrets
- ✅ Git: Conventional commits, branch protection
- ❌ NO heavy linting (runs in CI/CD instead)

**What Runs in CI/CD** (`.github/workflows/ci-lint.yml`):

- 🐍 Ruff, mypy, Bandit
- 🔵 golangci-lint, go vet, staticcheck
- ✨ ESLint, TSC
- 🦀 Clippy, cargo-deny
- ⛓️ solhint, Slither
- 🎯 flutter analyze
- 📦 buf lint, buf breaking
- 🏗️ tflint, tfsec
- And 6 more...

**Performance**: 15-30x faster than old config (1-2s vs 30-60s)

**Setup**:

```bash
make pre-commit-install
```

**Official Docs**: [pre-commit.com](https://pre-commit.com/)

---

### `.commitlintrc.js`

**Purpose**: Enforce Conventional Commits specification

**Format**: `<type>(<scope>): <subject>`

**Supported Types**:

- `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`
- `build`, `ci`, `chore`, `revert`, `security`, `deps`
- Extended: `ansible`, `k8s`, `terraform`, `proto`, `contract`, `bot`

**Supported Scopes**:

- Backend: `backend/db`, `backend/token`, `backend/contract/rust`, `backend/contract/solidity`
- Frontend: `frontend/flutter`, `frontend/web/angular`, `frontend/web/next`, etc.
- Bot: `bot/core`, `bot/integration`
- Infra: `dev/terraform`, `dev/k8s`, `dev/ansible`
- Schema: `schema/token`, `schema/asset`, etc.

**Examples**:

```bash
git commit -m "feat(backend/token): add transfer validation"
git commit -m "fix(bot/core): resolve import circular dependency"
git commit -m "docs(readme): update installation steps"
```

**Official Docs**: [Conventional Commits](https://www.conventionalcommits.org/)

---

### `.markdownlint.json`

**Purpose**: Markdown linting configuration

**Rules Configured**:

- Line length: 120 characters (relaxed for code blocks)
- Heading style: ATX (`#` style)
- List style: Dash (`-`)
- Code blocks: Must have language specified
- HTML: Allowed for `<details>`, `<table>`, `<img>`, etc.

**Disabled Rules**:

- MD034 (bare URLs)
- MD041 (first line heading)
- MD051 (link fragments) - disabled for flexibility

**Used By**:

- VSCode extension: `davidanson.vscode-markdownlint`
- CI/CD: `markdownlint-cli2` in `.github/workflows/ci-lint.yml`

**Official Docs**: [markdownlint](https://github.com/DavidAnson/markdownlint)

---

### `.yamllint`

**Purpose**: YAML linting and style enforcement

**Key Rules**:

- Indentation: 2 spaces
- Line length: 120 characters (warning)
- Truthy values: `true`/`false`, `yes`/`no` both allowed
- Document start: Optional
- Colons: One space after, zero before

**Excludes**:

- Helm templates (`.dev/k8s/templates/`)
- Node modules, vendor directories
- Generated files

**Used By**:

- VSCode extension: `redhat.vscode-yaml`
- CI/CD: `yamllint` in `.github/workflows/ci-lint.yml`

**Official Docs**: [yamllint](https://yamllint.readthedocs.io/)

---

### `.editorconfig`

**Purpose**: Consistent coding styles across editors and IDEs

**Global Settings** (`[*]`):

- Charset: UTF-8
- Line endings: LF (Unix-style)
- Trim trailing whitespace: Yes
- Insert final newline: Yes

**Per-Language Settings**:

- Python/JS/TS: 2 spaces, 120 max line length
- Go/Rust/Java: 4 spaces, 120 max line length
- YAML/JSON: 2 spaces
- Protobuf: 2 spaces
- Markdown: No trailing whitespace trim (for double-space line breaks)

**Supported By**:

- VSCode: `editorconfig.editorconfig` extension
- IntelliJ, Vim, Emacs, Sublime: Built-in or via plugins

**Official Docs**: [EditorConfig.org](https://editorconfig.org/)

---

### `.secrets.baseline`

**Purpose**: Whitelist of known "secrets" (false positives)

**What it does**:

- Stores baseline of detected "secrets" that are actually safe
- Prevents false positives (test data, example credentials, etc.)
- Used by `detect-secrets` scanner

**Update Baseline**:

```bash
detect-secrets scan --baseline .secrets.baseline
git add .secrets.baseline
git commit -m "chore(security): update secrets baseline"
```

**Used By**:

- Pre-commit: `detect-secrets` hook
- CI/CD: Security scanning workflows

**Official Docs**: [detect-secrets](https://github.com/Yelp/detect-secrets)

---

## 💻 Development Environment

### `rice-dev.code-workspace`

**Purpose**: VSCode multi-root workspace configuration

**Workspaces** (sorted by usage frequency):

**High Priority** (daily development):

1. 🌍 **ROOT** - Repository root (always first)
2. ⚙️ **BACKEND** - `.backend/` - Smart contracts & services
3. 💻 **FRONTEND** - `.frontend/` - Web & mobile apps
4. 🐍 **BOT** - `.bot/` - Python automation

**Medium Priority** (regular updates):

1. 📋 **SCHEMA** - `.schema/` - Protocol Buffers
2. 📚 **DOC** - `.doc/` - Documentation

**Low Priority** (occasional):

1. 🐳 **CONTAINER** - `.devcontainer/` - Dev containers
2. 🛠️ **INFRA** - `.dev/` - Terraform, K8s, Ansible
3. ⚡ **CI/CD** - `.github/` - GitHub Actions
4. 🔧 **IDE** - `.vscode/` - VSCode settings

**Benefits**:

- Organized file explorer per component
- Per-workspace settings and extensions
- Faster file search (scoped to workspace)
- Better IntelliSense (workspace-aware)

**Usage**:

```bash
# Open workspace
code rice-dev.code-workspace
# or
cursor rice-dev.code-workspace
```

**Official Docs**: [Multi-root Workspaces](https://code.visualstudio.com/docs/editor/multi-root-workspaces)

---

### `.envrc`

**Purpose**: Environment variables and tool versions (direnv)

**What it does**:

- Automatically loads environment variables when entering directory
- Activates Python virtual environments
- Sets tool versions (Go, Node.js, etc.)
- Configures PATH for local tools

**Requires**: [direnv](https://direnv.net/)

**Setup**:

```bash
# Install direnv
brew install direnv  # macOS
# or
apt install direnv   # Linux

# Allow for this directory
direnv allow

# Automatically loads .envrc when cd into directory
```

**Official Docs**: [direnv Documentation](https://direnv.net/)

---

### `.tool-versions`

**Purpose**: Tool version management (asdf)

**What it does**:

- Pins versions of development tools
- Ensures all team members use same versions
- Works with `asdf` version manager

**Tools Configured**:

```text
python 3.12.0
nodejs 20.10.0
golang 1.22.0
rust 1.76.0
terraform 1.7.0
kubectl 1.29.0
helm 3.14.0
```

**Requires**: [asdf](https://asdf-vm.com/)

**Setup**:

```bash
# Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf

# Install all tools
asdf install
```

**Official Docs**: [asdf Documentation](https://asdf-vm.com/guide/getting-started.html)

---

## 🚀 CI/CD & Automation

### `.github/workflows/*.yml`

**Purpose**: GitHub Actions CI/CD pipelines

**15 Workflows Organized by Category**:

**Continuous Integration** (5 workflows):

- `ci-build.yml` - Build verification (~5-10min)
- `ci-test.yml` - Test execution (~10-15min)
- `ci-lint.yml` - 14 parallel lint jobs (~3-5min) ⭐
- `ci-typecheck.yml` - Type checking (~5min)
- `ci-format.yml` - Format verification (~2min)

**Continuous Deployment** (2 workflows):

- `cd-release.yml` - Release automation (~15-20min)
- `cd-sync-subrepos.yml` - Subrepo synchronization (~5min)

**Security** (4 workflows):

- `sec-audit.yml` - Dependency audits (~5-10min)
- `sec-codeql.yml` - Static analysis SAST (~10-15min)
- `sec-trivy.yml` - Container scanning (~5min)
- `sec-gitleaks.yml` - Secret detection (~2min)

**Utilities** (4 workflows):

- `meta-stale.yml` - Stale issue cleanup (~1min)
- `docs-deploy.yml` - Documentation deployment (~3min)
- `codecov.yml` - Coverage reporting (~2min)
- `sonarcloud.yml` - Quality analysis (~5-10min)

**Best Practices**:

- All jobs use latest action versions (`@v4`, `@v5`)
- Smart caching for dependencies
- Parallel execution where possible
- Fail-fast disabled for better diagnostics
- Minimal permissions (security)

**Local Testing**:

```bash
# Install act
brew install act

# Run specific workflow
act -j python-lint
act -j go-lint

# Simulate pull_request event
act pull_request
```

**Official Docs**: [GitHub Actions](https://docs.github.com/en/actions)

---

### `renovate.json`

**Purpose**: Automated dependency updates via Renovate Bot

**What it does**:

- Creates PRs for dependency updates
- Groups related updates (frontend, backend, etc.)
- Auto-merges minor/patch updates
- Runs weekly (Mondays 6 AM UTC)

**Supported Ecosystems**:

- Python: Poetry, pip
- Node.js: npm, yarn, pnpm
- Go: go.mod
- Rust: Cargo.toml
- Docker: Dockerfile, docker-compose
- GitHub Actions: workflow files
- Terraform: provider versions

**Features**:

- 🔒 Security updates: Immediate
- 📦 Minor/patch: Auto-merge (with passing tests)
- 🚨 Major: Requires manual review
- 📊 Grouped by scope: frontend, backend, infra

**Activation** (first time only):

1. Visit [github.com/apps/renovate](https://github.com/apps/renovate)
2. Install on `rice-mono` repository
3. Merge initial configuration PR

**Official Docs**: [Renovate Documentation](https://docs.renovatebot.com/)

---

## 📊 Code Quality & Monitoring

### `.codecov.yml`

**Purpose**: Code coverage reporting and requirements

**Configuration**:

- Target coverage: 80%
- Precision: 2 decimal places
- Range: 70-100%

**Coverage Flags** (per-component):

- `python` → `.bot/`
- `go` → `.backend/`
- `typescript` → `.frontend/web/`
- `rust` → `.backend/contract/rust/`
- `solidity` → `.backend/contract/solidity/`
- `flutter` → `.frontend/flutter/`

**Status Checks**:

- Project: Must maintain ≥80% coverage
- Patch: New code must have ≥80% coverage
- Threshold: 1% decrease allowed

**Upload Coverage**:

```bash
# Python
cd .bot && pytest --cov --cov-report=xml
codecov -f coverage.xml -F python

# Go
cd .backend/db && go test -coverprofile=coverage.out ./...
codecov -f coverage.out -F go
```

**Official Docs**: [Codecov Documentation](https://docs.codecov.com/)

---

### `sonar-project.properties`

**Purpose**: SonarCloud static code analysis configuration

**Quality Gates**:

- Maintainability Rating: A
- Reliability Rating: A
- Security Rating: A
- Coverage on New Code: >80%
- Duplications: <3%

**Languages Analyzed**:

- JavaScript/TypeScript
- Python
- Go
- Java/Kotlin

**Metrics Tracked**:

- Code smells
- Bugs
- Security hotspots
- Technical debt
- Complexity
- Duplications

**View Results**: [SonarCloud Dashboard](https://sonarcloud.io/project/overview?id=rice-mono)

**Official Docs**: [SonarQube Properties](https://docs.sonarqube.org/latest/analysis/analysis-parameters/)

---

### `taplo.toml`

**Purpose**: TOML file formatter configuration

**What it formats**:

- `Cargo.toml` (Rust dependencies)
- `pyproject.toml` (Python projects)
- `buf.yaml` (Protobuf config)
- All other `.toml` files

**Rules**:

- Indentation: 2 spaces
- Array alignment: Enabled
- Inline table expansion: Smart
- Key ordering: Preserved

**Usage**:

```bash
taplo format           # Format all TOML files
taplo check            # Check formatting
taplo lint             # Lint TOML files
```

**Integration**:

- VSCode: `tamasfe.even-better-toml` extension
- Pre-commit: `pretty-format-toml` hook
- CI/CD: Format check in workflows

**Official Docs**: [Taplo](https://taplo.tamasfe.dev/)

---

## 🛡️ Security

### `.snyk`

**Purpose**: Snyk security scanning configuration

**What it scans**:

- Dependencies for known vulnerabilities
- Container images
- Infrastructure as Code (Terraform, K8s)
- Code for security issues

**Policies**:

- Fail on: High and critical vulnerabilities
- Ignore: Specific CVEs with justification
- Auto-remediate: When patches available

**Usage**:

```bash
snyk test           # Test for vulnerabilities
snyk monitor        # Monitor project continuously
```

**Official Docs**: [Snyk Documentation](https://docs.snyk.io/)

---

### `.licensrc.json`

**Purpose**: License header management and validation

**What it does**:

- Ensures all source files have proper license headers
- Validates license compliance
- Auto-inserts headers if missing

**License**: Apache License 2.0

**Header Template**:

```text
Copyright 2025 Rice Monorepo Contributors

Licensed under the Apache License, Version 2.0
```

**Applied To**:

- `.py`, `.go`, `.rs`, `.ts`, `.js`, `.sol` source files
- Excludes: tests, generated files, vendor

**Official Docs**: [License Headers](https://github.com/apache/skywalking-eyes)

---

## 📚 Documentation

### `README.md`

**Purpose**: Project homepage and quick start guide

**Sections**:

1. **Hero**: Project description and badges
2. **Features**: Key capabilities
3. **Quick Start**: Installation and usage
4. **Tech Stack**: All technologies used
5. **Structure**: Monorepo organization
6. **Documentation**: Links to detailed guides
7. **Contributing**: How to contribute
8. **License**: Apache 2.0

**Target Audience**:

- New developers (getting started)
- Contributors (how to help)
- Users (understanding the project)

**Length**: ~300 lines (concise but comprehensive)

---

### `.all-contributorsrc`

**Purpose**: All Contributors bot configuration

**What it does**:

- Tracks all types of contributions (code, docs, design, etc.)
- Generates contributor list automatically
- Adds contributors to README

**Contribution Types**:

- 💻 Code
- 📖 Documentation
- 🎨 Design
- 🐛 Bug reports
- 💡 Ideas
- 🤔 Q&A
- And 20+ more types

**Usage**:

```bash
# Add contributor
npx all-contributors-cli add username code,doc

# Generate contributor list
npx all-contributors-cli generate
```

**Official Docs**: [All Contributors](https://allcontributors.org/)

---

## 🔧 Additional Configuration

### `.bazelrc`

**Purpose**: Bazel build configuration

**Key Settings**:

- Build cache location
- Compiler flags
- Test output format
- Remote caching (optional)
- Platform-specific settings

---

### `.bazelignore`

**Purpose**: Directories Bazel should ignore

**Ignored**:

- `node_modules/`
- `.git/`
- `bazel-*` output directories
- Virtual environments
- IDE directories

---

### `.gitattributes`

**Purpose**: Git attributes for file handling

**Configures**:

- Line endings per file type
- Binary file detection
- Merge strategies
- Diff behavior

**Key Rules**:

```text
*.sh text eol=lf           # Shell scripts: LF line endings
*.proto linguist-language=Protocol Buffer
*.bzl linguist-language=Starlark
```

---

### `.gitignore`

**Purpose**: Files to exclude from version control

**Categories**:

- Build outputs: `dist/`, `build/`, `target/`, `bazel-*/`
- Dependencies: `node_modules/`, `vendor/`, `deps/`
- IDE: `.vscode/`, `.idea/`, `.DS_Store`
- Compiled: `*.pyc`, `*.so`, `*.wasm`
- Logs: `*.log`
- Sensitive: `.env`, `*.key`, `*.pem`

---

### `.prettierignore`

**Purpose**: Files Prettier should not format

**Ignored**:

- `node_modules/`
- `dist/`, `build/`
- `*.min.js`, `*.min.css`
- `package-lock.json`
- Generated files

---

### `.prettierrc.js`

**Purpose**: Prettier code formatter configuration

**Settings**:

- Print width: 120 characters
- Single quotes: Yes (for JS/TS)
- Trailing commas: ES5
- Tab width: 2 spaces
- Semicolons: Always

**Languages**:

- JavaScript, TypeScript, JSX, TSX
- JSON, YAML, Markdown
- CSS, SCSS, Less
- HTML
- Solidity (via plugin)

---

### `.npmrc`

**Purpose**: npm package manager configuration

**Settings**:

- Registry: npm default or custom
- Save exact versions: Yes
- Legacy peer deps: False

---

### `.releaserc.js`

**Purpose**: Semantic release configuration

**What it does**:

- Analyzes commits to determine next version
- Generates changelog
- Creates GitHub releases
- Publishes packages

**Version Rules**:

- `feat:` → Minor version bump
- `fix:` → Patch version bump
- `BREAKING CHANGE:` → Major version bump

---

## 🎯 Quick Reference

### 📁 File Organization

| Category          | Files                                                 | Purpose               |
| ----------------- | ----------------------------------------------------- | --------------------- |
| **Build**         | `MODULE.bazel`, `Makefile`, `.bazelrc`                | Build system          |
| **Quality**       | `.pre-commit-config.yaml`, `.commitlintrc.js`         | Code quality          |
| **Linting**       | `.markdownlint.json`, `.yamllint`, `.editorconfig`    | File formatting       |
| **Security**      | `.secrets.baseline`, `.snyk`, `.licensrc.json`        | Security & compliance |
| **CI/CD**         | `.github/workflows/*.yml`, `renovate.json`            | Automation            |
| **Coverage**      | `.codecov.yml`, `sonar-project.properties`            | Quality metrics       |
| **Environment**   | `rice-dev.code-workspace`, `.envrc`, `.tool-versions` | Dev setup             |
| **Documentation** | `README.md`, `.all-contributorsrc`                    | Project docs          |

---

### 🚀 Common Workflows

**First Time Setup**:

```bash
make deps-install          # Install all dependencies
make pre-commit-install    # Setup pre-commit hooks
direnv allow              # Enable direnv (if installed)
```

**Daily Development**:

```bash
make dev-start            # Start development environment
# ... code changes ...
git add .
git commit -m "feat(scope): description"  # Conventional commit
make dev-stop             # End of day
```

**Before Push**:

```bash
make pre-commit-run-all   # Run all hooks
make test                 # Run tests
git push                  # Push (triggers CI/CD)
```

**Updating Dependencies**:

```bash
# Automated (weekly via Renovate Bot)
# Or manual:
make deps-update
```

---

### 📖 Documentation Links

All root files link to these comprehensive guides:

| Topic                | Guide Location                     |
| -------------------- | ---------------------------------- |
| **CI/CD Workflows**  | `.doc/helpers/github/WORKFLOWS.md` |
| **Folder Structure** | `.doc/helpers/ROOT_FOLDERS.md`     |
| **VSCode Setup**     | `.doc/helpers/vscode/SETTINGS.md`  |
| **Contributing**     | `.doc/docs/CONTRIBUTING.md`        |
| **Architecture**     | `.doc/docs/ARCHITECTURE.md`        |

---

### 🔗 External Resources

- **Bazel**: [bazel.build](https://bazel.build/)
- **pre-commit**: [pre-commit.com](https://pre-commit.com/)
- **GitHub Actions**: [docs.github.com/actions](https://docs.github.com/en/actions)
- **Conventional Commits**: [conventionalcommits.org](https://www.conventionalcommits.org/)
- **Renovate**: [docs.renovatebot.com](https://docs.renovatebot.com/)
- **Codecov**: [docs.codecov.com](https://docs.codecov.com/)
- **SonarCloud**: [sonarcloud.io/documentation](https://sonarcloud.io/documentation)

---

## 💡 Pro Tips

### 1. Understanding Pre-Commit

**Pre-commit is FAST** (~1-2s) because it only auto-fixes formatting:

- ✅ Runs: Black, Prettier, gofmt, isort
- ❌ Doesn't run: Ruff, ESLint, mypy, Clippy (those run in CI/CD)

**Why?** You get instant feedback from VSCode extensions, so pre-commit just ensures consistent formatting.

### 2. Commit Message Mastery

Good commits help with:

- Automatic changelog generation
- Semantic versioning
- Code review
- Git history browsing

**Template**:

```bash
type(scope): short description

Longer description if needed.

Fixes #123
BREAKING CHANGE: Details about breaking change
```

### 3. Coverage Best Practices

**Aim for 80%+ coverage**, but remember:

- 100% coverage ≠ bug-free code
- Test behavior, not implementation
- Focus on critical paths
- Integration tests > unit tests (sometimes)

### 4. Renovate Bot

**Don't merge blindly!**

- Check changelog for breaking changes
- Run tests locally if major update
- Review security advisories
- Update lock files if needed

---

## 🆘 Troubleshooting

### Problem: Bazel build fails

**Solution**:

```bash
bazel clean --expunge
bazel sync --configure
bazel build //...
```

### Problem: Pre-commit too slow

**Check**: Are you editing vendor/generated files?

```bash
pre-commit run --verbose --files path/to/file
```

Should see: `Skipped` for excluded files

### Problem: CI/CD workflow failing

**Steps**:

1. Check workflow logs in GitHub Actions
2. Run same commands locally:

   ```bash
   cd .bot && ruff check .
   cd .backend/db && golangci-lint run
   ```

3. Fix issues locally
4. Push again

### Problem: Secrets detected (false positive)

**Solution**:

```bash
detect-secrets scan --baseline .secrets.baseline
git add .secrets.baseline
git commit -m "chore(security): update baseline"
```

---

### Built with 💎 by CODE GENIUSES for CODE GENIUSES

_Every file has a purpose. Every configuration is optimized. Every detail matters._

**Rice Monorepo** | October 2025
