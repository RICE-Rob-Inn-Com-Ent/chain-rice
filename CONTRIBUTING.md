# Contributing to Rice-Dev

Thank you for your interest in contributing to the Rice-Dev ecosystem! This document provides guidelines and information for contributors.

## 🌟 How to Contribute

### Types of Contributions

We welcome several types of contributions:

- **🐛 Bug Reports** - Report issues and bugs
- **✨ Feature Requests** - Suggest new features or improvements
- **📚 Documentation** - Improve or add documentation
- **🔧 Code Contributions** - Submit code changes
- **🧪 Testing** - Add or improve tests
- **🎨 Design** - UI/UX improvements
- **🌍 Translations** - Help with internationalization

### Getting Started

1. **Fork the repository** on GitHub

2. **Clone your fork** locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/rice-dev.git
   cd rice-dev
   ```

3. **Set up the development environment**:

   ```bash
   make dev-setup
   ```

4. **Create a new branch** for your changes:

   ```bash
   git checkout -b feature/your-feature-name
   ```

## 🏗️ Project Structure

Understanding the Rice-Dev structure is crucial for effective contributions:

```text
rice-dev/
├── 📁 stacks/                    # Reusable technology templates
│   ├── 📁 backend/              # Backend language stacks
│   │   ├── 📁 golang/           # Go development stack
│   │   ├── 📁 python/           # Python development stack
│   │   ├── 📁 rust/             # Rust development stack
│   │   └── [other languages]    # Additional language stacks
│   ├── 📁 frontend/             # Frontend framework stacks
│   │   ├── 📁 typescript/       # TypeScript frameworks
│   │   │   ├── 📁 next/         # Next.js stack
│   │   │   ├── 📁 nuxt/         # Nuxt.js stack
│   │   │   └── 📁 angular/      # Angular stack
│   │   ├── 📁 dart/             # Flutter/Dart stack
│   │   ├── 📁 swift/            # Swift/iOS stack
│   │   └── 📁 kotlin/           # Kotlin/Android stack
│   └── 📁 tools/                # Development tools
│       ├── 📁 docker/            # Containerization tools
│       ├── 📁 terraform/         # Infrastructure as Code
│       ├── 📁 ansible/           # Configuration management
│       └── [other tools]         # Additional tools
├── 📁 apps/                      # Complete applications
│   ├── 📁 chain-rice/           # Blockchain accounting system
│   └── 📁 meowtopia/            # Cat cafe management system
└── 📁 [root files]              # Ecosystem orchestration
```

## 📝 Contribution Guidelines

### Code Style

- **Follow existing patterns** in the codebase
- **Use consistent naming conventions** for your language/framework
- **Add comments** for complex logic
- **Keep functions small** and focused
- **Write tests** for new functionality

### Documentation

- **Update README.md** files when adding new features
- **Add ARCHITECTURE.md** for new stacks or major components
- **Include examples** in documentation
- **Use clear, concise language**

### Commit Messages

Use clear, descriptive commit messages:

```bash
# Good examples
feat: add Docker support to Python stack
fix: resolve TypeScript compilation errors
docs: update Go stack README with examples
test: add unit tests for Rust modules

# Bad examples
fix stuff
update
changes
```

### Pull Request Process

1. **Ensure your changes work**:

   ```bash
   make test
   make build
   ```

2. **Update documentation** if needed

3. **Add tests** for new functionality

4. **Submit a pull request** with:
   - Clear description of changes
   - Reference to related issues
   - Screenshots (for UI changes)
   - Test results

## 🧱 Adding New Stacks

### Backend Language Stack

To add a new backend language stack:

```bash
# Create the stack directory
mkdir stacks/backend/your-language
cd stacks/backend/your-language

# Add required files
touch README.md ARCHITECTURE.md CONTRIBUTING.md CHANGELOG.md
touch Makefile
touch src/main.your-ext
touch tests/test.your-ext
```

**Required files:**

- `README.md` - Comprehensive documentation
- `ARCHITECTURE.md` - Technical architecture details
- `Makefile` - Build and development commands
- `src/` - Source code examples
- `tests/` - Test examples
- `CHANGELOG.md` - Version history

### Frontend Framework Stack

To add a new frontend framework:

```bash
# Create the stack directory
mkdir stacks/frontend/typescript/your-framework
cd stacks/frontend/typescript/your-framework

# Add framework-specific files
touch package.json
touch tsconfig.json
touch vite.config.ts  # or webpack.config.js
touch src/App.tsx
touch src/components/
```

**Required files:**

- `package.json` - Dependencies and scripts
- `README.md` - Setup and usage instructions
- `src/` - Example components and pages
- `tests/` - Testing examples
- Configuration files (TypeScript, bundler, etc.)

### Development Tool Stack

To add a new development tool:

```bash
# Create the tool directory
mkdir stacks/tools/your-tool
cd stacks/tools/your-tool

# Add tool-specific files
touch README.md
touch docker-compose.yml  # if applicable
touch config/your-tool.conf
touch scripts/setup.sh
```

## 🚀 Adding New Applications

To add a new complete application:

```bash
# Create the app directory
mkdir apps/your-app
cd apps/your-app

# Add application structure
mkdir frontend backend docs
touch README.md ARCHITECTURE.md
touch docker-compose.yml
touch Makefile
```

**Required structure:**

- `README.md` - Application overview and setup
- `ARCHITECTURE.md` - System architecture
- `frontend/` - Frontend application
- `backend/` - Backend services
- `docker-compose.yml` - Container orchestration
- `Makefile` - Development commands

## 🧪 Testing Guidelines

### Running Tests

```bash
# Run all tests
make test

# Run tests for specific stack
cd stacks/backend/golang
make test

# Run tests for specific app
cd apps/chain-rice
make test
```

### Writing Tests

- **Unit tests** for individual functions/modules
- **Integration tests** for component interactions
- **End-to-end tests** for complete workflows
- **Performance tests** for critical paths

### Test Coverage

- Aim for **80%+ coverage** for new code
- Include **edge cases** and error conditions
- Test **both success and failure** scenarios

## 📋 Issue Guidelines

### Bug Reports

When reporting bugs, include:

- **Environment details** (OS, versions, etc.)
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Screenshots or logs** if applicable
- **Minimal reproduction case** if possible

### Feature Requests

When requesting features, include:

- **Clear description** of the feature
- **Use case** and motivation
- **Proposed implementation** (if you have ideas)
- **Alternative solutions** considered
- **Additional context** or references

## 🔄 Development Workflow

### Daily Development

```bash
# Start development environment
make dev

# Check status of services
make status

# View logs
make logs

# Run tests
make test
```

### Before Submitting

```bash
# Clean and rebuild
make clean
make build

# Run all tests
make test

# Check code formatting
make format

# Run linting
make lint
```

## 🌍 Internationalization

Rice-Dev supports multiple languages. When contributing:

- **Use English** for code, comments, and documentation
- **Provide translations** for user-facing text
- **Follow i18n best practices** for your framework
- **Test with different locales**

## 📞 Getting Help

### Community Channels

- **GitHub Discussions** - General questions and discussions
- **GitHub Issues** - Bug reports and feature requests
- **Discord/Slack** - Real-time chat (if available)

### 📚 Documentation

- **README.md** files in each stack/app
- **ARCHITECTURE.md** files for technical details
- **CONTRIBUTING.md** files for contribution guidelines

## 🏆 Recognition

Contributors will be recognized in:

- **CONTRIBUTORS.md** file
- **Release notes** for significant contributions
- **GitHub contributors** page
- **Community highlights**

## 📄 License

By contributing to Rice-Dev, you agree that your contributions will be licensed under the same license as the project (MIT License).

## ✅ Quick Start Checklist

- [ ] Fork the repository
- [ ] Clone your fork locally
- [ ] Set up development environment (`make dev-setup`)
- [ ] Create a new branch for your changes
- [ ] Make your changes
- [ ] Add tests for new functionality
- [ ] Update documentation
- [ ] Run tests (`make test`)
- [ ] Submit a pull request

---

**Thank you for contributing to Rice-Dev!** 🚀

Your contributions help make this ecosystem better for developers worldwide. Every contribution, no matter how small, makes a difference.
