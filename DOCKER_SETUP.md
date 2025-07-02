# 🐋 Docker Setup for Chain Rice & Meowtopia

This document explains how to build and run the complete Chain Rice blockchain project with Meowtopia frontend and backend using Docker.

## 🚀 Quick Start

### Start All Services
```bash
./scripts/start-all.sh
```

### Start Individual Services
```bash
# Web frontend only (includes backend dependencies)
./scripts/start-web.sh

# Blockchain only
./scripts/start-blockchain.sh

# Or manually with docker-compose
docker-compose up --build web-frontend
```

## 📦 Services Overview

| Service | Port | Description |
|---------|------|-------------|
| **Blockchain** | 26657 | Chain Rice blockchain RPC |
| **Blockchain API** | 1317 | REST API for blockchain |
| **Backend** | 8000 | FastAPI backend for Meowtopia |
| **Web Frontend** | 3000 | React web application |
| **PostgreSQL** | 5432 | Database for backend |
| **Redis** | 6379 | Cache/queue for backend |

## 🛠️ Requirements

- Docker & Docker Compose
- At least 4GB RAM
- 10GB free disk space

## 🔧 Development

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f blockchain
docker-compose logs -f web-frontend
docker-compose logs -f backend
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart blockchain
```

### Stop Services
```bash
# Stop all
docker-compose down

# Stop and remove volumes (CAUTION: This deletes data!)
docker-compose down -v
```

### Rebuild Services
```bash
# Rebuild all
docker-compose up --build

# Rebuild specific service
docker-compose up --build blockchain
```

## 🔍 Troubleshooting

### Go Version Issues
If you see "go.mod requires go >= 1.24.0", the Docker image has been updated to use Go 1.24+ which supports the `tool` directive required by Ignite CLI.

### Port Conflicts
If ports are already in use, you can modify them in `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Change 3000 to 3001
```

### Build Context Too Large
If Docker build is slow due to large context, add more items to `.dockerignore`:
```
node_modules
.git
.vscode
*.log
```

### Database Connection Issues
Ensure PostgreSQL is fully started before backend:
```bash
docker-compose up postgres
# Wait for "database system is ready to accept connections"
docker-compose up backend
```

## 🌐 Access URLs

After starting services:

- **Web Application**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Backend Docs**: http://localhost:8000/docs
- **Blockchain RPC**: http://localhost:26657
- **Blockchain API**: http://localhost:1317
- **Blockchain Status**: http://localhost:26657/status

## 🗂️ Project Structure

```
chain-rice/
├── Dockerfile.blockchain          # Blockchain service
├── docker-compose.yml            # Orchestration
├── go.mod                        # Go dependencies (fixed for 1.24+)
├── scripts/
│   ├── start-all.sh              # Start all services
│   ├── start-web.sh              # Start web frontend
│   └── start-blockchain.sh       # Start blockchain only
└── meowtopia/
    ├── backend/
    │   └── Dockerfile            # Python FastAPI backend
    └── frontend/web/
        └── Dockerfile            # React frontend
```

## 🔄 Updates Made

✅ **Fixed Go Version Compatibility**
- Updated Dockerfile to use Go 1.24+
- Restored `tool` directive in go.mod for Ignite CLI
- All dependencies preserved

✅ **Complete Docker Setup**
- Blockchain service with proper ports
- Backend with PostgreSQL and Redis
- Frontend with development hot reload
- Network isolation and service discovery

✅ **Helper Scripts**
- Easy startup scripts for different scenarios
- Proper service dependencies
- Clear status information

## 🎯 Next Steps

1. **Initialize Blockchain**: The blockchain may need genesis initialization on first run
2. **Database Migration**: Backend may need database schema setup
3. **Environment Variables**: Customize `.env` files for different environments
4. **Production**: Use production Docker images for deployment

Happy coding! 🎉