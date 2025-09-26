# 🚀 rice-dev: Unified Nix Development Environment

**Unified Nix dev shells with Bazel integration for multi-language development**

## 🎯 Швидкий старт

### 1. Встановлення Nix

```bash
# Встановити Nix (якщо ще не встановлено)
curl --proto '=https' --tlsv1.2 -sSf https://nixos.org/nix/install | sh

# Перезавантажити shell або виконати:
source ~/.nix-profile/etc/profile.d/nix.sh
```

### 2. Клонування проекту

```bash
git clone <your-repo-url> rice-dev
cd rice-dev
```

### 3. Запуск режиму розробки

```bash
# Ввійти в default Nix shell
nix develop

# Або використовувати Bazel
bazel run //:dev
```

## 🛠️ Доступні середовища розробки

### 🤖 AI & Bot Development
```bash
nix develop .#bot-core              # Мінімальне Python середовище для AI
nix develop .#bot-integration       # Інтеграція з чат-платформами
nix develop .#bot-julia-models      # Julia для моделювання
nix develop .#bot-finance-reporting # Аналітика та звітність
```

### 🔧 Backend Development
```bash
nix develop .#go-backend            # Go з Cosmos/Tendermint
nix develop .#dotnet-bridge         # .NET міст
nix develop .#beam-bridge           # Erlang/Elixir міст
nix develop .#python-fastapi-bridge # Python FastAPI міст
nix develop .#jvm-bridge            # Java міст
nix develop .#php-bridge            # PHP міст
```

### ⛓️ Blockchain & Smart Contracts
```bash
nix develop .#rust-cosmos           # Rust для блокчейну
nix develop .#solidity-evm          # Solidity для EVM
```

### 📱 Frontend Development
```bash
nix develop .#flutter-dart          # Flutter/Dart
nix develop .#kotlin-android        # Kotlin для Android
nix develop .#swift-ios              # Swift для iOS (macOS only)
nix develop .#angular-frontend      # Angular
nix develop .#next-frontend         # Next.js
nix develop .#nuxt-frontend         # Nuxt.js
nix develop .#ts-shared             # TypeScript shared
```

### 🚀 DevOps & Infrastructure
```bash
nix develop .#ansible               # Ansible
nix develop .#k8s                   # Kubernetes
nix develop .#terraform             # Terraform
nix develop .#bazel-dev             # Bazel development
```

## 🔨 Bazel команди

### Базові операції
```bash
# Ввійти в default Nix shell
bazel run //:dev

# Зібрати всі цілі з Nix
bazel run //:build

# Запустити тести з Nix
bazel run //:test
```

### Toolchain команди
```bash
# Go toolchain
bazel run //:go_toolchain

# Python toolchain
bazel run //:python_toolchain

# Rust toolchain
bazel run //:rust_toolchain

# Protobuf toolchain
bazel run //:proto_toolchain
```

### Збірка конкретних цілей
```bash
# Зібрати Go backend
bazel run //:nix_build_go

# Зібрати Python сервіси
bazel run //:nix_build_python

# Зібрати Rust контракти
bazel run //:nix_build_rust

# Зібрати Protobuf файли
bazel run //:nix_build_proto
```

## 🧪 Тестування інтеграції

```bash
# Запустити повний тест інтеграції
./test_nix_integration.sh
```

Цей скрипт перевіряє:
- ✅ Доступність Nix
- ✅ Валідність flake.nix
- ✅ Роботу Nix shells
- ✅ Інтеграцію з Bazel
- ✅ Доступність toolchains

## 📁 Структура проекту

```
rice-dev/
├── flake.nix              # Nix flake з усіма середовищами розробки
├── .bazelrc               # Базова Bazel конфігурація
├── .bazelrc.nix           # Nix-специфічна Bazel конфігурація
├── rules/                 # Bazel правила для Nix інтеграції
│   ├── nix.bzl           # Основні Nix правила
│   ├── go_toolchain.bzl  # Go toolchain інтеграція
│   ├── python_toolchain.bzl # Python toolchain інтеграція
│   ├── rust_toolchain.bzl # Rust toolchain інтеграція
│   ├── proto_toolchain.bzl # Protobuf toolchain інтеграція
│   └── BUILD.bazel        # BUILD файл для rules
├── libs/                  # Бібліотеки
│   ├── backend/          # Backend сервіси
│   ├── frontend/         # Frontend додатки
│   ├── contract/         # Smart contracts
│   └── proto/            # Protobuf визначення
├── bots/                 # AI боти та моделі
└── projects/             # Основні проекти
```

## 🎯 Переваги

1. **Консистентність** - Однакові залежності в Nix та Bazel
2. **Ізоляція** - Кожен shell має свої залежності
3. **Відтворюваність** - Точні версії пакетів
4. **Швидкість** - Nix кешування + Bazel інкрементальна збірка
5. **Гнучкість** - Легко додавати нові середовища

## 🔧 Конфігурація

### .bazelrc.nix
Містить Nix-специфічні налаштування для Bazel:
- Експорт Nix змінних середовища
- Налаштування toolchains для різних мов
- Інтеграція з Nix store
- Оптимізації для Nix середовища

### Bazel Rules
- **nix_shell** - Вхід в Nix development shell
- **nix_build** - Збірка цілей в Nix shell
- **nix_test** - Тестування в Nix shell
- **nix_toolchain** - Використання toolchain з Nix

## 🚨 Troubleshooting

### Проблеми з Nix
```bash
# Очистити Nix кеш
nix-collect-garbage -d

# Перебудувати flake
nix flake update
```

### Проблеми з Bazel
```bash
# Очистити Bazel кеш
bazel clean --expunge

# Перебудувати всі цілі
bazel build //...
```

### Проблеми з інтеграцією
```bash
# Перевірити .bazelrc.nix
bazel query //... --config=nix

# Тестувати конкретний shell
nix develop .#shell-name --command bazel build //target
```

## 📚 Додаткова документація

- [NIX_BAZEL_INTEGRATION.md](./NIX_BAZEL_INTEGRATION.md) - Детальна документація інтеграції
- [test_nix_integration.sh](./test_nix_integration.sh) - Скрипт тестування

## 🎉 Готово до розробки!

Тепер ви можете:
- ✅ Використовувати Nix пакети в Bazel
- ✅ Мати ізольовані середовища розробки
- ✅ Швидко переключатися між toolchains
- ✅ Автоматично тестувати інтеграцію
- ✅ Масштабувати проект з новими мовами/технологіями

**Проект готовий до продуктивної розробки! 🚀**
