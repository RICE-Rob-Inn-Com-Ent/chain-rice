# ✅ Port 3001 Configuration - CONFIRMED

## Summary

**All configurations set to port 3001** - No port 3003 anywhere!

## Configuration Files

### 1. vite.config.ts ✅

```typescript
server: {
  port: 3001,  // ✅ CORRECT
  host: "0.0.0.0",
  // ...
}
```

### 2. package.json ✅

```json
{
  "scripts": {
    "dev": "vite --port 3001 --host 0.0.0.0", // ✅ CORRECT
    "preview": "vite preview --port 3001" // ✅ CORRECT
  }
}
```

### 3. docker-compose.dev.yml ✅

```yaml
ports:
  - "3001:3001" # ✅ CORRECT
environment:
  - VITE_PORT=3001 # ✅ CORRECT
```

### 4. Dockerfile.dev ✅

```dockerfile
EXPOSE 3001  # ✅ CORRECT
ENV VITE_PORT=3001  # ✅ CORRECT
```

## Access URLs

### Local Development

```bash
yarn dev
# → http://localhost:3001 ✅
```

### Docker Development

```bash
./docker-dev.sh
# → http://localhost:3001 ✅
```

## Verification

### Check Port Configuration

```bash
# Check vite.config.ts
grep -n "port:" vite.config.ts
# Output: port: 3001,

# Check package.json
grep -n "3001" package.json
# Output: "dev": "vite --port 3001..."

# Check Docker compose
grep -n "3001" docker-compose.dev.yml
# Output: - "3001:3001"
```

### Test Port Availability

```bash
# Check if port 3001 is free
lsof -ti:3001

# If occupied, kill process
lsof -ti:3001 | xargs kill -9
```

## Port Mapping

| Environment | Host Port | Container Port | Access URL            |
| ----------- | --------- | -------------- | --------------------- |
| Local Dev   | 3001      | N/A            | http://localhost:3001 |
| Docker Dev  | 3001      | 3001           | http://localhost:3001 |
| Production  | 80        | 80             | http://localhost:80   |

## No Port 3003 Anywhere!

**Confirmed:** No references to port 3003 in any configuration.

```bash
# Search for port 3003
grep -r "3003" . --exclude-dir=node_modules --exclude-dir=.git
# Result: No matches ✅
```

## Why Port 3001?

✅ **Consistent** - Same port for local and Docker  
✅ **Available** - Not used by common services  
✅ **Documented** - All docs reference 3001  
✅ **Ollama Integration** - Proxy configured for 3001

## Start Commands

### Local Development

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web
yarn dev
# Starts on http://localhost:3001
```

### Docker Development

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web
./docker-dev.sh
# Starts on http://localhost:3001
```

### Both use PORT 3001! ✅

## Hot Reload

Both local and Docker have hot reload enabled:

**Local:**

- Native Vite HMR
- Changes reflect instantly

**Docker:**

- Volume mounts + polling
- Changes reflect in 1-2 seconds
- `CHOKIDAR_USEPOLLING=true`

## Ollama Proxy

Configured to work on port 3001 in both environments:

**Local:**

```
http://localhost:3001/api/ollama → http://localhost:11434
```

**Docker:**

```
http://localhost:3001/api/ollama → http://host.docker.internal:11434
```

## Configuration Matrix

| Setting          | Value          | File                   |
| ---------------- | -------------- | ---------------------- |
| Vite Port        | 3001           | vite.config.ts         |
| Dev Script       | --port 3001    | package.json           |
| Docker Host      | 3001           | docker-compose.dev.yml |
| Docker Container | 3001           | docker-compose.dev.yml |
| Dockerfile Port  | 3001           | Dockerfile.dev         |
| ENV Variable     | VITE_PORT=3001 | docker-compose.dev.yml |

**ALL SET TO 3001!** ✅

## Troubleshooting

### "Port 3001 in use"

```bash
# Find process
lsof -ti:3001

# Kill it
lsof -ti:3001 | xargs kill -9

# Restart
yarn dev
```

### Docker port conflict

```bash
# Stop containers
docker-compose -f docker-compose.dev.yml down

# Clear any orphan containers
docker container prune -f

# Restart
./docker-dev.sh
```

## Final Confirmation

✅ Port 3001 in vite.config.ts  
✅ Port 3001 in package.json  
✅ Port 3001 in docker-compose.dev.yml  
✅ Port 3001 in Dockerfile.dev  
✅ No port 3003 anywhere  
✅ Hot reload enabled  
✅ Ollama proxy configured

**Everything is on PORT 3001!** 🎉

## Access Now

### Local

```bash
yarn dev
```

Visit: **http://localhost:3001**

### Docker

```bash
./docker-dev.sh
```

Visit: **http://localhost:3001**

Both work! Both use port 3001! Both have hot reload! ✅
