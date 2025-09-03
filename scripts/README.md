# 📁 Scripts Directory

This directory contains all the scripts organized by functionality for the Chain Rice project.

## 📂 Directory Structure

```
scripts/
├── dev/              # Development environment scripts
├── platforms/        # Platform-specific build scripts
├── docker/           # Docker utility scripts
├── logs/             # Logging and monitoring scripts
├── utils/            # General utility scripts
└── tests/            # Testing scripts
```

## 🚀 Development Scripts (`dev/`)

- **`start-dev.sh`** - Complete development environment startup
- **`start-web.sh`** - Web frontend startup
- **`start-blockchain.sh`** - Blockchain service startup
- **`start-mobile.sh`** - Mobile development startup
- **`start-all.sh`** - All services startup

## 🏗️ Platform Scripts (`platforms/`)

- **`build-linux.sh`** - Build for Linux platforms (AMD64, ARM64)
- **`build-windows.sh`** - Build for Windows platforms (WSL2/Docker Desktop)
- **`build-mac.sh`** - Build for macOS platforms (Intel, Apple Silicon)
- **`build-all.sh`** - Build for all platforms

## 🐳 Docker Scripts (`docker/`)

- **`docker-helper.sh`** - Docker Compose operations (up, down, restart, logs, status)

## 📝 Logging Scripts (`logs/`)

- **`colored-logs.sh`** - Color-coded log viewing for different services

## 🛠️ Utility Scripts (`utils/`)

- **`open-interfaces.sh`** - Open all development interfaces in browser

## 🧪 Testing Scripts (`tests/`)

- **`run-tests.sh`** - Run all tests (Go, frontend, backend)

## 🎯 Usage

### Using Make Commands (Recommended)
```bash
make dev          # Start development environment
make linux        # Build for Linux
make windows      # Build for Windows
make mac          # Build for macOS
make logs         # View logs
make open         # Open interfaces
```

### Direct Script Usage
```bash
./scripts/dev/start-dev.sh
./scripts/platforms/build-linux.sh
./scripts/logs/colored-logs.sh
```

## 🔧 Adding New Scripts

When adding new scripts:

1. **Choose the right directory** based on functionality
2. **Make it executable**: `chmod +x script-name.sh`
3. **Add to Makefile** if it's a common operation
4. **Update this README** with the new script
5. **Follow naming conventions**: `kebab-case.sh`

## 📋 Script Guidelines

- Use `#!/bin/bash` shebang
- Include color output for better UX
- Add error handling with `set -e`
- Include help/usage information
- Use descriptive variable names
- Add comments for complex logic
