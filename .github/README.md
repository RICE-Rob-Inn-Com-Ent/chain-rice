# 🚀 CI/CD Documentation - Rice Monorepo

> **Million Dollar Per Hour Development Environment**
> 100% Open Source | Zero Corporate Dependencies | Production-Ready

[![Build](https://github.com/mrDinkelman/rice-mono/workflows/Build/badge.svg)](https://github.com/mrDinkelman/rice-mono/actions/workflows/ci-build.yml)
[![Test](https://github.com/mrDinkelman/rice-mono/workflows/Test/badge.svg)](https://github.com/mrDinkelman/rice-mono/actions/workflows/ci-test.yml)
[![Lint](https://github.com/mrDinkelman/rice-mono/workflows/Lint/badge.svg)](https://github.com/mrDinkelman/rice-mono/actions/workflows/ci-lint.yml)
[![Security Audit](https://github.com/mrDinkelman/rice-mono/workflows/Security%20Audit/badge.svg)](https://github.com/mrDinkelman/rice-mono/actions/workflows/sec-audit.yml)

---

## 📑 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Workflows](#workflows)
  - [Continuous Integration (CI)](#continuous-integration-ci)
  - [Continuous Deployment (CD)](#continuous-deployment-cd)
  - [Security & Compliance](#security--compliance)
  - [Repository Management](#repository-management)
- [Issue Templates](#issue-templates)
- [Pull Request Process](#pull-request-process)
- [Code Ownership](#code-ownership)
- [Sponsorship & Funding](#sponsorship--funding)
- [Configuration Files](#configuration-files)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## 🎯 Overview

This directory contains the complete CI/CD infrastructure for the Rice Monorepo. Our automation pipeline provides:

- **🏗️ Automated Building**: Multi-language build system using Bazel
- **✅ Comprehensive Testing**: Python, Go, TypeScript, Rust, Solidity, Dart
- **🔍 Code Quality**: 3-layer linting (VSCode + Pre-commit + CI/CD) with 14 parallel jobs
- **🔒 Security Scanning**: Dependency audits, CodeQL analysis, container scanning
- **📦 Release Automation**: Semantic versioning, changelog generation, artifact publishing
- **🐳 Docker Publishing**: Automated container builds and registry publishing
- **🔄 Subrepo Synchronization**: Keep standalone repositories in sync
- **📊 Observability**: Build metrics, test coverage, security reports

### Architecture Philosophy

1. **100% Open Source**: Every tool is FOSS - no vendor lock-in
2. **Reproducible Builds**: Hermetic builds with Bazel
3. **Fast Feedback**: Parallel execution, intelligent caching
4. **Security First**: Multiple layers of security scanning
5. **Developer Experience**: Ultra-fast pre-commit (~1-2s) + real-time VSCode linting
6. **Performance Optimized**: 15-30x faster pre-commit (1-2s vs 30-60s)

---

## 🚀 Quick Start

### For Contributors

1. **Fork and Clone**

   ```bash
   git clone https://github.com/your-username/rice-mono.git
   cd rice-mono
   ```

2. **Create a Feature Branch**

   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make Your Changes**

   ```bash
   # Edit files...
   git add .
   git commit -m "feat: add amazing feature"
   ```

4. **Push and Create PR**

   ```bash
   git push origin feature/amazing-feature
   # Open PR on GitHub
   ```

### CI/CD Triggers

- **On Push to `main` or `dev`**: Runs CI build, test, lint, security scans
- **On Pull Request**: Runs all CI checks
- **On Tag `v*.*.*`**: Triggers release workflow
- **Daily**: Runs security audits and stale issue management
- **Weekly**: Deep security scans (CodeQL)

---

## 📁 Directory Structure

```
.github/
├── README.md                      # This file - CI/CD overview
├── CODEOWNERS                     # Code ownership and review assignments
├── FUNDING.yml                    # Sponsorship and funding information
├── PULL_REQUEST_TEMPLATE.md       # PR description template
│
├── issue_template/                # Issue forms for structured reporting
│   ├── bug-report.yml            # Bug report form
│   ├── feature-request.yml       # Feature request form
│   ├── question.yml              # Question/discussion form
│   └── config.yml                # Issue template configuration
│
└── workflows/                     # GitHub Actions CI/CD pipelines
    ├── ci-build.yml              # Build verification
    ├── ci-test.yml               # Test execution
    ├── ci-lint.yml               # Code quality checks
    ├── ci-typecheck.yml          # Type checking
    ├── ci-format.yml             # Code formatting verification
    ├── cd-release.yml            # Release automation
    ├── cd-sync-subrepos.yml      # Subrepo synchronization
    ├── sec-audit.yml             # Dependency security audits
    ├── sec-codeql.yml            # CodeQL security scanning
    ├── sec-trivy.yml             # Container security scanning
    ├── sec-gitleaks.yml          # Secrets detection
    ├── sonarcloud.yml            # SonarCloud code quality analysis
    ├── codecov.yml               # Code coverage reporting
    ├── meta-stale.yml            # Stale issue management
    └── docs-deploy.yml           # Documentation deployment

📚 Detailed Documentation:
    ../.doc/helpers/
    ├── PRE_COMMIT_GUIDE.md       # Pre-commit & linting architecture
    └── github/
        ├── WORKFLOWS.md          # Complete workflow guide
        ├── ISSUE_TEMPLATE.md     # Issue template guide
        ├── CODEOWNERS.md         # Code ownership guide
        ├── FUNDING.md            # Funding guide
        └── PULL_REQUEST_TEMPLATE_GUIDE.md  # PR template guide
```

---

## ⚙️ Workflows

### Continuous Integration (CI)

#### 🏗️ [Build Workflow](workflows/ci-build.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests
**Purpose**: Verify that all code compiles successfully

**What it does**:

- Installs Bazel build system
- Builds all targets: `bazel build //...`
- Validates build configuration
- Caches build artifacts for speed

**Tools**: [Bazel](https://bazel.build/)

---

#### ✅ [Test Workflow](workflows/ci-test.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests
**Purpose**: Run all test suites across languages

**Test Coverage**:

- **Python**: pytest with coverage reporting
- **Go**: `go test ./...` with race detector
- **TypeScript/JavaScript**: Jest, Vitest
- **Rust**: `cargo test`
- **Solidity**: Hardhat tests
- **Dart/Flutter**: `flutter test`

**Tools**: [pytest](https://pytest.org/), [Go testing](https://golang.org/pkg/testing/), [Jest](https://jestjs.io/),
[cargo](https://doc.rust-lang.org/cargo/)

---

#### 🎨 [Lint Workflow](workflows/ci-lint.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests
**Purpose**: Comprehensive code quality enforcement across 14 parallel jobs

**Architecture**: 3-layer quality assurance (VSCode + Pre-commit + CI/CD)

**14 Parallel Jobs**:

- 🐍 **Python**: Ruff, Black, isort, mypy, Bandit
- 🔵 **Go**: golangci-lint, go vet, staticcheck (matrix: db, token)
- ✨ **TypeScript**: ESLint, Prettier, TSC type checking
- 🦀 **Rust**: Clippy, rustfmt, cargo-deny
- ⛓️ **Solidity**: solhint, Prettier, Slither security
- 🎯 **Dart/Flutter**: flutter analyze, dart format
- 📦 **Protobuf**: buf lint, buf format, buf breaking
- 🏗️ **Terraform**: tflint, tfsec, terraform validate
- 📝 **Markdown**: markdownlint
- 📋 **YAML**: yamllint
- 🐳 **Docker**: hadolint
- 🐚 **Shell**: ShellCheck
- 🏗️ **Bazel**: buildifier
- 📖 **Spelling**: codespell

**Performance**: Pre-commit ~1-2s (formatting only) → CI/CD ~3-5min (full linting)

**→ See [WORKFLOWS.md](../.doc/helpers/github/WORKFLOWS.md#3-lint-workflow-ci-lintyml) for detailed architecture**

---

#### 🧠 [SonarCloud Workflow](workflows/sonarcloud.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests
**Purpose**: Comprehensive code quality and security analysis

**What it analyzes**:

- Code quality metrics (maintainability, reliability, security)
- Bug detection patterns
- Security hotspots
- Code smells and technical debt
- Duplicate code detection
- Test coverage integration

**Quality Gates**:

- Maintainability rating: A
- Reliability rating: A
- Security rating: A
- Coverage on new code: > 80%

**Tools**: [SonarCloud](https://sonarcloud.io/)

---

#### 📊 [Codecov Workflow](workflows/codecov.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests
**Purpose**: Track and report test coverage

**Coverage by Language**:

- Python (pytest-cov)
- Go (coverprofile)
- TypeScript (Istanbul/Jest)
- Rust (llvm-cov)
- Solidity (solidity-coverage)
- Flutter (lcov)

**Features**:

- Coverage trends over time
- PR coverage diff comments
- Flag-based coverage (per component)
- Coverage visualizations

**Tools**: [Codecov](https://codecov.io/)

---

#### 🔤 [Type Check Workflow](workflows/ci-typecheck.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests
**Purpose**: Verify type safety across typed languages

**Type Checkers**:

- **Python**: `mypy` (strict mode)
- **TypeScript**: `tsc --noEmit`
- **Go**: Built-in type checking
- **Rust**: Built-in type checking

---

#### 📐 [Format Check Workflow](workflows/ci-format.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests
**Purpose**: Ensure consistent code formatting

**Formatters**:

- **Python**: `black`, `isort`
- **Go**: `gofmt`, `goimports`
- **TypeScript**: `prettier`
- **Rust**: `rustfmt`
- **Solidity**: `prettier-plugin-solidity`
- **TOML**: `taplo`
- **Protobuf**: `buf format`

---

### Continuous Deployment (CD)

#### 📦 [Release Workflow](workflows/cd-release.yml)

**Trigger**: Git tags `v*.*.*`, Manual dispatch
**Purpose**: Automate the release process

**Release Process**:

1. **Version Detection**: Extract from git tag or manual input
2. **Changelog Generation**: Auto-generate from commits
3. **GitHub Release**: Create release with notes
4. **Build Artifacts**: Compile production builds
5. **Docker Images**: Build and publish containers
6. **NPM Packages**: Publish to registries (if applicable)
7. **Documentation**: Deploy updated docs

**Artifacts Published**:

- Source code archives (`.tar.gz`, `.zip`)
- Compiled binaries (Linux, macOS, Windows)
- Docker images (backend, bots)
- NPM packages (frontend libraries)
- Helm charts (Kubernetes deployments)

**Tools**: [semantic-release](https://semantic-release.gitbook.io/), [Docker Buildx](https://docs.docker.com/buildx/)

---

#### 🔄 [Subrepo Sync Workflow](workflows/cd-sync-subrepos.yml)

**Trigger**: Push to `main`, Manual dispatch
**Purpose**: Keep standalone repositories synchronized with monorepo

**Synchronized Repos**:

- `rice-backend` ← `/backend`
- `rice-frontend` ← `/frontend`
- `rice-bots` ← `/bots`
- `rice-contracts` ← `/backend/contract`
- `rice-proto` ← `/schema`

**Tools**: [git-subrepo](https://github.com/ingydotnet/git-subrepo),
[git-subtree](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging)

---

### Security & Compliance

#### 🔒 [Security Audit Workflow](workflows/sec-audit.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests, Weekly schedule
**Purpose**: Scan dependencies for known vulnerabilities

**Audits by Ecosystem**:

- **Python**: `poetry audit`, `pip-audit`, `safety`
- **Node.js**: `npm audit`, `yarn audit`, `snyk`
- **Go**: `govulncheck`, `nancy`
- **Rust**: `cargo audit`
- **Solidity**: `slither`, `mythril`

**SBOM Generation**: Software Bill of Materials for compliance

**Tools**: [pip-audit](https://pypi.org/project/pip-audit/),
[govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck), [cargo-audit](https://crates.io/crates/cargo-audit)

---

#### 🛡️ [CodeQL Security Scan](workflows/sec-codeql.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests, Weekly
**Purpose**: Static application security testing (SAST)

**Languages Analyzed**:

- JavaScript/TypeScript
- Python
- Go
- (Rust support coming soon)

**Detects**:

- SQL injection
- Cross-site scripting (XSS)
- Path traversal
- Command injection
- Insecure cryptography
- Authentication issues
- And 100+ other vulnerability types

**Tools**: [CodeQL](https://codeql.github.com/)

---

#### 🐳 [Trivy Container Scan](workflows/sec-trivy.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests, Daily
**Purpose**: Scan Docker images for vulnerabilities

**Scans**:

- OS packages (Alpine, Ubuntu, Debian)
- Application dependencies
- Configuration issues
- Secret detection in images

**Tools**: [Trivy](https://aquasecurity.github.io/trivy/)

---

#### 🔑 [GitLeaks Secret Detection](workflows/sec-gitleaks.yml)

**Trigger**: Push to `main`/`dev`, Pull Requests
**Purpose**: Prevent secrets from being committed

**Detects**:

- API keys
- Private keys
- Passwords
- Tokens
- Connection strings
- AWS credentials
- 100+ secret patterns

**Tools**: [Gitleaks](https://gitleaks.io/)

---

### Repository Management

#### 🏷️ [Stale Issues/PRs](workflows/meta-stale.yml)

**Trigger**: Daily at midnight UTC
**Purpose**: Keep issue tracker organized

**Configuration**:

- Issues stale after 60 days
- PRs stale after 30 days
- Closed after 7 days of staleness
- Exempt labels: `pinned`, `security`, `bug`, `enhancement`

**Tools**: [actions/stale](https://github.com/actions/stale)

---

#### 🎯 [Label Sync](workflows/meta-label-sync.yml)

**Trigger**: Push to `main`, Manual dispatch
**Purpose**: Synchronize repository labels

**Label Categories**:

- Type: `bug`, `feature`, `docs`, `refactor`
- Priority: `P0-critical`, `P1-high`, `P2-medium`, `P3-low`
- Status: `in-progress`, `blocked`, `needs-review`
- Area: `backend`, `frontend`, `bots`, `contracts`, `infra`

---

#### 📚 [Docs Deploy](workflows/docs-deploy.yml)

**Trigger**: Push to `main`, Manual dispatch
**Purpose**: Deploy documentation to GitHub Pages

**Deploys**:

- API documentation
- Architecture guides
- Developer guides
- OpenAPI specs

**Tools**: [MkDocs](https://www.mkdocs.org/), [GitHub Pages](https://pages.github.com/)

---

## 🎫 Issue Templates

We use structured issue forms to collect necessary information efficiently.

### Available Templates

1. **[Bug Report](issue_template/bug-report.yml)**: Report a bug or unexpected behavior
2. **[Feature Request](issue_template/feature-request.yml)**: Propose a new feature
3. **[Question](issue_template/question.yml)**: Ask questions or start discussions

### Using Issue Templates

1. Navigate to [Issues → New Issue](../../issues/new/choose)
2. Select the appropriate template
3. Fill in all required fields
4. Submit the issue

**→ See [ISSUE_TEMPLATE.md](../.doc/helpers/github/ISSUE_TEMPLATE.md) for detailed guide**

---

## 🔀 Pull Request Process

### Before Submitting

1. **Create an issue** describing the change
2. **Fork the repository** and create a feature branch
3. **Write tests** for your changes
4. **Run local checks**:

   ```bash
   make lint
   make test
   make build
   ```

5. **Update documentation** if needed

### PR Template

All pull requests must use our [PR template](PULL_REQUEST_TEMPLATE.md) which includes:

- Description of changes
- Related issues
- Type of change (bugfix, feature, docs, etc.)
- Testing checklist
- Documentation updates
- Breaking changes

### Review Process

1. **Automated Checks**: All CI workflows must pass (build, test, lint, security)
2. **Code Review**: At least one approval from a code owner
3. **Merge**: Squash and merge to `main`

**→ See [PULL_REQUEST_TEMPLATE_GUIDE.md](../.doc/helpers/github/PULL_REQUEST_TEMPLATE_GUIDE.md) for detailed guide**

---

## 👥 Code Ownership

The [CODEOWNERS](CODEOWNERS) file defines who is responsible for reviewing changes to specific parts of the codebase.

### How It Works

- When you create a PR, GitHub automatically requests reviews from relevant code owners
- Code owners are defined using file patterns (similar to `.gitignore`)
- At least one code owner approval is required to merge

### Key Ownership Areas

- **Backend**: @mrDinkelman
- **Frontend**: @mrDinkelman
- **Smart Contracts**: @mrDinkelman
- **Bots/AI**: @mrDinkelman
- **Infrastructure**: @mrDinkelman
- **Documentation**: @mrDinkelman

**→ See [CODEOWNERS.md](../.doc/helpers/github/CODEOWNERS.md) for detailed guide**

---

## 💰 Sponsorship & Funding

Support this project through various platforms defined in [FUNDING.yml](FUNDING.yml).

Available sponsorship options:

- GitHub Sponsors
- Open Collective
- Patreon
- Buy Me a Coffee
- Crypto donations

**→ See [FUNDING.md](../.doc/helpers/github/FUNDING.md) for detailed guide**

---

## 🤖 Automated Dependency Updates

### Renovate Bot

This repository uses **Renovate** (better than Dependabot!) for automated dependency updates.

**Configuration**: `renovate.json` in root directory

**Features**:

- ✅ Weekly updates (Mondays at 6 AM UTC)
- ✅ Auto-merge minor/patch updates
- ✅ Groups monorepo packages
- ✅ Supports: Python, Go, Node.js, Rust, Terraform, Docker, GitHub Actions

**Activation** (one-time, 3 minutes):

1. Visit [https://github.com/apps/renovate](https://github.com/apps/renovate)
2. Click "Install"
3. Select `rice-mono` repository
4. Merge Renovate's configuration PR

**Official Docs**: [Renovate Documentation](https://docs.renovatebot.com/)

---

## 📋 Configuration Files

### Root Configuration Files

```
.codecov.yml               - Codecov coverage configuration
renovate.json              - Renovate Bot dependency update rules
sonar-project.properties   - SonarCloud quality analysis settings
```

### Workflow Configuration

All workflows are configured using YAML files in the `workflows/` directory.

#### Common Workflow Structure

```yaml
name: Workflow Name
on:
  push:
    branches: [main, dev]
  pull_request:

jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Step name
        run: command
```

#### Reusable Workflows

We use composite actions and reusable workflows to reduce duplication:

```yaml
jobs:
  call-reusable:
    uses: ./.github/workflows/reusable-build.yml
    with:
      environment: production
```

### Secrets Management

Required secrets (set in repository settings):

- `GITHUB_TOKEN`: Automatically provided by GitHub Actions
- `NPM_TOKEN`: For publishing NPM packages (if applicable)
- `DOCKER_HUB_TOKEN`: For Docker Hub publishing (if applicable)

---

## 🎯 Best Practices

### For Workflows

1. **Use Latest Action Versions**: Pin to major version (`@v4`)
2. **Cache Dependencies**: Speed up builds with caching
3. **Fail Fast**: Use `fail-fast: false` only when necessary
4. **Parallel Jobs**: Run independent jobs in parallel
5. **Permissions**: Use minimal required permissions
6. **Conditional Execution**: Skip unnecessary jobs with `if` conditions

### For Commits

1. **Conventional Commits**: Use semantic commit messages

   ```
   feat: add new feature
   fix: resolve bug
   docs: update documentation
   chore: update dependencies
   ```

2. **Atomic Commits**: One logical change per commit
3. **Test Before Commit**: Ensure tests pass locally
4. **Sign Commits**: Use GPG signing for security

### For Pull Requests

1. **Small PRs**: Keep changes focused and reviewable
2. **Clear Descriptions**: Explain what, why, and how
3. **Link Issues**: Reference related issues
4. **Update Tests**: Add/update tests for changes
5. **Documentation**: Update docs when needed

---

## 🐛 Troubleshooting

### Build Failures

**Problem**: `bazel build //...` fails
**Solution**:

```bash
# Clean build cache
bazel clean --expunge
# Rebuild
bazel build //...
```

### Test Failures

**Problem**: Tests fail in CI but pass locally
**Solution**:

- Check environment differences (Python version, Go version, etc.)
- Verify dependencies are locked (poetry.lock, go.sum, package-lock.json)
- Look for time-dependent or flaky tests

### Lint Failures

**Problem**: Linter finds issues
**Solution**:

```bash
# Auto-fix most issues
pre-commit run --all-files
# Or use specific linters
ruff format .
black .
prettier --write .
```

### Permission Errors

**Problem**: Workflow fails with permission error
**Solution**:

- Check workflow permissions configuration
- Verify GitHub token has required scopes
- Ensure repository settings allow workflow actions

### Workflow Not Triggering

**Problem**: Push doesn't trigger workflow
**Solution**:

- Check workflow `on` conditions
- Verify branch names match
- Check if workflow file is valid YAML
- Look at Actions tab for disabled workflows

---

## 📚 Resources

### Official Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [CODEOWNERS Documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests)

### Build Systems

- [Bazel Documentation](https://bazel.build/docs)
- [Bazel Best Practices](https://bazel.build/basics/best-practices)

### Testing Frameworks

- [pytest Documentation](https://docs.pytest.org/)
- [Go Testing](https://golang.org/doc/tutorial/add-a-test)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Rust Testing](https://doc.rust-lang.org/book/ch11-00-testing.html)

### Code Quality

- [Ruff - Python Linter](https://docs.astral.sh/ruff/)
- [golangci-lint](https://golangci-lint.run/)
- [ESLint](https://eslint.org/)
- [Clippy - Rust Linter](https://github.com/rust-lang/rust-clippy)

### Security Tools

- [CodeQL](https://codeql.github.com/docs/)
- [Trivy](https://aquasecurity.github.io/trivy/)
- [Gitleaks](https://github.com/gitleaks/gitleaks)
- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/)

### Container & Kubernetes

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

### Infrastructure as Code

- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com/)

---

## 📚 Deep Dive Guides

For complete mastery of CI/CD in this repository, read these detailed guides:

| Topic               | Guide                                                                                                            | What You'll Learn                                                  |
| ------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **Workflows**       | [`../.doc/helpers/github/WORKFLOWS.md`](../.doc/helpers/github/WORKFLOWS.md)                                     | Every workflow explained, configuration patterns, troubleshooting  |
| **Pre-Commit & Linting** | [`../.doc/helpers/PRE_COMMIT_GUIDE.md`](../.doc/helpers/PRE_COMMIT_GUIDE.md)                              | 3-layer architecture, performance optimization, local development  |
| **Issue Templates** | [`../.doc/helpers/github/ISSUE_TEMPLATE.md`](../.doc/helpers/github/ISSUE_TEMPLATE.md)                           | How to use templates, best practices for reporters and maintainers |
| **Code Ownership**  | [`../.doc/helpers/github/CODEOWNERS.md`](../.doc/helpers/github/CODEOWNERS.md)                                   | Review process, ownership patterns, becoming a code owner          |
| **Funding**         | [`../.doc/helpers/github/FUNDING.md`](../.doc/helpers/github/FUNDING.md)                                         | Sponsorship options, benefits, transparency                        |
| **Pull Requests**   | [`../.doc/helpers/github/PULL_REQUEST_TEMPLATE_GUIDE.md`](../.doc/helpers/github/PULL_REQUEST_TEMPLATE_GUIDE.md) | Section-by-section PR guide, examples, best practices              |

---

## 🤝 Contributing to CI/CD

Want to improve our CI/CD pipeline? Here's how:

1. **Propose Changes**: Open an issue describing the improvement
2. **Test Locally**: Use [act](https://github.com/nektos/act) to test workflows locally
3. **Update Docs**: Document any changes
4. **Submit PR**: Follow our PR process

### Testing Workflows Locally

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run a workflow
act -j build

# Run with specific event
act push -e event.json
```

---

## 📊 Metrics & Monitoring

### Workflow Execution Times

- **Build**: ~5-10 minutes
- **Test**: ~10-15 minutes
- **Lint**: ~2-5 minutes
- **Security Scan**: ~5-10 minutes
- **Release**: ~15-20 minutes

### Success Rates

Monitor workflow success rates in the [Actions tab](../../actions).

Target: >95% success rate for all CI workflows

---

## 🔐 Security

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Email: [security contact to be added]

See [SECURITY.md](../doc/docs/SECURITY.md) for our security policy.

### Security Features

- ✅ Automated dependency scanning
- ✅ Secret detection (pre-commit and CI)
- ✅ CodeQL static analysis
- ✅ Container vulnerability scanning
- ✅ Supply chain security (SBOM generation)
- ✅ Signed commits and releases

---

## 📝 License

See [LICENSE.md](../doc/docs/LICENSE.md) for license information.

---

## 📮 Support

- 📖 Documentation: `/doc/docs/`
- 💬 Discussions: [GitHub Discussions](../../discussions)
- 🐛 Issues: [GitHub Issues](../../issues)
- 📧 Email: [contact to be added]

---

<div align="center">

**Made with ❤️ by the Rice Monorepo Team**

**100% Open Source | Zero Corporate Dependencies**

[Report Bug](../../issues/new?template=bug-report.yml) ·
[Request Feature](../../issues/new?template=feature-request.yml) ·
[Ask Question](../../issues/new?template=question.yml)

</div>
