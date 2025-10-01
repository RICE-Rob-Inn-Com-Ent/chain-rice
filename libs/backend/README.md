# Rice Dev Backend

Це основний бекенд сервіс для Rice Dev платформи, який включає в себе:

## Модулі

### 1. Blockchain Module (`/blockchain`)
- **Cosmos SDK** блокчейн з власним токеном
- **Token Management** - створення та управління токенами
- **Smart Contracts** - підтримка смарт-контрактів
- **Consensus** - алгоритм консенсусу
- **Wallet Integration** - інтеграція з гаманцями

### 2. Database Module
- Підключення до бази даних
- ORM та міграції
- Кешування

### 3. API Module
- REST API ендпоінти
- GraphQL підтримка
- Middleware та аутентифікація

## Структура

```
libs/backend/
├── main.go                 # Основний файл сервера
├── go.mod                  # Go модуль з залежностями
├── BUILD.bazel            # Bazel конфігурація
├── blockchain/            # Блокчейн модуль
│   ├── app/              # Cosmos SDK додаток
│   ├── config/           # Конфігурація блокчейну
│   ├── scripts/          # Скрипти для ініціалізації
│   ├── x/tokens/         # Кастомний модуль токенів
│   ├── main.go           # Точка входу для блокчейну
│   └── module.go         # Простий модуль для інтеграції
└── Dockerfile            # Docker конфігурація
```

## Запуск

### Локальний розробка
```bash
cd libs/backend
go run main.go
```

### З Docker
```bash
docker build -t rice-dev-backend .
docker run -p 8080:8080 rice-dev-backend
```

## API Ендпоінти

- `GET /` - Основний інформаційний ендпоінт
- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /api` - API статус
- `GET /blockchain` - Статус блокчейн модуля
- `GET /blockchain/status` - Детальний статус блокчейну
- `POST /blockchain/tokens` - Створення токенів

## Блокчейн Функціональність

Блокчейн модуль базується на Cosmos SDK і включає:

1. **Token Module** - власний модуль для управління токенами
2. **Standard Cosmos Modules** - auth, bank, staking, governance тощо
3. **IBC Support** - міжблокчейн комунікація
4. **Custom Consensus** - налаштований алгоритм консенсусу

## Конфігурація

Всі конфігурації знаходяться в `blockchain/config/`:
- `app.yaml` - конфігурація додатку
- `config.toml` - конфігурація ноди
- `genesis.json` - початковий стан блокчейну

## Розробка

Для додавання нових функцій:

1. **API ендпоінти** - додайте в `main.go`
2. **Блокчейн модулі** - додайте в `blockchain/x/`
3. **Конфігурація** - оновіть файли в `blockchain/config/`

## Залежності

- Go 1.21+
- Cosmos SDK v0.50.1
- Gin Web Framework
- CometBFT (Tendermint)
