# Nix-Bazel Integration для rice-dev

Цей документ описує інтеграцію між Nix та Bazel в проекті rice-dev.

## Огляд

Проект rice-dev використовує Nix для управління залежностями та середовищами розробки, а Bazel для збірки та тестування. Інтеграція дозволяє Bazel використовувати пакети та інструменти, налаштовані в Nix flake.

## Структура

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
└── BUILD.bazel           # Основний BUILD файл
```

## Доступні Nix Shells

### AI & Bot Development

- `bot-core` - Мінімальне Python середовище для AI
- `bot-integration` - Інтеграція з чат-платформами
- `bot-julia-models` - Julia для моделювання
- `bot-finance-reporting` - Аналітика та звітність

### Backend Development

- `go-backend` - Go з Cosmos/Tendermint
- `dotnet-bridge` - .NET міст
- `beam-bridge` - Erlang/Elixir міст
- `python-fastapi-bridge` - Python FastAPI міст
- `jvm-bridge` - Java міст
- `php-bridge` - PHP міст

### Blockchain & Smart Contracts

- `rust-cosmos` - Rust для блокчейну
- `solidity-evm` - Solidity для EVM

### Frontend Development

- `flutter-dart` - Flutter/Dart
- `kotlin-android` - Kotlin для Android
- `swift-ios` - Swift для iOS
- `angular-frontend` - Angular
- `next-frontend` - Next.js
- `nuxt-frontend` - Nuxt.js
- `ts-shared` - TypeScript shared

### DevOps & Infrastructure

- `ansible` - Ansible
- `k8s` - Kubernetes
- `terraform` - Terraform
- `bazel-dev` - Bazel development

## Використання

### Базові команди

```bash
# Ввійти в default Nix shell
bazel run //:dev

# Зібрати всі цілі з Nix
bazel run //:build

# Запустити тести з Nix
bazel run //:test
```

### Специфічні toolchains

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

### Пряме використання Nix shells

```bash
# Ввійти в конкретний shell
nix develop .#go-backend
nix develop .#python-fastapi-bridge
nix develop .#rust-cosmos
nix develop .#proto-tools
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

## Конфігурація

### .bazelrc.nix

Цей файл містить Nix-специфічні налаштування для Bazel:

- Експорт Nix змінних середовища
- Налаштування toolchains для різних мов
- Інтеграція з Nix store
- Оптимізації для Nix середовища

### Bazel Rules

#### nix_shell

Створює Bazel правило для входу в Nix development shell.

#### nix_build

Створює Bazel правило для збірки цілей в Nix shell.

#### nix_test

Створює Bazel правило для тестування в Nix shell.

#### nix_toolchain

Створює Bazel правило для використання toolchain з Nix.

## Переваги

1. **Консистентність** - Однакові залежності в Nix та Bazel
2. **Ізоляція** - Кожен shell має свої залежності
3. **Відтворюваність** - Точні версії пакетів
4. **Швидкість** - Nix кешування + Bazel інкрементальна збірка
5. **Гнучкість** - Легко додавати нові середовища

## Тестування

Запустіть тест інтеграції:

```bash
./test_nix_integration.sh
```

Цей скрипт перевіряє:

- Доступність Nix
- Валідність flake.nix
- Роботу Nix shells
- Інтеграцію з Bazel
- Доступність toolchains

## Troubleshooting

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
