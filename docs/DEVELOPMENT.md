# 🚀 Chain Rice Development Guide

This guide will help you set up and run the Chain Rice development environment on any platform.

## 📋 Prerequisites

### Required Software

- **Docker Desktop** (latest version)
  - [Download for Windows](https://www.docker.com/products/docker-desktop/)
  - [Download for macOS](https://www.docker.com/products/docker-desktop/)
  - [Install for Linux](https://docs.docker.com/engine/install/)

- **Git** (for version control)
  - [Download Git](https://git-scm.com/downloads)

- **Make** (for running commands)
  - **Windows**: Install via [Chocolatey](https://chocolatey.org/) or [WSL](https://docs.microsoft.com/en-us/windows/wsl/)
  - **macOS**: Install via [Homebrew](https://brew.sh/) or Xcode Command Line Tools
  - **Linux**: Usually pre-installed, or install via package manager

### Platform-Specific Setup

#### Windows
1. Install Docker Desktop
2. Enable WSL2 backend in Docker Desktop settings
3. Install WSL2 if not already installed
4. Install Make via Chocolatey: `choco install make`

#### macOS
1. Install Docker Desktop
2. Install Make via Homebrew: `brew install make`
3. For Apple Silicon Macs, ensure Docker Desktop supports ARM64

#### Linux
1. Install Docker Engine
2. Install Docker Compose
3. Add your user to docker group: `sudo usermod -aG docker $USER`
4. Log out and back in

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd chain-rice
```

### 2. Start Development Environment
```bash
make dev
```

This command will:
- Build all Docker images
- Start all services (frontend, backend, database, blockchain)
- Display service URLs and useful commands

### 3. Access the Application
- **Web Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Blockchain API**: http://localhost:1317

## 🛠️ Available Commands

### Development Commands
```bash
make dev          # Start complete development environment
make up           # Start services
make down         # Stop services
make restart      # Restart services
make logs         # View colored logs
make status       # Show service status
make open         # Open all development interfaces
```

### Platform-Specific Build Commands
```bash
make linux        # Build for Linux platforms
make windows      # Build for Windows platforms
make mac          # Build for macOS platforms
make build-all    # Build for all platforms
```

### Testing Commands
```bash
make test         # Run Go tests
make test-unit    # Run unit tests
make test-race    # Run tests with race detection
make lint         # Run linter
```

## 🐳 Docker Services

The development environment includes:

- **Frontend** (React + Vite): Port 3000
- **Backend** (FastAPI): Port 8000
- **Database** (PostgreSQL): Port 5432
- **Blockchain** (Cosmos SDK): Ports 26656, 26657, 1317

## 🔧 Troubleshooting

### Common Issues

#### Docker Not Running
```bash
# Check Docker status
docker info

# Start Docker Desktop (Windows/macOS)
# Or start Docker service (Linux)
sudo systemctl start docker
```

#### Port Already in Use
```bash
# Check what's using the port
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Stop conflicting services or change ports in docker-compose.yml
```

#### Permission Issues (Linux)
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker
```

#### Build Failures
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache
```

### Platform-Specific Issues

#### Windows
- Ensure WSL2 is enabled in Docker Desktop
- Run commands in WSL2 terminal or PowerShell
- Check Windows Defender firewall settings

#### macOS
- For Apple Silicon Macs, ensure Docker Desktop supports ARM64
- Check Docker Desktop resource allocation
- Ensure sufficient disk space

#### Linux
- Ensure Docker daemon is running
- Check user permissions for Docker
- Verify Docker Compose version compatibility

## 📁 Project Structure

```
chain-rice/
├── scripts/
│   ├── dev/              # Development scripts
│   ├── platforms/        # Platform-specific builds
│   ├── docker/           # Docker utilities
│   ├── logs/             # Logging utilities
│   ├── utils/            # General utilities
│   └── tests/            # Testing scripts
├── meowtopia/
│   ├── frontend/web/     # React frontend
│   └── backend/          # FastAPI backend
├── app/                  # Go blockchain application
├── docker-compose.yml    # Docker services configuration
└── Makefile             # Build and development commands
```

## 🎯 Development Workflow

1. **Start Development Environment**
   ```bash
   make dev
   ```

2. **Make Changes**
   - Edit frontend code in `meowtopia/frontend/web/`
   - Edit backend code in `meowtopia/backend/`
   - Edit blockchain code in `app/`

3. **View Logs**
   ```bash
   make logs
   ```

4. **Test Changes**
   ```bash
   make test
   ```

5. **Stop Environment**
   ```bash
   make down
   ```

## 🔗 Useful Links

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Make Documentation](https://www.gnu.org/software/make/manual/)
- [Cosmos SDK Documentation](https://docs.cosmos.network/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://reactjs.org/docs/)

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Docker and service logs: `make logs`
3. Check service status: `make status`
4. Try rebuilding: `make build-all`
5. Create an issue in the repository

Happy coding! 🎉
