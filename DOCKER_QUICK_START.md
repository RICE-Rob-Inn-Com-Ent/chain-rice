# 🐳 Docker Quick Start Guide

## ✅ Currently Running Services

All core backend services are **UP and HEALTHY**:

```
✅ MongoDB         → localhost:27017
✅ PostgreSQL      → localhost:5432
✅ Data Service    → localhost:8080
✅ GraphQL API     → localhost:4000
✅ Bot Core        → localhost:8100
✅ Bot Integrations→ localhost:8200
```

## 🚀 Essential Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Restart a service
docker-compose restart <service-name>

# Rebuild a service
docker-compose up -d --build <service-name>
```

## 📊 Port Mapping

| Service          | Internal | External | URL                                         |
| ---------------- | -------- | -------- | ------------------------------------------- |
| MongoDB          | 27017    | 27017    | mongodb://localhost:27017                   |
| PostgreSQL       | 5432     | 5432     | postgres://rice:rice123@localhost:5432/rice |
| Data API         | 8080     | 8080     | http://localhost:8080                       |
| GraphQL          | 4000     | 4000     | http://localhost:4000                       |
| Bot Core         | 8100     | 8100     | http://localhost:8100                       |
| Bot Integrations | 8200     | 8200     | http://localhost:8200                       |

## 🔨 Build Remaining Services (when network is better)

```bash
# Frontend
docker-compose up -d --build ui-kit nextjs-web

# Gods (AI Services) - one at a time recommended
docker-compose up -d --build thoth
docker-compose up -d --build ra
docker-compose up -d --build isis
docker-compose up -d --build bastet
docker-compose up -d --build maat
docker-compose up -d --build khnum
```

## 📁 Files Structure

```
rice-mono/
├── docker-compose.yml          # Main orchestration file
├── DOCKER_STATUS.md            # Detailed status report
└── DOCKER_QUICK_START.md       # This file
```

## 🎯 Next Steps

1. **Test APIs**:

   ```bash
   curl http://localhost:8100/health
   curl http://localhost:4000/health
   ```

2. **Build Frontend** (when ready):

   ```bash
   docker-compose up -d --build ui-kit nextjs-web
   ```

3. **Build Gods Services** (when ready, requires good network):
   ```bash
   docker-compose up -d --build thoth ra isis bastet maat khnum
   ```

## 💡 Tips

- All scattered docker-compose files have been removed
- Single `docker-compose.yml` at root manages everything
- Docker cleaned: **128.4 GB reclaimed**
- All services use proper health checks
- Persistent volumes for databases

---

**Status**: ✅ Backend core is operational and healthy! **Created**: 2025-10-27
