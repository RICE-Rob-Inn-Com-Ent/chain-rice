# 🌍 Rice-Dev Ecosystem

**Повна екосистема додатків з блокчейн інтеграцією**

Rice-Dev - це комплексна платформа, що включає два основні додатки, які працюють на спільному блокчейні Cosmos SDK:

- **🍚 ChainRice** - Бухгалтерська система з AI розпізнаванням чеків
- **🐱 Meowtopia** - Адміністративна система для кафе з котами

## 🚀 Швидкий старт

### Системні вимоги

- **Go 1.21+** - для блокчейну та API
- **Node.js 18+** - для React фронтенду
- **Python 3.11+** - для AI сервісу
- **Docker** (опціонально) - для контейнеризації

### Встановлення та запуск

```bash
# Клонуйте репозиторій
git clone <repository-url>
cd rice-dev

# Встановіть всі залежності
make install

# Запустіть всю екосистему
make start

# Відкрийте інтерфейси в браузері
make open
```

### Швидкий запуск (все в одній команді)

```bash
make quick  # Встановить, зібере, запустить та відкриє все
```

## 🎯 Управління з кореня

### Основні команди

```bash
# Екосистема
make start              # Запустити всю екосистему
make stop               # Зупинити всі сервіси
make status             # Перевірити статус сервісів
make clean              # Очистити всі збірки

# Окремі додатки
make chainrice          # Запустити тільки ChainRice
make meowtopia          # Запустити тільки Meowtopia

# Docker
make docker             # Запустити через Docker Compose

# Інтерфейси
make open               # Відкрити всі інтерфейси
make open-chainrice     # Відкрити ChainRice інтерфейси
make open-meowtopia     # Відкрити Meowtopia інтерфейси
```

## 🌐 Доступні інтерфейси

Після запуску `make start`:

### 🍚 ChainRice (Бухгалтерія)
- **Фронтенд**: http://localhost:5173
- **API**: http://localhost:8004
- **AI сервіс**: http://localhost:8005

### 🐱 Meowtopia (Кафе з котами)
- **Фронтенд**: http://localhost:5174
- **API**: http://localhost:8006

### ⛓️ Блокчейн
- **REST API**: http://localhost:1317
- **RPC**: http://localhost:26657

## 📊 Функції екосистеми

### 🍚 ChainRice - Бухгалтерська система

#### AI розпізнавання чеків
- Автоматичне розпізнавання чеків з фото/PDF
- EasyOCR + Tesseract для багатомовного розпізнавання
- Автоматичне заповнення даних інвойсів
- Підтримка української, польської, англійської мов

#### Управління інвойсами
- Створення та редагування інвойсів
- Автоматичний розрахунок ПДВ
- Категоризація витрат
- Історія з фільтрацією та пошуком

#### Дашборд з графіками
- Статистика доходів та витрат
- Графіки по місяцях (лінійні та стовпчасті)
- Кругові діаграми по категоріях
- Аналіз тенденцій та прогнози

#### Blockchain інтеграція
- Запис транзакцій в блокчейн
- Незмінність записів для аудиту
- Smart contracts для автоматизації
- Децентралізоване зберігання даних

### 🐱 Meowtopia - Кафе з котами

#### Управління котами
- Каталог котів з фотографіями
- Детальна інформація (вік, порода, характер)
- Система усиновлення з заявками
- Відстеження здоров'я та активності

#### Меню кафе
- Управління стравами та напоями
- Категорії (їжа, напої, десерти)
- Інформація про алергени
- Рейтинг популярності страв

#### Бронювання столиків
- Онлайн система бронювання
- Управління розкладом роботи
- Спеціальні запити клієнтів
- SMS/email сповіщення

#### Система замовлень
- Прийом замовлень від клієнтів
- Відстеження статусу приготування
- Автоматичний розрахунок вартості
- Інтеграція з платіжними системами

## 🏗️ Архітектура

### Структура проекту

```
rice-dev/
├── Makefile                    # Головне управління
├── README.md                   # Цей файл
├── apps/
│   ├── chain-rice/            # Бухгалтерська система
│   │   ├── frontend/          # React фронтенд
│   │   ├── go/                # Go API сервер
│   │   ├── python/            # Python AI сервіс
│   │   ├── proto/             # Protobuf схеми
│   │   └── docker/            # Docker конфігурація
│   └── meowtopia/             # Кафе з котами
│       ├── src/               # React фронтенд
│       ├── Makefile           # Локальне управління
│       └── package.json       # Залежності
```

### Технологічний стек

#### Frontend
- **React 19** + **TypeScript**
- **Tailwind CSS** для стилізації
- **React Query** для кешування API
- **Recharts** для графіків
- **React Hook Form** + **Zod** для форм

#### Backend
- **Go 1.21** для API серверів
- **gRPC** + **HTTP REST** для комунікації
- **SQLite** для локального зберігання
- **Protobuf** для типізованих API

#### AI/ML
- **Python 3.11** + **FastAPI**
- **EasyOCR** + **Tesseract** для OCR
- **OpenCV** для обробки зображень
- **PIL** для роботи з зображеннями

#### Blockchain
- **Cosmos SDK** для блокчейну
- **Tendermint** для консенсусу
- **gRPC** для блокчейн API
- **Protobuf** для схеми блокчейну

## 🔧 Розробка

### Локальна розробка

```bash
# Розробка ChainRice
cd apps/chain-rice
make start

# Розробка Meowtopia
cd apps/meowtopia
make start

# Розробка з кореня
make chainrice    # Тільки ChainRice
make meowtopia    # Тільки Meowtopia
make start        # Все разом
```

### Docker розробка

```bash
# Запуск через Docker
make docker

# Зупинка Docker контейнерів
docker-compose -f apps/chain-rice/docker-compose.yml down
```

### Тестування

```bash
# Тести всієї екосистеми
make test

# Тести окремих додатків
cd apps/chain-rice && make test
cd apps/meowtopia && make test
```

## 🚀 Deployment

### Production

```bash
# Використання Docker Compose з production профілем
cd apps/chain-rice
docker-compose --profile production up -d
```

### Kubernetes

```bash
# Deployment в Kubernetes
kubectl apply -f k8s/
```

## 📈 Моніторинг

### Статус сервісів

```bash
# Перевірити статус всіх сервісів
make status

# Показати логі
make logs
```

### Health Checks

- **ChainRice API**: http://localhost:8004/health
- **Meowtopia API**: http://localhost:8006/health
- **Python AI**: http://localhost:8005/health
- **Blockchain**: http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info

## 🔐 Безпека

- **CORS** налаштований для фронтенду
- **Input validation** через protobuf схеми
- **SQL injection** захист через prepared statements
- **HTTPS/gRPC** шифрування в транзиті
- **Blockchain** валідація транзакцій

## 📚 Документація

- **Архітектура**: [apps/chain-rice/ARCHITECTURE.md](apps/chain-rice/ARCHITECTURE.md)
- **ChainRice**: [apps/chain-rice/README.md](apps/chain-rice/README.md)
- **Meowtopia**: [apps/meowtopia/README.md](apps/meowtopia/README.md)

## 🤝 Внесок у розробку

1. Fork репозиторій
2. Створіть feature branch
3. Зробіть зміни
4. Додайте тести
5. Створіть Pull Request

## 📄 Ліцензія

MIT License - дивіться файл [LICENSE](LICENSE) для деталей.

---

**Rice-Dev Ecosystem** - сучасна платформа для бухгалтерії та управління бізнесом з інтеграцією блокчейн технологій та AI. 🚀