# 🧹 Docker Cache Management

This document explains how Docker cache management works in Chain Rice project.

## 🔄 Automatic Cache Cleaning

### Default Behavior
By default, `make down` automatically cleans Docker cache to save disk space:

```bash
make down         # Stops services AND cleans cache
```

### Keep Cache Option
If you want to stop services without cleaning cache (useful for development):

```bash
make down-no-clean # Stops services but keeps cache
```

## 🧹 Manual Cache Management

### Clean Everything
```bash
make clean        # Clean all Docker cache and volumes
```

### Clean Images Only
```bash
make clean-images # Clean only Docker images
```

## 💡 When to Use Each Command

### `make down` (Default)
- **Use when**: You're done with development for the day
- **What it does**: Stops services + cleans cache
- **Benefit**: Saves disk space
- **Drawback**: Next `make dev` will rebuild images

### `make down-no-clean`
- **Use when**: You're taking a short break but will continue soon
- **What it does**: Stops services but keeps cache
- **Benefit**: Faster restart next time
- **Drawback**: Uses more disk space

### `make clean`
- **Use when**: You want to free up disk space manually
- **What it does**: Cleans all Docker cache and volumes
- **Benefit**: Maximum disk space recovery
- **Drawback**: All images will be rebuilt

### `make clean-images`
- **Use when**: You want to clean only images (keep build cache)
- **What it does**: Removes unused images only
- **Benefit**: Moderate disk space recovery
- **Drawback**: Images will be rebuilt but build cache is preserved

## 📊 Disk Space Impact

| Command | Cache Cleaned | Volumes Cleaned | Images Cleaned | Rebuild Required |
|---------|---------------|-----------------|----------------|------------------|
| `make down` | ✅ | ❌ | ❌ | Partial |
| `make down-no-clean` | ❌ | ❌ | ❌ | None |
| `make clean` | ✅ | ✅ | ✅ | Full |
| `make clean-images` | ❌ | ❌ | ✅ | Images only |

## 🚨 Important Notes

- **Development**: Use `make down-no-clean` during active development
- **End of day**: Use `make down` to clean up
- **Disk full**: Use `make clean` for maximum cleanup
- **CI/CD**: Always use `make clean` in automated builds

## 🔧 Troubleshooting

### Cache Not Cleaning
```bash
# Check Docker system info
docker system df

# Force clean everything
docker system prune -a --volumes -f
```

### Out of Space
```bash
# Check what's using space
docker system df -v

# Clean everything
make clean
```

### Build Issues After Clean
```bash
# Rebuild everything
make build-all
```
