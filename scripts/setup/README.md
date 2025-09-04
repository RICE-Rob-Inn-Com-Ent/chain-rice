# 🛠️ Chain Rice Setup Scripts

Ці скрипти автоматично підготовлюють середовище розробки для Chain Rice на всіх платформах.

## 📁 Файли

### Linux/macOS/WSL
- `setup-environment.sh` - Автоматична підготовка середовища
- `check-system.sh` - Перевірка системних вимог

### Windows
- `setup-environment.bat` - Batch скрипт для Windows
- `setup-environment.ps1` - PowerShell скрипт для Windows
- `check-system.bat` - Batch перевірка для Windows
- `check-system.ps1` - PowerShell перевірка для Windows

## 🚀 Використання

### Через Makefile (рекомендовано)
```bash
# Перший запуск - повна підготовка
make prepare

# Тільки перевірка системи
make check

# Тільки налаштування
make setup

# Швидка підготовка для Windows
make windows-setup
```

### Прямий запуск скриптів

#### Linux/macOS/WSL
```bash
# Підготовка
chmod +x scripts/setup/setup-environment.sh
./scripts/setup/setup-environment.sh

# Перевірка
chmod +x scripts/setup/check-system.sh
./scripts/setup/check-system.sh
```

#### Windows (PowerShell)
```powershell
# Підготовка
powershell -ExecutionPolicy Bypass -File scripts/setup/setup-environment.ps1

# Перевірка
powershell -ExecutionPolicy Bypass -File scripts/setup/check-system.ps1
```

#### Windows (Command Prompt)
```cmd
# Підготовка
scripts\setup\setup-environment.bat

# Перевірка
scripts\setup\check-system.bat
```

## 🔍 Що перевіряють скрипти

### Обов'язкові компоненти
- ✅ Docker (встановлений та запущений)
- ✅ Docker Compose
- ✅ Git
- ✅ Необхідні файли проекту

### Опціональні компоненти
- ⚠️ Go (для розробки блокчейну)
- ⚠️ Node.js (для фронтенд розробки)
- ⚠️ .env файл (створюється автоматично)
- ⚠️ Docker Buildx (налаштовується автоматично)

## 🛠️ Що роблять скрипти підготовки

1. **Перевірка системи** - всі необхідні компоненти
2. **Налаштування Docker Buildx** - для мультиплатформних збірок
3. **Створення директорій** - для логів та даних
4. **Створення .env файлу** - з налаштуваннями за замовчуванням

## 🐛 Вирішення проблем

### Docker не запускається
- **Linux**: `sudo systemctl start docker`
- **Windows**: Запустіть Docker Desktop
- **macOS**: Запустіть Docker Desktop

### PowerShell Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### WSL проблеми
Якщо ви в WSL, використовуйте Linux скрипти:
```bash
./scripts/setup/setup-environment.sh
```

## 📚 Додаткова інформація

Після успішної підготовки ви можете запустити:
- `make dev` - повне середовище розробки
- `make web` - тільки веб сервіси
- `make up` - всі сервіси
- `make build-all` - збірка для всіх платформ
