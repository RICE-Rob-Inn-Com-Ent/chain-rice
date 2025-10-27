# 🛠️ Makefile Commands Guide

## 🎯 Trzy Sposoby Uruchamiania Frontendu

### 1. 🎨 Frontend Lokalnie (BEZ Dockera) - `make web-dev`
```bash
make web-dev
```
**Co robi:**
- Odpala `yarn dev` lokalnie
- UI Kit (Vite) na porcie 5173
- Next.js na porcie 3002
- **Najszybsze** do developmentu
- Hot reload działa natywnie
- **BEZ DOCKERA!**

**Kiedy używać:**
- Development frontend
- Szybkie zmiany w UI
- Debugowanie React/Next.js

---

### 2. 🐳 Frontend w Dockerze - `make web-docker` lub `--profile web`
```bash
make web-docker
# LUB
docker-compose --profile web up -d
```
**Co robi:**
- Buduje obrazy z **Dockerfile**
- `.frontend/web/Dockerfile` dla UI Kit
- `.project/web/Dockerfile` dla Next.js
- Uruchamia kontenery
- **W DOCKERZE!**

**Kiedy używać:**
- Testing w środowisku podobnym do production
- CI/CD pipelines
- Chcesz mieć WSZYSTKO w Dockerze

---

### 3. 🚀 Wszystko w Dockerze - `make all`
```bash
make all
```
**Co robi:**
- Backend + Gods + Monitoring + **Frontend w Dockerze**
- Wszystkie 21 serwisów
- Production-like setup

---

## 📦 Podstawowe Komendy

### Docker Management
```bash
make up          # Backend + Gods + Monitoring (19 serwisów)
make down        # Stop wszystko
make restart     # Restart serwisów
make logs        # Zobacz logi
make ps          # Status serwisów
make clean       # Usuń wszystko + wolumeny
```

### Frontend
```bash
make web-dev     # Frontend lokalnie (yarn dev) ← NAJCZĘŚCIEJ
make web-build   # Build lokalnie
make web-docker  # Frontend w Dockerze
```

### Profiles (konkretne grupy)
```bash
make backend     # Tylko backend (6 serwisów)
make gods        # Tylko Gods AI (6 serwisów)
make monitoring  # Tylko monitoring (7 serwisów)
make all         # WSZYSTKO (21 serwisów)
```

### Utilities
```bash
make build           # Rebuild wszystko
make build-nocache   # Rebuild bez cache
make prune           # Wyczyść Docker system
```

---

## 🎨 Typowy Workflow

### Development (zalecane)
```bash
# 1. Uruchom backend w Dockerze
make up

# 2. Frontend lokalnie (szybkie, hot reload)
make web-dev

# 3. Zobacz status
make ps

# 4. Logi jeśli potrzeba
make logs
```

### Testing w Docker
```bash
# Wszystko w Dockerze (jak production)
make all

# Status
make ps

# Stop
make down
```

### Production Deploy
```bash
# Build bez cache
make build-nocache

# Uruchom wszystko
make all

# Sprawdź
make ps
```

---

## 🔍 Różnice: web-dev vs web-docker

| Feature | `make web-dev` | `make web-docker` |
|---------|----------------|-------------------|
| Środowisko | Lokalnie (host) | Docker kontenery |
| Szybkość | ⚡ Bardzo szybkie | 🐢 Wolniejsze |
| Hot Reload | ✅ Natywny | ⚠️ Przez polling |
| Dockerfile | ❌ Nie używa | ✅ Używa |
| Porty | 5173, 3002 | 5173, 3001 |
| Zależności | Lokalne node_modules | Docker volumes |
| Debugowanie | 🎯 Łatwe | 🔧 Trudniejsze |
| Production-like | ❌ Nie | ✅ Tak |

---

## 🚦 Quick Reference

```bash
# Start development (NAJCZĘŚCIEJ)
make up && make web-dev

# Stop wszystko
make down

# Wszystko w Docker
make all

# Clean i restart
make clean && make up

# Zobacz co działa
make ps

# Logi konkretnego serwisu
docker-compose logs -f thoth
```

---

## 📝 Tips

1. **Development**: Używaj `make web-dev` (frontend lokalnie)
2. **Testing**: Używaj `make all` (wszystko w Docker)
3. **Debugging**: `make web-dev` jest najszybsze
4. **CI/CD**: Używaj `make all` (pełny Docker setup)
5. **Cleanup**: `make clean` przed rebuild

---

**Domyślnie (`make up`)**: Backend + Gods + Monitoring = 19 serwisów
**Profile web**: Frontend w Docker = +2 serwisy = 21 total
**Local dev (`make web-dev`)**: Frontend poza Dockerem (0 serwisów Docker)

