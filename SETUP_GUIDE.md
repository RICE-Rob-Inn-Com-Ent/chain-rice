# 🚀 Chain Rice - Гід по налаштуванню

## 🎯 Проблема, яку ми вирішили

Ваші команди `make` працювали тільки у вас, але на Windows не працювали навіть Docker. Тепер у вас є автоматична підготовка середовища для всіх платформ!

## 🛠️ Нові команди підготовки

### Перший запуск (рекомендовано)
```bash
make prepare
```
Ця команда:
- ✅ Перевіряє всі системні вимоги
- ✅ Налаштовує Docker Buildx
- ✅ Створює необхідні директорії
- ✅ Створює .env файл з налаштуваннями

### Окремі команди
```bash
# Тільки перевірка системи
make check

# Тільки налаштування
make setup

# Швидка підготовка для Windows
make windows-setup
```

## 🖥️ Підтримувані платформи

### Linux/macOS/WSL
- Автоматично використовує `scripts/setup/setup-environment.sh`
- Підтримує всі Unix-подібні системи

### Windows
- **PowerShell**: `scripts/setup/setup-environment.ps1`
- **Command Prompt**: `scripts/setup/setup-environment.bat`
- **WSL**: автоматично перемикається на Linux скрипти

## 🔧 Що перевіряють скрипти

### Обов'язкові компоненти
- ✅ **Docker** - встановлений та запущений
- ✅ **Docker Compose** - доступний
- ✅ **Git** - встановлений
- ✅ **Файли проекту** - всі необхідні Dockerfile та конфігурації

### Опціональні компоненти
- ⚠️ **Go** - для розробки блокчейну
- ⚠️ **Node.js** - для фронтенд розробки
- ⚠️ **.env файл** - створюється автоматично
- ⚠️ **Docker Buildx** - налаштовується автоматично

## 🚀 Автоматична підготовка

Тепер всі основні команди автоматично підготовлюють середовище:

```bash
# Автоматично запускає prepare перед стартом
make dev          # Повне середовище розробки
make web          # Тільки веб сервіси
make up           # Всі сервіси
make build-all    # Збірка для всіх платформ
```

## 🐛 Вирішення проблем

### Docker не запускається
- **Linux**: `sudo systemctl start docker`
- **Windows**: Запустіть Docker Desktop
- **macOS**: Запустіть Docker Desktop

### PowerShell Execution Policy (Windows)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### WSL проблеми
Якщо ви в WSL, скрипти автоматично використовують Linux версії.

## 📁 Структура нових файлів

```
scripts/setup/
├── setup-environment.sh    # Linux/macOS/WSL підготовка
├── setup-environment.ps1   # Windows PowerShell
├── setup-environment.bat   # Windows Command Prompt
├── check-system.sh         # Linux/macOS/WSL перевірка
├── check-system.ps1        # Windows PowerShell перевірка
├── check-system.bat        # Windows Command Prompt перевірка
└── README.md               # Детальна документація
```

## 🎉 Результат

Тепер ваші команди `make` працюватимуть на:
- ✅ **Linux** (Ubuntu, CentOS, etc.)
- ✅ **macOS** (Intel та Apple Silicon)
- ✅ **Windows** (Command Prompt, PowerShell, WSL)
- ✅ **WSL** (Windows Subsystem for Linux)

### Швидкий старт для нових розробників

1. **Клонуйте репозиторій**
2. **Запустіть підготовку**: `make prepare`
3. **Запустіть розробку**: `make dev`

Все! 🎉

## 📚 Додаткова інформація

- Детальна документація: `scripts/setup/README.md`
- Всі команди: `make help`
- Розробка: `docs/DEVELOPMENT.md`
