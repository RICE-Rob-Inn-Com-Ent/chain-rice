# 🚀 Quick Start Guide - Rice-Mono Ultimate Dev Environment

## Step 1: Install Docker (if not already installed)

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer
./install-docker-arch.sh
```

**After installation:**

- Log out and log back in (or run `newgrp docker`)
- Verify: `docker --version`

## Step 2: Build and Start the Environment

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer
./start-devcontainer.sh
```

**⏱️ Build time:** 30-60 minutes (first time only)
**💾 Disk space required:** ~50GB

## Step 3: Access Your Development Environment

### Option A: VS Code (Recommended)

1. Open VS Code in the rice-mono folder
2. Install "Dev Containers" extension
3. Press `F1` → "Dev Containers: Reopen in Container"

### Option B: Terminal

```bash
docker compose exec devcontainer bash
```

## What You Get

✅ **200+ Tools** - Every programming language and framework
✅ **15+ Services** - PostgreSQL, Redis, Kafka, MongoDB, and more
✅ **Complete Stack** - Frontend, backend, DevOps, blockchain, ML
✅ **Zero Setup** - Everything pre-configured and ready to use

## Quick Commands

```bash
# Check all services
docker compose ps

# View logs
docker compose logs -f

# Stop everything
docker compose down

# Restart devcontainer
docker compose restart devcontainer

# Clean up everything
docker compose down -v  # ⚠️ This removes all data!
```

## Service Access

| Service  | URL                    | User       | Pass              |
| -------- | ---------------------- | ---------- | ----------------- |
| Grafana  | http://localhost:3000  | admin      | admin             |
| Adminer  | http://localhost:8081  | -          | -                 |
| RabbitMQ | http://localhost:15672 | rice_user  | rice_password     |
| MinIO    | http://localhost:9001  | rice_admin | rice_password_123 |
| Jaeger   | http://localhost:16686 | -          | -                 |
| Traefik  | http://localhost:8080  | -          | -                 |

See [README.md](./README.md) for full documentation.

## Troubleshooting

**Problem:** Docker not installed
**Solution:** Run `./install-docker-arch.sh`

**Problem:** Permission denied
**Solution:** Add user to docker group and log out/in

**Problem:** Port already in use
**Solution:** Stop conflicting service or change port in docker-compose.yml

**Problem:** Out of disk space
**Solution:** Run `docker system prune -a --volumes`

## Next Steps

1. ✅ Install Docker
2. ✅ Build environment (30-60 min)
3. ✅ Open in VS Code
4. 🚀 Start coding!

**Need help?** Check the [full README.md](./README.md)
