# Rice-Mono Ultimate Development Environment

## 🚀 Overview

This is the **ULTIMATE OPEN SOURCE DEVELOPMENT ENVIRONMENT** - a comprehensive devcontainer setup with:

- ✅ **200+ Development Tools** - Every language, framework, and tool you'll ever need
- ✅ **15+ Services** - Complete infrastructure stack (databases, queues, monitoring, etc.)
- ✅ **100% Open Source** - Zero proprietary/corporate dependencies
- ✅ **Production-Ready** - Enterprise-grade tools and best practices
- ✅ **Million Dollar Per Hour Dev** - Work with any technology stack instantly

## 📋 What's Included

### Languages & Runtimes

- **Systems**: Rust, Go, Zig, Nim, Crystal
- **Application**: Python (3.11, 3.12), Ruby, PHP, Perl, Lua
- **JVM**: Java (17, 21), Kotlin, Scala, Clojure, Groovy
- **.NET**: C#, F# (v8.0)
- **JavaScript/TypeScript**: Node.js 20, Deno, Bun
- **Functional**: Elixir, Erlang, Haskell, OCaml
- **Mobile**: Flutter/Dart, Android SDK
- **Blockchain**: Solidity (Hardhat, Foundry), Solana CLI

### Build Systems & Tools

- Bazel, CMake, Ninja, Maven, Gradle
- npm, yarn, pnpm, Poetry, Cargo, Go modules
- Task runners: just, make

### Infrastructure Services

- **SQL Databases**: PostgreSQL 16, MySQL 8.3
- **NoSQL**: MongoDB 7, Redis 7
- **Search**: Elasticsearch 8.12
- **Message Queues**: Kafka, RabbitMQ
- **Object Storage**: MinIO (S3-compatible)
- **Monitoring**: Prometheus, Grafana, Jaeger, Loki
- **Reverse Proxy**: Traefik
- **Development Tools**: Adminer, Redis Commander, Mongo Express, MailHog

### DevOps & Cloud

- **Containers**: Docker, kind, kubectl, helm, k9s
- **IaC**: Terraform, Terragrunt, Ansible, Packer
- **Cloud CLIs**: AWS, Google Cloud, Azure
- **Security**: Trivy, Hadolint, Gitleaks

### Development Tools

- **Version Control**: Git, Git LFS, GitHub CLI, LazyGit
- **Editors**: Neovim, Vim, Emacs
- **Terminal**: Tmux, Zsh, Starship prompt
- **Testing**: k6, Playwright, Postman CLI
- **API Tools**: HTTPie, grpcurl, Evans
- **Code Quality**: golangci-lint, shellcheck, yamllint
- **Documentation**: Hugo, MkDocs, Sphinx

## 🔧 Prerequisites

### Install Docker (Arch Linux)

```bash
# Install Docker
sudo pacman -S docker docker-compose docker-buildx

# Enable and start Docker service
sudo systemctl enable docker.service
sudo systemctl start docker.service

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Log out and log back in for group changes to take effect
# Or run: newgrp docker
```

### Verify Installation

```bash
docker --version
docker compose version
```

### System Requirements

- **Disk Space**: Minimum 50GB free (100GB+ recommended)
- **RAM**: Minimum 16GB (32GB+ recommended for all services)
- **CPU**: 4+ cores recommended
- **OS**: Linux (Arch Linux, Ubuntu, etc.), macOS, Windows with WSL2

## 🚀 Quick Start

### Method 1: Using the Makefile Pipeline (Recommended)

```bash
cd /home/mrDinkelman/rice-mono
make config
```

This script will:

1. Run pre-flight checks (tool versions, Docker, ports)
2. Install required tooling (asdf plugins, language runtimes)
3. Warm up Docker/compose stacks (devcontainer + backend)
4. Generate frontend overrides and restart project containers

### Method 2: Manual Setup

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# Build the devcontainer
docker compose build devcontainer

# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### Method 3: VS Code Dev Containers Extension

1. Install the "Dev Containers" extension in VS Code
2. Open the rice-mono folder in VS Code
3. Press `F1` or `Ctrl+Shift+P`
4. Select "Dev Containers: Reopen in Container"
5. Wait for the container to build and start

## 📊 Service URLs & Credentials

After starting, access these services:

| Service               | URL                    | Username   | Password          |
| --------------------- | ---------------------- | ---------- | ----------------- |
| **PostgreSQL**        | localhost:5432         | rice_user  | rice_password     |
| **MySQL**             | localhost:3306         | rice_user  | rice_password     |
| **MongoDB**           | localhost:27017        | rice_user  | rice_password     |
| **Redis**             | localhost:6379         | -          | rice_password     |
| **Elasticsearch**     | http://localhost:9200  | -          | -                 |
| **Kafka**             | localhost:9092         | -          | -                 |
| **RabbitMQ**          | http://localhost:15672 | rice_user  | rice_password     |
| **MinIO Console**     | http://localhost:9001  | rice_admin | rice_password_123 |
| **Grafana**           | http://localhost:3000  | admin      | admin             |
| **Prometheus**        | http://localhost:9090  | -          | -                 |
| **Jaeger UI**         | http://localhost:16686 | -          | -                 |
| **Traefik Dashboard** | http://localhost:8080  | -          | -                 |
| **Adminer**           | http://localhost:8081  | -          | -                 |
| **Redis Commander**   | http://localhost:8082  | -          | -                 |
| **Mongo Express**     | http://localhost:8083  | admin      | admin             |
| **MailHog**           | http://localhost:8025  | -          | -                 |

## 💻 Working Inside the Container

### Access the Container Shell

```bash
# Enter the devcontainer
docker compose exec devcontainer bash

# Or with sudo
docker compose exec --user root devcontainer bash
```

### Verify Tools

Once inside the container:

```bash
# Check versions
python3 --version
node --version
go version
cargo --version
java -version
kubectl version --client
terraform version
bazel version

# Test databases
psql -h postgres -U rice_user -d rice_db
redis-cli -h redis -a rice_password ping
mongo mongodb://rice_user:rice_password@mongodb:27017/rice_db
```

## 🔧 Useful Commands

### Container Management

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Stop and remove all data
docker compose down -v

# Rebuild a service
docker compose build devcontainer

# View logs
docker compose logs -f
docker compose logs -f devcontainer
docker compose logs -f postgres

# Restart a service
docker compose restart devcontainer

# Check resource usage
docker stats
```

### Development Workflow

```bash
# Enter devcontainer
docker compose exec devcontainer bash

# Run Bazel build
bazel build //...

# Run Python tests
cd .bot && pytest

# Run Go tests
cd .backend/token && go test ./...

# Start a development server
npm run dev
```

### Cleaning Up

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Full cleanup (CAUTION: removes everything)
docker system prune -a --volumes
```

## 📁 Directory Structure

```
.devcontainer/
├── Dockerfile              # Main devcontainer image
├── docker-compose.yml      # All services configuration
├── devcontainer.json       # VS Code devcontainer config
├── start-devcontainer.sh   # Startup script
├── config/                 # Service configurations
│   ├── prometheus/
│   ├── grafana/
│   ├── loki/
│   ├── logstash/
│   └── traefik/
└── init-scripts/           # Database initialization scripts
    ├── postgres/
    └── mysql/
```

## 🎯 Use Cases

### Full-Stack Development

All languages and frameworks ready to go - Python backend, React frontend, Go microservices, all in one place.

### Data Engineering

Python data tools, Spark, Kafka, multiple databases, all integrated.

### DevOps & Infrastructure

Terraform, Ansible, Kubernetes tools, cloud CLIs - manage any infrastructure.

### Blockchain Development

Solidity with Hardhat/Foundry, Solana CLI, Rust for smart contracts.

### Machine Learning

Python ML stack, Jupyter notebooks, MLflow for experiment tracking.

### API Development

Multiple languages for backend, gRPC/Protobuf support, testing tools.

## 🐛 Troubleshooting

### Build Issues

**Problem**: Build fails due to network timeouts

```bash
# Increase Docker build timeout
export DOCKER_BUILDKIT=1
docker compose build --no-cache devcontainer
```

**Problem**: Out of disk space

```bash
# Clean up Docker
docker system prune -a --volumes
```

### Service Issues

**Problem**: Service won't start

```bash
# Check logs
docker compose logs <service-name>

# Restart service
docker compose restart <service-name>
```

**Problem**: Port already in use

```bash
# Check what's using the port
sudo lsof -i :5432

# Change port in docker-compose.yml if needed
```

### Performance Issues

**Problem**: Container is slow

```bash
# Allocate more resources in Docker Desktop settings
# Or reduce number of running services in docker-compose.yml
```

## 🔐 Security Notes

⚠️ **IMPORTANT**: This setup uses default passwords and is **NOT secure for production use**.

- Change all default passwords in `docker-compose.yml`
- Use secrets management for sensitive data
- Enable authentication where disabled (Elasticsearch, Prometheus, etc.)
- Configure TLS/SSL for production deployments
- Review security settings in Dockerfile and docker-compose.yml

## 📝 Customization

### Add More Languages

Edit `.devcontainer/Dockerfile` and add installation steps for your language.

### Add More Services

Edit `.devcontainer/docker-compose.yml` and add new service definitions.

### Modify Tool Versions

Edit `.tool-versions` in the root directory and rebuild.

### Change Ports

Edit `docker-compose.yml` port mappings and rebuild.

## 🚀 Performance Tips

1. **Use BuildKit**: `export DOCKER_BUILDKIT=1`
2. **Multi-stage builds**: Already implemented in Dockerfile
3. **Layer caching**: Keep frequently changing commands at the end
4. **Volume mounts**: Use volumes for build caches (already configured)
5. **Stop unused services**: Comment out services you don't need in docker-compose.yml

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Bazel Documentation](https://bazel.build/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

This is your ultimate dev environment! Customize it to your needs:

1. Fork or modify the Dockerfile
2. Add/remove services in docker-compose.yml
3. Update tool versions in .tool-versions
4. Share improvements with the team

## 📄 License

This development environment configuration is part of the Rice-Mono project.

## 🎉 Happy Coding

You now have access to virtually every development tool and service available in the open source world. Go build
something amazing! 🚀

---

**Built with ❤️ for developers who want it all**
