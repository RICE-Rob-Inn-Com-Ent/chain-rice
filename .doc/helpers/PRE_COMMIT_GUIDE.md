# 💎 Pre-Commit & CI/CD Linting Guide

## Overview

Rice Monorepo uses a **three-layer quality assurance** strategy for optimal developer experience:

1. **VSCode Extensions** → Real-time linting while coding
2. **Pre-Commit Hooks** → Fast auto-fix formatting (~1-2 seconds)
3. **CI/CD Pipeline** → Comprehensive linting before merge (~3-5 minutes)

## Architecture

```text
┌─────────────────────────────────────────────────────────┐
│ LAYER 1: VSCode Extensions (Real-time)                 │
├─────────────────────────────────────────────────────────┤
│ • Pylance, Ruff, ESLint, rust-analyzer                 │
│ • Instant feedback while typing                        │
│ • Configured via .vscode/settings.json                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ LAYER 2: Pre-Commit (~1-2 seconds)                     │
├─────────────────────────────────────────────────────────┤
│ • Auto-fix formatting (Black, Prettier, gofmt, etc.)   │
│ • Basic syntax checks (YAML, JSON, TOML)               │
│ • Security scanning (detect-secrets)                   │
│ • NO heavy linting (Ruff, ESLint, mypy, clippy, etc.)  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ LAYER 3: CI/CD (3-5 minutes)                           │
├─────────────────────────────────────────────────────────┤
│ • ALL linters: Ruff, ESLint, Clippy, golangci-lint     │
│ • Type checking: mypy, TSC                             │
│ • Security: Bandit, Slither, tfsec, cargo-deny         │
│ • Breaking changes: buf breaking, dependency-review    │
└─────────────────────────────────────────────────────────┘
```

## Pre-Commit Hooks (Fast Layer)

### What Runs Locally (~1-2 seconds)

✅ **File Cleanup**
- Trim trailing whitespace
- Fix end-of-file newlines
- Fix line endings (LF)
- Check merge conflicts
- Check large files

✅ **Formatting Only** (NO linting)
- 🐍 Python: `black`, `isort`
- 🔵 Go: `gofmt`, `goimports`
- 🦀 Rust: `rustfmt`
- ✨ JS/TS: `prettier`
- 🐚 Shell: `shfmt`
- 🏗️ Bazel: `buildifier`

✅ **Basic Syntax Validation**
- YAML, JSON, TOML syntax
- No deep validation

✅ **Security & Git**
- Secret detection (detect-secrets)
- Conventional commits
- Branch protection

### What Does NOT Run (Runs in CI/CD)

❌ **Heavy Linters** (too slow)
- Ruff, ESLint, Clippy, golangci-lint, solhint
- mypy, TSC type checking
- Markdown, YAML deep linting

❌ **Security Scanners** (too slow)
- Bandit, Slither, tfsec, cargo-deny

❌ **Breaking Change Detection**
- buf breaking, dependency-review

## CI/CD Linting (Comprehensive Layer)

### 14 Parallel Jobs

All linters run in GitHub Actions on `push` and `pull_request`:

| Job | Tools | Languages |
|-----|-------|-----------|
| 🐍 Python | Ruff, Black, isort, mypy, Bandit | `.bot/**/*.py` |
| 🔵 Go | golangci-lint, go vet, staticcheck | `.backend/**/*.go` |
| ✨ TypeScript | ESLint, Prettier, TSC | `.frontend/web/**/*.ts` |
| 🦀 Rust | Clippy, rustfmt, cargo-deny | `.backend/contract/rust/**/*.rs` |
| ⛓️ Solidity | solhint, Prettier, Slither | `.backend/contract/solidity/**/*.sol` |
| 🎯 Dart/Flutter | flutter analyze, dart format | `.frontend/flutter/**/*.dart` |
| 📦 Protobuf | buf lint, buf format, buf breaking | `.schema/**/*.proto` |
| 🏗️ Terraform | tflint, tfsec, terraform validate | `.dev/terraform/**/*.tf` |
| 📝 Markdown | markdownlint | `**/*.md` |
| 📋 YAML | yamllint | `**/*.{yaml,yml}` |
| 🐳 Docker | hadolint | `**/Dockerfile*` |
| 🐚 Shell | ShellCheck | `**/*.sh` |
| 🏗️ Bazel | buildifier | `**/*.{bazel,bzl}` |
| 📖 Spelling | codespell | All text files |

### Additional Checks

- 💬 **Commitlint** - Conventional commits enforcement
- ⚖️ **License** - License header compliance
- 🔍 **Dependency Review** - Vulnerability & license scanning

## Quick Start

### Install Pre-Commit Hooks

```bash
# Using make (recommended)
make pre-commit-install

# Or directly
pre-commit install --install-hooks --hook-type pre-commit --hook-type commit-msg
```

### Daily Usage

```bash
# Normal commit - auto-formatting applied (~1s)
git add .
git commit -m "feat(backend/token): add transfer endpoint"

# Pre-commit will:
# ✅ Auto-fix formatting (Black, Prettier, gofmt, etc.)
# ✅ Check syntax (YAML, JSON)
# ✅ Scan for secrets
# ✅ Validate commit message format
```

### Run Manually

```bash
# Run on staged files only
make pre-commit-run

# Run on all files (slower, ~10-30s for whole repo)
make pre-commit-run-all

# Run specific hook
pre-commit run black --all-files
```

## Bypassing Pre-Commit

### When to Skip

Use `--no-verify` for:
- 🔄 Mass refactors (1000+ files)
- 📦 Vendor/dependency updates
- 🤖 Generated code commits
- 🔥 Emergency hotfixes
- 🚧 WIP commits to feature branch

### How to Skip

```bash
# Skip all hooks for one commit
git commit --no-verify -m "message"
# or
git commit -n -m "message"

# Skip specific hooks
SKIP=detect-secrets,black git commit -m "message"

# Skip all hooks temporarily
SKIP=all git commit -m "message"
```

## CI/CD Pipeline

### Triggers

```yaml
# Runs on:
- Push to: main, dev, v.*
- Pull requests to: main, dev
- Merge queue
```

### Viewing Results

1. **GitHub Actions tab** - See all 14 jobs
2. **PR Checks** - Status badges on PR
3. **Step Summary** - Beautiful table with results

### Local Testing (Before Push)

```bash
# Run specific linter locally
cd .bot && ruff check .
cd .backend/db && golangci-lint run
cd .frontend/web && npm run lint

# Or use act to run GitHub Actions locally
act -j python-lint
```

## Commit Message Format

### Conventional Commits

Format: `<type>(<scope>): <subject>`

#### Types

- `feat` - New feature ✨
- `fix` - Bug fix 🐛
- `docs` - Documentation 📚
- `style` - Formatting 💎
- `refactor` - Code refactoring 📦
- `perf` - Performance 🚀
- `test` - Tests 🧪
- `build` - Build system 🛠
- `ci` - CI/CD ⚙️
- `chore` - Maintenance ♻️
- `security` - Security 🔒
- `deps` - Dependencies 📦

#### Scopes (examples)

```text
backend/db
backend/token
backend/contract/rust
backend/contract/solidity
bot/core
bot/integration
frontend/flutter
frontend/web/angular
frontend/web/next
schema/token
dev/terraform
dev/k8s
config
ci
```

#### Examples

```bash
git commit -m "feat(backend/token): add transfer validation"
git commit -m "fix(bot/core): resolve import circular dependency"
git commit -m "docs(readme): update installation steps"
git commit -m "ci(github/workflows): optimize lint pipeline"
git commit -m "chore(deps): update Rust dependencies"
```

## Performance Comparison

### Before (Full Linting in Pre-Commit)

```text
⏱️  30-60 seconds per commit
😫 Frustrating developer experience
🐌 Slow feedback loop
❌ Often bypassed with --no-verify
```

### After (Minimal Pre-Commit + CI/CD)

```text
⚡ 1-2 seconds per commit
😊 Great developer experience
🚀 Fast feedback loop
✅ Rarely bypassed
💪 Comprehensive validation in CI/CD
```

## What Gets Checked Where?

### ⚡ Pre-Commit (1-2s)

```text
✅ Formatting (auto-fix)
✅ Basic syntax
✅ Secrets
✅ Commit format
❌ NO linting
❌ NO type checking
❌ NO complex validation
```

### 🔍 CI/CD (3-5min)

```text
✅ ALL linters
✅ Type checking
✅ Security scanning
✅ Breaking changes
✅ License compliance
✅ Dependency review
```

### 💡 VSCode (Real-time)

```text
✅ Instant feedback
✅ Auto-complete
✅ Inline errors
✅ Quick fixes
```

## Troubleshooting

### Pre-Commit Fails with "File was modified"

This is **normal** - the hook auto-fixed your code:

```bash
git add -u  # Stage the auto-fixes
git commit  # Commit again
```

### Pre-Commit is Still Slow

Check if you're running on vendor files:

```bash
# Should be excluded already, but verify
pre-commit run --verbose --files path/to/file
```

### CI/CD Lint Job Fails

1. **Run locally first:**

```bash
# Python
cd .bot && ruff check . && mypy core

# Go
cd .backend/db && golangci-lint run

# TypeScript
cd .frontend/web && npm run lint
```

2. **Check workflow logs** in GitHub Actions
3. **Fix locally** and push again

### "InvalidManifestError" or Cache Issues

```bash
make pre-commit-clean
make pre-commit-install
```

### Secrets Detected (False Positive)

Add to `.secrets.baseline`:

```bash
detect-secrets scan --baseline .secrets.baseline
git add .secrets.baseline
git commit -m "chore(security): update secrets baseline"
```

## Advanced Usage

### Run Single Hook

```bash
pre-commit run black --all-files
pre-commit run prettier --files .frontend/web/src/main.ts
```

### Skip Commit-Msg Hook

```bash
git commit --no-verify -m "message"
```

### Disable Temporarily

```bash
# Disable
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled

# Re-enable
mv .git/hooks/pre-commit.disabled .git/hooks/pre-commit
```

### Environment Variables

```bash
# Skip specific hooks
SKIP=black,ruff git commit -m "message"

# Skip all
SKIP=all git commit -m "message"

# Verbose output
PRE_COMMIT_VERBOSE=1 git commit
```

## Files Structure

```text
.
├── .pre-commit-config.yaml    # Minimal fast hooks
├── .commitlintrc.js           # Commit message rules
├── .markdownlint.json         # Markdown config
├── .yamllint                  # YAML config
├── .editorconfig              # Editor config
├── .secrets.baseline          # Allowed "secrets"
├── .github/workflows/
│   └── ci-lint.yml            # 14 comprehensive lint jobs
├── .bot/
│   ├── ruff.toml              # Ruff configuration
│   └── pyproject.toml         # Python tools
├── .backend/
│   └── .golangci.yml          # Go linter config
└── .frontend/web/
    └── .eslintrc.js           # ESLint config
```

## Makefile Commands

```bash
make pre-commit-install     # Install hooks
make pre-commit-run         # Run on staged files
make pre-commit-run-all     # Run on all files (slow)
make pre-commit-update      # Update hook versions
make pre-commit-clean       # Clean cache
make pre-commit-uninstall   # Remove hooks
```

## Best Practices

### ✅ Do

- Commit frequently (smaller = faster)
- Let pre-commit auto-fix formatting
- Use VSCode extensions for real-time feedback
- Review CI/CD logs when linting fails
- Update `.secrets.baseline` when adding test data

### ❌ Don't

- Skip pre-commit for normal commits
- Ignore CI/CD lint failures
- Commit vendor/generated files
- Use `--no-verify` as default

## What Makes This Setup Special?

✅ **Ultra-fast pre-commit** (~1-2s, not 30-60s)
✅ **Comprehensive CI/CD** (14 parallel jobs)
✅ **Real-time VSCode feedback**
✅ **Smart excludes** (vendor, deps, generated)
✅ **14 languages/tools supported**
✅ **Auto-fix enabled** (most issues fixed automatically)
✅ **Security-first** (secrets, dependencies, licenses)
✅ **Conventional commits** (clean git history)
✅ **Beautiful output** (emojis, colors, summaries)
✅ **Developer-friendly** (rarely need --no-verify)

## CI/CD Jobs Details

### 🐍 Python Job

```yaml
- Ruff: Lint + format check
- Black: Format check
- isort: Import check
- mypy: Type checking
- Bandit: Security scanning
```

### 🔵 Go Job (Matrix: db, token)

```yaml
- golangci-lint: 50+ linters
- go vet: Code analysis
- staticcheck: Additional checks
```

### ✨ TypeScript Job

```yaml
- ESLint: Lint all TS/JS
- Prettier: Format check
- TSC: Type checking (--noEmit)
```

### 🦀 Rust Job

```yaml
- rustfmt: Format check
- Clippy: Lint with -D warnings
- cargo-deny: License & security
```

### ⛓️ Solidity Job

```yaml
- solhint: Lint smart contracts
- Prettier: Format check
- Slither: Security analysis
```

### 🎯 Dart/Flutter Job

```yaml
- flutter analyze: Static analysis
- dart format: Format check
```

### 📦 Protobuf Job

```yaml
- buf lint: Style & best practices
- buf format: Format check
- buf breaking: API breaking changes
```

### 🏗️ Terraform Job

```yaml
- terraform fmt: Format check
- terraform validate: Config validation
- tflint: Linting
- tfsec: Security scanning
```

## Migration from Old Config

### What Changed?

**Old Pre-Commit (26 tools, 30-60s):**
- ❌ Heavy linting in pre-commit
- ❌ Type checking in pre-commit
- ❌ Slow developer experience
- ❌ Often bypassed

**New Pre-Commit (11 tools, 1-2s):**
- ✅ Only auto-fix formatting
- ✅ Basic syntax checks
- ✅ Lightning fast
- ✅ Rarely bypassed
- ✅ Heavy linting in CI/CD

### Upgrade Steps

Already done! Just:

```bash
make pre-commit-clean
make pre-commit-install
```

## Monitoring & Reports

### GitHub Actions

- **Summary page** - Beautiful table with all results
- **Artifacts** - Bandit security reports
- **PR comments** - Automatic feedback
- **Status checks** - Must pass before merge

### Local Reports

```bash
# Generate coverage report
cd .bot && pytest --cov --cov-report=html

# Run security scan
cd .bot && bandit -r core integration -f html -o report.html
```

## Support & Help

- **Documentation:** `.doc/helpers/`
- **Issues:** `.github/issue_template/`
- **CI/CD Logs:** GitHub Actions tab
- **VSCode Problems:** View → Problems panel

---

**Made with 💎 for Rice Monorepo**
**Developer Experience First** | **Speed Meets Quality**
Last updated: October 2025
