# 🏆 Rice-Mono - Enterprise Monorepo

**Enterprise-grade polyglot monorepo** with complete tooling for 15+ languages

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](.doc/docs/LICENSE.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](.doc/docs/CONTRIBUTING.md)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

---

## 🚀 Quick Start

### For New Developers

Complete setup in one command:

```bash
make prepare
```

This will:
1. ✅ Install **asdf** version manager (if not installed)
2. ✅ Install all **asdf plugins** (Rust, Go, Node.js, Python, Java, etc.)
3. ✅ Install **all tools** from `.tool-versions` (40+ tools)
4. ✅ Install **all project dependencies** (npm, cargo, poetry, flutter, etc.)
5. ✅ Setup **pre-commit hooks** for code quality

**Time:** ~15-30 minutes (downloads & compiles everything)

### Alternative: Manual Setup

```bash
# 1. Install asdf (if not already installed)
make asdf-install

# 2. Install all tools from .tool-versions
make asdf-plugins

# 3. Install project dependencies
make deps-install

# 4. Install pre-commit hooks
make pre-commit-install

# 5. Start development environment
make dev-start
```

### Verify Installation

```bash
# Check installed tools
asdf list

# Check project help
make help
```

---

## 📚 Documentation

### 🎯 **START HERE**

- **[📄 ROOT_FILES.md](.document/helpers/ROOT_FILES.md)** - Complete guide to all files in repository root
- **[📁 ROOT_FOLDERS.md](.document/helpers/ROOT_FOLDERS.md)** - Complete guide to all folders in repository root
