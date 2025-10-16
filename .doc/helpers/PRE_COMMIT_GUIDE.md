# 💎 Pre-Commit Configuration Guide

## Overview

Rice Monorepo uses a **billion-dollar enterprise-grade pre-commit configuration** supporting all languages and
frameworks in the monorepo.

## Supported Languages & Tools

### 🐍 Python (.bot/)

- **Black** - Code formatter (PEP 8)
- **Ruff** - Ultra-fast linter (10-100x faster than Flake8)
- **isort** - Import organizer
- **mypy** - Static type checker

### 🔵 Go (.backend/db/, .backend/token/)

- **gofmt** - Standard Go formatter
- **goimports** - Import organizer
- **go vet** - Go code analyzer
- **go mod tidy** - Module cleanup

### 🦀 Rust (.backend/contract/rust/)

- **rustfmt** - Rust formatter
- **clippy** - Rust linter

### ✨ JavaScript/TypeScript (.frontend/web/)

- **Prettier** - Code formatter
- **ESLint** - Linter with TypeScript support

### ⛓️ Solidity (.backend/contract/solidity/)

- **solhint** - Solidity linter

### 🎯 Dart/Flutter (.frontend/flutter/)

- **dart format** - Dart formatter
- **flutter analyze** - Static analyzer

### 📦 Protocol Buffers (.schema/)

- **buf format** - Protobuf formatter
- **buf lint** - Protobuf linter

### 🏗️ Infrastructure

- **Terraform** - fmt, validate, tflint
- **Kubernetes/Helm** - helm lint
- **Bazel** - buildifier
- **Docker** - hadolint

### 📝 Documentation & Config

- **Markdown** - markdownlint
- **YAML** - yamllint
- **TOML** - pretty-format-toml
- **EditorConfig** - compliance checker

### 🔒 Security & Quality

- **detect-secrets** - Secret scanner
- **codespell** - Spell checker
- **conventional-commits** - Commit message format

## Quick Start

### Install Pre-Commit Hooks

```bash
# Using make
make pre-commit-install

# Or directly
pre-commit install --install-hooks --hook-type pre-commit --hook-type commit-msg
```

### Run on Staged Files

```bash
# Using make
make pre-commit-run

# Or directly
pre-commit run
```

### Run on All Files

```bash
# Using make (WARNING: slow on large monorepo)
make pre-commit-run-all

# Or directly
pre-commit run --all-files
```

### Update Hook Versions

```bash
# Using make
make pre-commit-update

# Or directly
pre-commit autoupdate
```

### Clean Cache

```bash
# Using make
make pre-commit-clean

# Or directly
pre-commit clean && rm -rf ~/.cache/pre-commit
```

## Bypass Pre-Commit (Use Sparingly)

### Skip for One Commit

```bash
git commit --no-verify -m "message"
# or shorter
git commit -n -m "message"
```

### Skip Specific Hooks

```bash
SKIP=markdownlint,detect-secrets git commit -m "message"
```

### Temporarily Disable

```bash
# Disable
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled

# Re-enable
mv .git/hooks/pre-commit.disabled .git/hooks/pre-commit
```

## Commit Message Format

### Conventional Commits

Format: `<type>(<scope>): <subject>`

**Types:**

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Code style/formatting
- `refactor` - Code refactoring
- `perf` - Performance improvement
- `test` - Tests
- `build` - Build system
- `ci` - CI/CD changes
- `chore` - Maintenance
- `security` - Security fixes

**Scopes (examples):**

- `backend/db`
- `backend/token`
- `backend/contract/rust`
- `backend/contract/solidity`
- `bot/core`
- `bot/integration`
- `frontend/flutter`
- `frontend/web/angular`
- `frontend/web/next`
- `schema/token`
- `dev/terraform`
- `dev/k8s`
- `config`
- `ci`

**Examples:**

```bash
git commit -m "feat(backend/token): add token transfer endpoint"
git commit -m "fix(bot/core): resolve import error in main.py"
git commit -m "docs(readme): update installation instructions"
git commit -m "ci(github/workflows): add Python test workflow"
```

## What Gets Checked?

### ✅ Always Checked

- Your source code in `.backend/`, `.frontend/`, `.bot/`, `.schema/`
- Configuration files (`.yaml`, `.json`, `.toml`)
- Scripts (`.sh`, `.bash`)
- Documentation (`.md`)

### 🚫 Always Excluded

- `node_modules/`, `dist/`, `build/`, `target/`
- `vendor/`, `deps/`, `bazel-*/`
- `connection/BEAM/deps/` (Erlang vendor)
- `connection/.NET/obj/` (.NET build)
- `.schema/token/third_party/` (vendor proto)
- Lock files (`*.lock`, `go.sum`, `package-lock.json`)
- Generated files (`*_pb.*`, `*.generated.*`)
- Minified files (`*.min.js`, `*.min.css`)

## Troubleshooting

### Hook Fails with "File was modified"

This is **normal** - the hook auto-fixed your code. Just:

```bash
git add -u  # Stage the fixes
git commit  # Commit again
```

### "InvalidManifestError" or Cache Issues

```bash
make pre-commit-clean
make pre-commit-install
```

### Pre-Commit is Too Slow

For **mass changes** or **vendor updates**, bypass it:

```bash
git commit --no-verify -m "chore: mass refactor"
```

Then run manually on small batches:

```bash
pre-commit run --files src/file1.py src/file2.py
```

### Specific Hook Keeps Failing

Skip it temporarily:

```bash
SKIP=problematic-hook git commit -m "message"
```

Or disable permanently in `.pre-commit-config.yaml`:

```yaml
- id: problematic-hook
  # ... config ...
  exclude: .* # Disables for all files
```

## Performance Tips

### 1. Use `make` commands

They're optimized and user-friendly.

### 2. Commit frequently

Smaller commits = faster pre-commit runs.

### 3. Use `--no-verify` for

- Mass refactors (1000+ files)
- Vendor/dependency updates
- Generated code commits
- Emergency hotfixes

### 4. Clean cache periodically

```bash
make pre-commit-clean
```

## What Makes This Config "Billion Dollar"?

✅ **26+ tools** integrated seamlessly ✅ **8 programming languages** supported ✅ **Smart excludes** - skips
vendor/generated files ✅ **Fast** - only checks what matters ✅ **Emoji indicators** - easy to read output ✅ **CI/CD
ready** - pre-commit.ci configured ✅ **Conventional commits** - enforces good git history ✅ **Security first** -
secret detection enabled ✅ **Monorepo optimized** - per-directory targeting ✅ **Auto-fix** - most issues fixed
automatically

## CI/CD Integration

The same hooks run in GitHub Actions:

- `.github/workflows/ci-lint.yml` - Runs pre-commit on PRs
- `.github/workflows/ci-format.yml` - Checks formatting
- **pre-commit.ci** - Automatic PR fixes

## Advanced Usage

### Run Specific Hook

```bash
pre-commit run black --all-files
pre-commit run ruff --files .bot/core/main.py
```

### Debug Hook

```bash
pre-commit run hook-name --verbose --files path/to/file
```

### Manual Hook Installation

```bash
pre-commit install --hook-type pre-push
pre-commit install --hook-type pre-merge-commit
```

### Environment Variables

```bash
# Skip all hooks
SKIP=all git commit -m "message"

# Skip multiple hooks
SKIP=black,ruff,mypy git commit -m "message"

# Run even if no files match
PRE_COMMIT_ALLOW_NO_CONFIG=1 pre-commit run
```

## Files Structure

```text
.
├── .pre-commit-config.yaml    # Main configuration
├── .commitlintrc.js           # Commit message rules
├── .markdownlint.json         # Markdown linter config
├── .yamllint                  # YAML linter config
├── .editorconfig              # Editor config
├── .secrets.baseline          # Allowed "secrets"
├── .bot/
│   ├── ruff.toml              # Ruff configuration
│   └── pyproject.toml         # Python tools config
├── .backend/
│   └── .golangci.yml          # Go linter (CI/CD only)
└── .frontend/web/
    └── .eslintrc.js           # ESLint configuration
```

## Common Issues & Solutions

### Issue: "unknown variant 'concise'" (Ruff)

**Solution:** Already fixed - uses `grouped` format

### Issue: "py313 is not one of..." (Black)

**Solution:** Already fixed - uses `py312` as target

### Issue: Too many markdown warnings

**Solution:** Markdownlint is configured with relaxed rules

### Issue: False positive secrets detected

**Solution:** Add to `.secrets.baseline`:

```bash
detect-secrets scan --baseline .secrets.baseline
```

### Issue: Pre-commit modifying vendor files

**Solution:** Already excluded via global `exclude` pattern

## Support

- **Documentation:** `.doc/helpers/`
- **Issues:** `.github/issue_template/`
- **Slack:** #dev-tooling

---

**Made with 💎 for Rice Monorepo** | Last updated: October 2025
