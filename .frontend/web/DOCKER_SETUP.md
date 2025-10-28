# Docker Development Setup - Hot Reload on Port 3001

## Quick Start

### 1. Build and Start Container

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web

# Build and start in one command
docker-compose -f docker-compose.dev.yml up --build

# Or run in background
docker-compose -f docker-compose.dev.yml up -d --build
```

### 2. Access Dashboard

Open browser: **http://localhost:3001**

### 3. Stop Container

```bash
docker-compose -f docker-compose.dev.yml down
```

## Features

✅ **Hot Reload** - Code changes automatically refresh  
✅ **Port 3001** - Consistent with local development  
✅ **Volume Mounts** - Real-time code sync  
✅ **Ollama Integration** - Connects to host Ollama (localhost:11434)  
✅ **Fast Startup** - Cached dependencies in container

## File Structure

```
.frontend/web/
├── Dockerfile.dev           # Development container
├── docker-compose.dev.yml   # Compose configuration
├── .dockerignore           # Exclude files from build
└── [source files]          # Mounted for hot reload
```

## How Hot Reload Works

### Volume Mounts

The following directories are mounted from host → container:

- `./app` - All dashboard pages
- `./lib` - Components, hooks, services
- `./themes` - Theme configurations
- `*.tsx`, `*.ts`, `*.css` - Config files

### File Watching

- `CHOKIDAR_USEPOLLING=true` - Enable polling for file changes
- `WATCHPACK_POLLING=true` - Webpack polling (backup)
- Vite automatically detects changes and hot-reloads

### What Triggers Reload

- ✅ Editing `.tsx` files
- ✅ Editing `.ts` files
- ✅ Editing `.css` files
- ✅ Changing `vite.config.ts`
- ✅ Changing `tailwind.config.ts`

## Connecting to Ollama

### Option 1: Ollama on Host (Recommended)

Start Ollama on your host machine:

```bash
ollama serve
```

The container connects via `host.docker.internal:11434`

### Option 2: Ollama in Container

Add Ollama service to `docker-compose.dev.yml`:

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    networks:
      - dashboard-network

volumes:
  ollama-data:
```

Then update Vite proxy to target `ollama:11434` instead of `localhost:11434`.

## Commands

### View Logs

```bash
# Follow logs
docker-compose -f docker-compose.dev.yml logs -f

# View specific service
docker-compose -f docker-compose.dev.yml logs -f vite-dashboard
```

### Restart Container

```bash
docker-compose -f docker-compose.dev.yml restart
```

### Rebuild After Dependency Changes

```bash
# If you add new packages to package.json
docker-compose -f docker-compose.dev.yml up --build
```

### Execute Commands in Container

```bash
# Open shell
docker-compose -f docker-compose.dev.yml exec vite-dashboard sh

# Run yarn commands
docker-compose -f docker-compose.dev.yml exec vite-dashboard yarn add some-package
```

## Troubleshooting

### Hot Reload Not Working

**Problem:** Changes don't trigger refresh

**Solution:**

```bash
# Increase polling interval (edit docker-compose.dev.yml)
environment:
  - CHOKIDAR_USEPOLLING=true
  - CHOKIDAR_INTERVAL=1000  # Add this

# Restart container
docker-compose -f docker-compose.dev.yml restart
```

### Ollama Connection Failed

**Problem:** Dashboard shows "Ollama: Disconnected"

**Solution 1 - Check host Ollama:**

```bash
# On host machine
curl http://localhost:11434/api/tags

# If not running, start it
ollama serve
```

**Solution 2 - Update proxy target:** Edit `vite.config.ts`:

```typescript
proxy: {
  "/api/ollama": {
    target: "http://host.docker.internal:11434",  // For Docker
    // OR
    target: "http://ollama:11434",  // If Ollama in container
  }
}
```

### Port 3001 Already in Use

**Problem:** Error: "port is already allocated"

**Solution:**

```bash
# Find and kill process on port 3001
lsof -ti:3001 | xargs kill -9

# Or change port in docker-compose.dev.yml
ports:
  - "3002:3001"  # Map to different host port
```

### Build Errors

**Problem:** Container fails to build

**Solution:**

```bash
# Clean build
docker-compose -f docker-compose.dev.yml down -v
docker system prune -af
docker-compose -f docker-compose.dev.yml up --build
```

### Module Not Found After Adding Package

**Problem:** New package not found

**Solution:**

```bash
# Rebuild to install new dependencies
docker-compose -f docker-compose.dev.yml up --build

# Or install manually
docker-compose -f docker-compose.dev.yml exec vite-dashboard yarn install
docker-compose -f docker-compose.dev.yml restart
```

## Performance Tips

### 1. Use .dockerignore

Exclude unnecessary files from build context (already configured).

### 2. Layer Caching

Dependencies are cached. Only source code changes trigger rebuilds.

### 3. Volume Performance

On Mac/Windows, use Docker Desktop's latest version for better volume performance.

### 4. Memory Allocation

Increase Docker memory if builds are slow:

```bash
# Docker Desktop → Settings → Resources → Memory
# Set to at least 4GB
```

## Development Workflow

### Day-to-day Development

```bash
# Morning: Start container
docker-compose -f docker-compose.dev.yml up -d

# Work on code (hot reload active)
# Edit files in app/, lib/, themes/

# Evening: Stop container
docker-compose -f docker-compose.dev.yml down
```

### Adding New Dependencies

```bash
# Add package
docker-compose -f docker-compose.dev.yml exec vite-dashboard yarn add package-name

# Rebuild if needed
docker-compose -f docker-compose.dev.yml up --build
```

### Testing Production Build

```bash
# Use main Dockerfile (not Dockerfile.dev)
docker build -t egyptian-dashboard:prod .
docker run -p 8080:80 egyptian-dashboard:prod
```

## Environment Variables

Available in container:

- `NODE_ENV=development`
- `VITE_HOST=0.0.0.0`
- `VITE_PORT=3001`
- `CHOKIDAR_USEPOLLING=true`
- `WATCHPACK_POLLING=true`

Add custom variables in `docker-compose.dev.yml`:

```yaml
environment:
  - VITE_API_URL=http://api.example.com
  - VITE_CUSTOM_VAR=value
```

Access in code:

```typescript
const apiUrl = import.meta.env.VITE_API_URL;
```

## Comparison: Docker vs Local

| Feature        | Docker Dev         | Local Dev       |
| -------------- | ------------------ | --------------- |
| Port           | 3001               | 3001            |
| Hot Reload     | ✅ Yes             | ✅ Yes          |
| Ollama Access  | Via host           | Direct          |
| Startup Time   | ~10-15s            | ~3-5s           |
| Isolation      | ✅ Complete        | Shares host     |
| Consistency    | ✅ Same everywhere | Depends on host |
| Resource Usage | Higher             | Lower           |

## Summary

✅ **Dockerfile.dev** - Development container with hot reload  
✅ **docker-compose.dev.yml** - Orchestration with volumes  
✅ **Port 3001** - Matches local development  
✅ **Ollama Integration** - Connects to host or container  
✅ **Hot Reload** - Real-time code changes

**Start developing:**

```bash
docker-compose -f docker-compose.dev.yml up --build
```

Open: http://localhost:3001 🚀
