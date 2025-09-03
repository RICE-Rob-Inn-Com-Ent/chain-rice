# 🚀 Chain Rice Quick Start Guide

Get up and running with Chain Rice in under 5 minutes!

## 📋 Prerequisites

- **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop/)
- **Git** - [Download here](https://git-scm.com/downloads)
- **Make** - Usually pre-installed on Linux/macOS, [install for Windows](https://chocolatey.org/)

## ⚡ Quick Start

1. **Clone and start**
   ```bash
   git clone <repository-url>
   cd chain-rice
   make dev
   ```

2. **Access the application**
   - **Web App**: http://localhost:3000
   - **API Docs**: http://localhost:8000/docs
   - **Blockchain**: http://localhost:1317

3. **Open all interfaces**
   ```bash
   make open
   ```

## 🛠️ Essential Commands

```bash
make dev          # Start everything
make status       # Check if services are running
make logs         # View logs
make down         # Stop everything
make help         # Show all commands
```

## 🆘 Need Help?

- **Full Documentation**: [README.md](README.md)
- **Development Guide**: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- **Troubleshooting**: See README.md troubleshooting section

## 🎯 What's Included

- ✅ **Web Frontend** - React + Vite + Tailwind CSS
- ✅ **Backend API** - FastAPI + Python
- ✅ **Blockchain** - Cosmos SDK + Tendermint
- ✅ **Database** - PostgreSQL
- ✅ **Cross-Platform** - Works on Windows, macOS, Linux

Happy coding! 🎉
