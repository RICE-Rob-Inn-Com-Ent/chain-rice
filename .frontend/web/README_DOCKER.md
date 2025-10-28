# Docker Development - Port 3001 with Hot Reload

## 🚀 Quick Start (3 Commands)

```bash
# 1. Start Ollama (in separate terminal)
ollama serve

# 2. Start Docker dev environment
cd /home/mrDinkelman/rice-mono/.frontend/web
./docker-dev.sh

# 3. Open browser
http://localhost:3001
```

That's it! Hot reload is enabled. Edit code and see changes instantly.

## Alternative: Using docker-compose Directly

```bash
# Start in foreground (see logs)
docker-compose -f docker-compose.dev.yml up --build

# Start in background
docker-compose -f docker-compose.dev.yml up -d --build

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop
docker-compose -f docker-compose.dev.yml down
```

## What's Included

✅ **Port 3001** - Same as local dev  
✅ **Hot Reload** - File changes trigger auto-refresh  
✅ **Ollama Integration** - Connects to host Ollama (localhost:11434)  
✅ **Volume Mounts** - Code synced in real-time  
✅ **Fast Startup** - Dependencies cached

## Configuration Files

- **Dockerfile.dev** - Development container definition
- **docker-compose.dev.yml** - Container orchestration
- **docker-dev.sh** - Quick start script
- **.dockerignore** - Files excluded from build

## Development Workflow

### Day-to-Day

```bash
# Morning: Start containers
./docker-dev.sh &

# Work on code (hot reload active)
# Files in app/, lib/, themes/ automatically sync

# Evening: Stop
docker-compose -f docker-compose.dev.yml down
```

### Making Code Changes

1. Edit any `.tsx`, `.ts`, or `.css` file
2. Save file
3. Browser automatically refreshes (hot reload)
4. No restart needed!

### Adding Dependencies

```bash
# Add package
docker-compose -f docker-compose.dev.yml exec vite-dashboard yarn add package-name

# Or rebuild
docker-compose -f docker-compose.dev.yml up --build
```

## Ports

| Service       | Port  | Description     |
| ------------- | ----- | --------------- |
| Dashboard     | 3001  | Vite dev server |
| Ollama (host) | 11434 | AI model API    |

## Ollama Connection

The container connects to Ollama on your **host machine** via `host.docker.internal:11434`.

### Verify Ollama is Accessible

```bash
# From host
curl http://localhost:11434/api/tags

# From inside container
docker-compose -f docker-compose.dev.yml exec vite-dashboard curl http://host.docker.internal:11434/api/tags
```

## Troubleshooting

### "Ollama: Disconnected" in Dashboard

**Cause:** Ollama not running on host

**Fix:**

```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Restart dashboard container
docker-compose -f docker-compose.dev.yml restart
```

### Hot Reload Not Working

**Cause:** File watching not enabled

**Fix:** Already configured with:

- `CHOKIDAR_USEPOLLING=true`
- `WATCHPACK_POLLING=true`

If still not working:

```bash
# Restart container
docker-compose -f docker-compose.dev.yml restart
```

### Port 3001 Already in Use

**Fix:**

```bash
# Kill process on port 3001
lsof -ti:3001 | xargs kill -9

# Or change host port in docker-compose.dev.yml
ports:
  - "3002:3001"  # Map to different host port
```

### Container Build Fails

**Fix:**

```bash
# Clean rebuild
docker-compose -f docker-compose.dev.yml down -v
docker system prune -af --volumes
docker-compose -f docker-compose.dev.yml up --build
```

## Commands Cheat Sheet

```bash
# Start (foreground)
docker-compose -f docker-compose.dev.yml up --build

# Start (background)
docker-compose -f docker-compose.dev.yml up -d --build

# Stop
docker-compose -f docker-compose.dev.yml down

# Restart
docker-compose -f docker-compose.dev.yml restart

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Execute command in container
docker-compose -f docker-compose.dev.yml exec vite-dashboard <command>

# Shell access
docker-compose -f docker-compose.dev.yml exec vite-dashboard sh

# Rebuild
docker-compose -f docker-compose.dev.yml up --build

# Clean up
docker-compose -f docker-compose.dev.yml down -v
```

## Environment Variables

Set in `docker-compose.dev.yml`:

- `VITE_HOST=0.0.0.0` - Listen on all interfaces
- `VITE_PORT=3001` - Dev server port
- `CHOKIDAR_USEPOLLING=true` - Enable file watching
- `DOCKER_ENV=true` - Flag for Docker environment

## Volume Mounts

The following directories are mounted for hot reload:

- `./app` - Dashboard pages
- `./lib` - Components, hooks, services
- `./themes` - Theme configurations
- `./index.tsx` - Main entry
- `./vite.config.ts` - Vite config
- `./tailwind.config.ts` - Tailwind config

**Note:** `node_modules` is NOT mounted (uses container's version)

## Performance

### Build Time

- **First build:** ~30-60 seconds (installs dependencies)
- **Subsequent builds:** ~5-10 seconds (cached layers)

### Hot Reload Speed

- **File save → Browser refresh:** ~1-2 seconds

### Container Resource Usage

- **Memory:** ~200-400 MB
- **CPU:** ~5-10% idle, ~30-50% during builds

## Comparison: Docker vs Local

| Feature     | Docker             | Local          |
| ----------- | ------------------ | -------------- |
| Setup       | `./docker-dev.sh`  | `yarn dev`     |
| Hot Reload  | ✅ Yes (1-2s)      | ✅ Yes (<1s)   |
| Port        | 3001               | 3001           |
| Ollama      | Via host           | Direct         |
| Isolation   | ✅ Complete        | Shares host    |
| Consistency | ✅ Same everywhere | Varies by host |
| Startup     | ~10-15s            | ~3-5s          |

## When to Use Docker

✅ **Use Docker when:**

- Team development (consistent environment)
- Testing deployment scenarios
- Isolating dependencies
- Multiple projects on same machine

✅ **Use Local when:**

- Solo development
- Faster iteration needed
- Debugging build issues
- Limited Docker resources

## Next Steps

1. **Start developing:**

   ```bash
   ./docker-dev.sh
   ```

2. **Edit code:** Changes auto-reload

3. **Check Ollama:** Dashboard should show "Connected"

4. **Build something awesome!** 🎨

## See Also

- [DOCKER_SETUP.md](./DOCKER_SETUP.md) - Detailed Docker docs
- [QUICK_START.md](./QUICK_START.md) - Local development guide
- [DASHBOARD_GUIDE.md](./DASHBOARD_GUIDE.md) - User manual

---

**Ready to go!** Run `./docker-dev.sh` and start building. 🚀
