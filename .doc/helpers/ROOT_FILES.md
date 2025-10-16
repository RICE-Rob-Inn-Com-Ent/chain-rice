# 📄 Root Files Guide

Complete reference for all files in the repository root

---

## 📋 Table of Contents

- [Build & Package Management](#build--package-management)
- [Configuration Files](#configuration-files)
- [Documentation](#documentation)
- [Quick Reference](#quick-reference)

---

## Build & Package Management

### `MODULE.bazel`

**What**: Bazel module definition (Bzlmod)
**Purpose**: Define dependencies and toolchains for Bazel build system
**Docs**: <https://bazel.build/external/module>

**Supported Languages**:

- Python 3.11+ (rules_python)
- Rust 1.75+ (rules_rust)
- Node.js 20 (aspect_rules_js)
- Go 1.22 (rules_go)
- Kotlin/Android (rules_kotlin)
- Swift/iOS (rules_swift)
- Protocol Buffers (rules_proto)

**Usage**:

```bash
# Build everything
bazel build //...

# Test everything
bazel test //...
```

---

### `Makefile`

**What**: Build automation commands
**Purpose**: Simple interface for common development tasks
**Docs**: <https://www.gnu.org/software/make/manual/>

**Common Commands**:

```bash
make deps-install   # Install all dependencies
make deps-update    # Update all dependencies
make dev-start      # Start dev containers
make dev-stop       # Stop dev containers
make help           # Show available commands
```

---

## Configuration Files

### `taplo.toml`

**What**: TOML file formatter configuration
**Purpose**: Format and validate TOML files (Cargo.toml, pyproject.toml, etc.)
**Affects**: All `.toml` files in the repository
**Docs**: <https://taplo.tamasfe.dev/>

**Usage**:

```bash
# Format all TOML files
taplo format

# Check formatting
taplo check
```

---

### `sonar-project.properties`

**What**: SonarQube analysis configuration
**Purpose**: Static code analysis for bugs, security vulnerabilities, and code smells
**Affects**: Entire monorepo
**Docs**: <https://docs.sonarqube.org/latest/>

**Languages Analyzed**:

- JavaScript/TypeScript
- Python
- Go
- Java/Kotlin
- Rust

**Usage**:

```bash
# Run analysis
sonar-scanner
```

---

### `renovate.json`

**What**: Automated dependency updates configuration
**Purpose**: Keep dependencies up-to-date via automated pull requests
**Docs**: <https://docs.renovatebot.com/>

**Features**:

- Weekly dependency updates (Mondays 6am)
- Grouped by scope (frontend, backend, infrastructure)
- Auto-merge for non-major updates
- Security updates run immediately

**Configuration**: Fully automated via Renovate bot

---

### `rice-dev.code-workspace`

**What**: VS Code multi-root workspace configuration
**Purpose**: Organize monorepo into logical workspace folders (sorted by usage frequency)
**Docs**: <https://code.visualstudio.com/docs/editor/multi-root-workspaces>

**Workspaces** (ordered by priority):

**High Priority** (daily development):

- 🌍 ROOT - Repository root (always first)
- ⚙️ BACKEND - Smart contracts & services
- 💻 FRONTEND - Web & mobile apps
- 🐍 BOT - Python automation (AI integrations)

**Medium Priority** (regular updates):

- 📋 SCHEMA - Protocol Buffer definitions
- 📚 DOC - Documentation

**Low Priority** (occasional access):

- 🐳 CONTAINER - Docker & devcontainer
- 🛠️ INFRA - Infrastructure as Code (Terraform, K8s, Ansible)
- ⚡ CI/CD - GitHub workflows
- 🔧 IDE - VS Code settings

**Usage**: Open `rice-dev.code-workspace` in VS Code or Cursor

---

## Documentation

### `README.md`

**What**: Project documentation homepage
**Purpose**: Introduction, quick links, getting started guide
**Format**: Markdown

**Sections**:

- Technology stack overview
- Quick navigation to key resources
- Learning paths for different roles
- Getting started guide
- Links to detailed documentation

---

## Quick Reference

### 🚀 Common Tasks

| Task                      | Command             |
| ------------------------- | ------------------- |
| **Install dependencies**  | `make deps-install` |
| **Update dependencies**   | `make deps-update`  |
| **Start dev environment** | `make dev-start`    |
| **Stop dev environment**  | `make dev-stop`     |
| **Build with Bazel**      | `bazel build //...` |
| **Test with Bazel**       | `bazel test //...`  |
| **Format TOML files**     | `taplo format`      |
| **Run code analysis**     | `sonar-scanner`     |

---

### 📚 File Categories

| Category               | Files                      | Purpose            |
| ---------------------- | -------------------------- | ------------------ |
| **Build System**       | `MODULE.bazel`, `Makefile` | Build automation   |
| **Code Quality**       | `sonar-project.properties` | Static analysis    |
| **Package Management** | `renovate.json`            | Dependency updates |
| **Formatting**         | `taplo.toml`               | TOML formatting    |
| **Workspace**          | `rice-dev.code-workspace`  | VS Code setup      |
| **Documentation**      | `README.md`                | Project overview   |

---

### 🔗 Official Documentation Links

- **Bazel**: <https://bazel.build/>
- **Make**: <https://www.gnu.org/software/make/>
- **Renovate**: <https://docs.renovatebot.com/>
- **SonarQube**: <https://docs.sonarqube.org/>
- **Taplo**: <https://taplo.tamasfe.dev/>
- **VS Code Workspaces**: <https://code.visualstudio.com/docs/editor/multi-root-workspaces>

---

### 💡 Tips

1. **First Time Setup**:

   ```bash
   make deps-install
   make dev-start
   ```

2. **Daily Development**:

   ```bash
   # Start your day
   make dev-start

   # Work on code...

   # Stop at end of day
   make dev-stop
   ```

3. **Before Committing**:

   ```bash
   # Format TOML files
   taplo format

   # Commit your changes
   git add .
   git commit -m "feat(scope): your changes"
   ```

4. **Keep Dependencies Updated**:

   ```bash
   # Renovate bot creates PRs automatically
   # Or manually update:
   make deps-update
   ```

---

### 🆘 Troubleshooting

**Problem**: Bazel build fails
**Solution**: Run `bazel clean --expunge` and rebuild

**Problem**: Make commands not working
**Solution**: Check if you have GNU Make installed: `make --version`

**Problem**: SonarQube analysis fails
**Solution**: Ensure SonarQube server is running and credentials are set

---

Built with ❤️ by the Rice-Dev team

Last updated: October 2025
