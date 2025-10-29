# Docker Cache Management - Szybkie Przeładowanie

## ⚡ Najszybsze Metody (od najszybszej)

### 1️⃣ Restart Kontenera (5 sekund)

```bash
docker-compose restart ui-kit
```

**Kiedy użyć:** Zmieniłeś pliki źródłowe (.tsx, .ts), hot reload powinien zadziałać

**Czas:** ~5s

---

### 2️⃣ Czyszczenie Vite Cache + Restart (10 sekund)

```bash
./docker-hot-reload-fix.sh
```

Lub ręcznie:

```bash
docker-compose exec ui-kit rm -rf /app/.frontend/web/node_modules/.vite
docker-compose restart ui-kit
```

**Kiedy użyć:** Restart nie pomógł, podejrzewasz że Vite ma stary cache

**Czas:** ~10s

---

### 3️⃣ Down + Up (bez rebuild) (15 sekund)

```bash
docker-compose down
docker-compose up -d ui-kit
```

**Kiedy użyć:** Zmieniłeś docker-compose.yml lub env variables

**Czas:** ~15s

---

### 4️⃣ Rebuild z Cache (30 sekund)

```bash
docker-compose down
docker-compose build ui-kit
docker-compose up -d ui-kit
```

**Kiedy użyć:** Zmieniłeś package.json (nowe zależności)

**Czas:** ~30s (używa Docker layer cache)

---

### 5️⃣ Full Rebuild (bez cache) (2-3 minuty)

```bash
docker-compose down
docker-compose build --no-cache ui-kit
docker-compose up -d ui-kit
```

**Kiedy użyć:**

- Zmieniłeś Dockerfile
- Coś jest bardzo zepsute
- Ostateczna opcja

**Czas:** ~2-3 min (pobiera wszystko na nowo)

---

## 🎯 Decyzja Tree

```
Zmiany nie widoczne?
│
├─ Zmieniałeś tylko .tsx/.ts?
│  └─ 1️⃣ Restart (docker-compose restart)
│
├─ Restart nie pomógł?
│  └─ 2️⃣ Wyczyść Vite cache (./docker-hot-reload-fix.sh)
│
├─ Zmieniałeś docker-compose.yml?
│  └─ 3️⃣ Down + Up
│
├─ Dodałeś nowe npm packages?
│  └─ 4️⃣ Rebuild z cache
│
├─ Zmieniałeś Dockerfile?
│  └─ 5️⃣ Full rebuild --no-cache
│
└─ Wszystko inne nie działa?
   └─ 5️⃣ Full rebuild --no-cache (nuclear option)
```

---

## 🔍 Diagnostyka

### Sprawdź czy kontener działa:

```bash
docker ps | grep rice-ui-kit
```

### Sprawdź logi:

```bash
docker-compose logs -f ui-kit
```

### Sprawdź czy pliki są w kontenerze:

```bash
docker-compose exec ui-kit ls -la /app/.frontend/web/app/
```

### Sprawdź konkretny plik:

```bash
docker-compose exec ui-kit cat /app/.frontend/web/app/Layout.tsx | grep gipt1
```

### Sprawdź Vite cache:

```bash
docker-compose exec ui-kit ls -la /app/.frontend/web/node_modules/.vite/
```

---

## 🚀 Automatyczne Skrypty

### `./docker-hot-reload-fix.sh`

Automatycznie:

1. ✓ Sprawdza status kontenera
2. ✓ Czyści Vite cache
3. ✓ Restartuje kontener
4. ✓ Weryfikuje pliki
5. ✓ Pokazuje logi

**Użycie:**

```bash
./docker-hot-reload-fix.sh
```

---

## 🐛 Typowe Problemy

### Problem: "Nie widzę zmian w przeglądarce"

**Rozwiązanie:**

1. Sprawdź czy zmiany są w kontenerze: `docker-compose exec ui-kit cat /path/to/file`
2. Jeśli TAK → wyczyść cache przeglądarki (Ctrl+Shift+R)
3. Jeśli NIE → restart kontenera

### Problem: "Hot reload nie działa"

**Przyczyny:**

- Brak `CHOKIDAR_USEPOLLING=true` w docker-compose.yml
- Volume mapping niepoprawny
- Zbyt wiele plików (limit inotify)

**Rozwiązanie:**

```yaml
environment:
  - CHOKIDAR_USEPOLLING=true # WAŻNE dla Docker!
volumes:
  - .:/app # Mapuj cały root
```

### Problem: "node_modules w kontenerze są stare"

**Rozwiązanie:**

```bash
docker-compose down
docker-compose build --no-cache ui-kit
docker-compose up -d ui-kit
```

---

## 📊 Volumes w docker-compose.yml

```yaml
volumes:
  - .:/app # Cały projekt
  - /app/node_modules # Nie nadpisuj node_modules
  - /app/.frontend/web/node_modules # Nie nadpisuj web node_modules
```

**Co to robi:**

- Mapuje cały projekt do `/app` w kontenerze
- Ale chroni `node_modules` przed nadpisaniem (używa node_modules z kontenera)

---

## ⚡ Przyspieszenie Buildów

### 1. Użyj Docker BuildKit

```bash
export DOCKER_BUILDKIT=1
docker-compose build ui-kit
```

### 2. Multi-stage builds (już w Dockerfile)

```dockerfile
FROM node:20-alpine AS development
# ...
```

### 3. .dockerignore (już utworzony)

```
node_modules
dist
.git
*.log
```

### 4. Cache dependencies layer

```dockerfile
COPY package.json yarn.lock ./
RUN yarn install  # Ten layer będzie cache'owany
COPY . .          # Kod źródłowy w osobnym layer
```

---

## 🎯 Best Practices

### ✅ DO:

- Używaj hot reload dla zmian w kodzie (.tsx/.ts)
- Restartuj kontener dla nowych plików
- Rebuild dla nowych dependencies
- `--no-cache` tylko w ostateczności

### ❌ DON'T:

- Nie używaj `--no-cache` rutynowo (wolne!)
- Nie commituj `node_modules/` do git
- Nie mapuj node_modules jako volume (`- ./node_modules:/app/node_modules` ❌)

---

## 🔧 Komendy Pomocnicze

```bash
# Restart wszystkich kontenerów
docker-compose restart

# Restart konkretnego
docker-compose restart ui-kit

# Rebuild konkretnego
docker-compose build ui-kit

# Rebuild wszystkich
docker-compose build

# Rebuild bez cache
docker-compose build --no-cache

# Sprawdź obrazy
docker images | grep rice

# Usuń stare obrazy
docker image prune -a

# Usuń wszystkie kontenery
docker-compose down

# Usuń z volumes
docker-compose down -v

# Rebuild + Up w jednej komendzie
docker-compose up --build ui-kit

# Force recreate
docker-compose up --force-recreate ui-kit
```

---

## 📈 Monitoring Performance

### Sprawdź rozmiar obrazów:

```bash
docker images | grep rice
```

### Sprawdź zużycie zasobów:

```bash
docker stats rice-ui-kit
```

### Sprawdź czas buildu:

```bash
time docker-compose build ui-kit
```

---

## 🎊 Podsumowanie

**Dla 95% przypadków:**

```bash
./docker-hot-reload-fix.sh
```

**Dla poważnych problemów:**

```bash
docker-compose down
docker-compose build --no-cache ui-kit
docker-compose up -d ui-kit
```

**Sprawdzenie czy działa:**

```bash
docker-compose logs -f ui-kit
curl http://localhost:3001
```

---

**Hot reload + Docker = ❤️ + szybkie iteracje!**
