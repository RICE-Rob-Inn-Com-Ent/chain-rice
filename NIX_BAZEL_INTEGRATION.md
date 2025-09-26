# 🔧 Nix-Bazel Integration - Технічна документація

**Детальна технічна документація інтеграції між Nix та Bazel в проекті rice-dev**

> 📖 **Швидкий старт**: Дивіться [README.md](./README.md) для базового використання

## Огляд архітектури

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

## Технічні деталі інтеграції

### Bazel Rules Implementation

#### nix_shell
```python
def _nix_shell_impl(ctx):
    """Implementation for nix_shell rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    
    script_content = """#!/usr/bin/env bash
set -euo pipefail
cd """ + shell.quote(flake_path) + """
exec nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command "$@"
"""
```

#### nix_build
```python
def _nix_build_impl(ctx):
    """Implementation for nix_build rule."""
    # Створює скрипт для збірки цілей в Nix shell
    script_content = """#!/usr/bin/env bash
set -euo pipefail
cd """ + shell.quote(flake_path) + """
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command bazel build """ + " ".join([shell.quote(t) for t in targets]) + """
"""
```

#### nix_test
```python
def _nix_test_impl(ctx):
    """Implementation for nix_test rule."""
    # Створює скрипт для тестування в Nix shell
    script_content = """#!/usr/bin/env bash
set -euo pipefail
cd """ + shell.quote(flake_path) + """
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command bazel test """ + " ".join([shell.quote(t) for t in targets]) + """
"""
```

### Toolchain Integration

#### Go Toolchain
```python
def _nix_go_toolchain_impl(ctx):
    """Implementation for nix_go_toolchain rule."""
    script_content = """#!/usr/bin/env bash
set -euo pipefail
cd """ + shell.quote(flake_path) + """
export GOROOT=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command go env GOROOT)
export GOPATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command go env GOPATH)
export PATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command go env GOROOT)/bin:$PATH
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command "$@"
"""
```

#### Python Toolchain
```python
def _nix_python_toolchain_impl(ctx):
    """Implementation for nix_python_toolchain rule."""
    script_content = """#!/usr/bin/env bash
set -euo pipefail
cd """ + shell.quote(flake_path) + """
export PYTHONPATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command python -c "import sys; print(':'.join(sys.path))")
export PYTHONNOUSERSITE=1
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command "$@"
"""
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

```bash
# Nix development environment integration
build --action_env=NIX_PATH
build --action_env=NIX_STORE
build --action_env=NIX_PROFILES
build --action_env=NIX_DEVELOP_SHELL
build --action_env=NIX_SHELL

# Python configuration for Nix
build --python_path=/nix/store/*-python3-*/bin/python3
build --python_version=PY3
build --action_env=PYTHONPATH
build --action_env=PYTHONNOUSERSITE
build --action_env=LC_ALL
build --action_env=LANG

# Go configuration for Nix
build --@io_bazel_rules_go//go/config:static
build --action_env=GOROOT
build --action_env=GOPATH
build --action_env=GOBIN

# Rust configuration for Nix
build --action_env=CARGO_HOME
build --action_env=RUSTUP_HOME
build --action_env=RUST_SRC_PATH

# Nix-specific build optimizations
build --experimental_use_hermetic_linux_sandbox
build --sandbox_tmpfs_path=/tmp
build --sandbox_tmpfs_path=/nix
```

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

### Автоматичне тестування

Запустіть тест інтеграції:

```bash
./test_nix_integration.sh
```

Цей скрипт перевіряє:

- ✅ Доступність Nix
- ✅ Валідність flake.nix
- ✅ Роботу Nix shells
- ✅ Інтеграцію з Bazel
- ✅ Доступність toolchains

### Результат тестування

```
🧪 Testing Nix-Bazel Integration for rice-dev
==============================================
1. Testing Nix availability...
✅ Nix is available: nix (Nix) 2.31.2
2. Testing flake.nix validity...
✅ flake.nix is valid
3. Testing Nix development shells...
  ✅ default shell works
  ✅ go-backend shell works
  ✅ python-fastapi-bridge shell works
  ✅ rust-cosmos shell works
  ✅ proto-tools shell works
4. Testing Bazel with Nix integration...
✅ Bazel can query targets
5. Testing Nix shell targets...
✅ Nix shell targets are available
6. Testing toolchain targets...
  ✅ nix_go_toolchain is available
  ✅ nix_python_toolchain is available
  ✅ nix_rust_toolchain is available
  ✅ nix_proto_toolchain is available
7. Testing build targets...
✅ Nix build targets are available
8. Testing .bazelrc.nix integration...
✅ .bazelrc.nix exists
✅ Nix environment variables configured

🎉 Nix-Bazel Integration Test Complete!
```

### Ручне тестування

```bash
# Тестувати конкретний shell
nix develop .#shell-name --command echo "Shell works"

# Тестувати Bazel з Nix
nix develop .#bazel-dev --command bazel query //...

# Тестувати toolchain
bazel run //:go_toolchain -- --version
```

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
