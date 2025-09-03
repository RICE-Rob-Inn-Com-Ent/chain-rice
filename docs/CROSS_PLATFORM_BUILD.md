# 🌍 Cross-Platform Docker Build Guide

Цей гід допоможе вам зібрати Chain Rice проект на будь-якій платформі (Windows, macOS, Linux).

## 🚨 Проблеми з залежностями

### Проблема з Rollup
Якщо ви отримуєте помилку:
```
Error: Cannot find module @rollup/rollup-linux-x64-gnu
```

Це означає, що npm/yarn встановив неправильні платформно-специфічні залежності для вашого контейнера.

### Проблема з Yarn 4
Якщо ви отримуєте помилку:
```
Usage Error: Couldn't find the node_modules state file - running an install might help (findPackageLocation)
```

Це проблема з Yarn 4 станом файлів. Використовується npm замість Yarn для стабільності.

## 🔧 Рішення

### 1. Використання крос-платформної збірки

```bash
# Запустіть скрипт крос-платформної збірки
./scripts/build-cross-platform.sh
```

### 2. Ручна збірка з buildx

```bash
# Створіть builder для крос-платформної збірки
docker buildx create --name multiplatform --use

# Зберіть frontend для всіх платформ
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag meowtopia-frontend:latest \
  --file meowtopia/frontend/web/Dockerfile.web.npm \
  ./meowtopia/frontend/web

# Зберіть backend для всіх платформ
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag meowtopia-backend:latest \
  --file meowtopia/backend/Dockerfile.backend \
  ./meowtopia/backend
```

### 3. Використання docker-compose

```bash
# Зберіть всі сервіси
docker-compose build --parallel

# Або запустіть з автоматичною збіркою
docker-compose up --build
```

## 🛠️ Налаштування для різних платформ

### Windows (WSL2/Docker Desktop)
```bash
# Переконайтеся, що увімкнено WSL2 backend
# В Docker Desktop: Settings > General > Use WSL 2 based engine
```

### macOS (Apple Silicon)
```bash
# Для M1/M2 Macs, додайте arm64 платформу
docker buildx build --platform linux/arm64,linux/amd64 ...
```

### Linux
```bash
# Стандартна збірка працює без додаткових налаштувань
docker-compose up --build
```

## 🔍 Діагностика проблем

### Перевірка платформи контейнера
```bash
docker run --rm meowtopia-frontend:latest uname -m
```

### Очищення кешу Docker
```bash
docker system prune -a
docker buildx prune -a
```

### Перевірка buildx
```bash
docker buildx ls
docker buildx inspect --bootstrap
```

## 📝 Нотатки

- Використовується `Dockerfile.web.npm` для frontend (npm замість Yarn для стабільності)
- Всі Dockerfile підтримують `linux/amd64` та `linux/arm64`
- Скрипт `build-cross-platform.sh` автоматизує весь процес
- При проблемах з залежностями, Dockerfile автоматично спробує альтернативні методи встановлення
- Крос-платформна підтримка працює автоматично без додаткових налаштувань
- npm використовується замість Yarn 4 через проблеми зі станом файлів

## 🎯 Результат

Після виконання цих кроків, ваш проект буде працювати на:
- ✅ Windows (WSL2/Docker Desktop)
- ✅ macOS (Intel та Apple Silicon)
- ✅ Linux (всі архітектури)
- ✅ CI/CD системах (GitHub Actions, GitLab CI, тощо)
