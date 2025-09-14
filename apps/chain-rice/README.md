# 🐱🍚 ChainRice Ecosystem

**Бухгалтерська система з AI та кафе з котами на блокчейні**

Екосистема з двох додатків: **ChainRice** (бухгалтерська система з AI розпізнаванням чеків) та **Meowtopia** (адміністративна система для кафе з котами). Обидва працюють на спільному блокчейні Cosmos SDK.

## 🚀 Швидкий старт

### Системні вимоги

- **Go 1.21+** - для блокчейну та API
- **Node.js 18+** - для React фронтенду
- **Python 3.11+** - для AI сервісу
- **Docker** (опціонально) - для контейнеризації
- **Tesseract OCR** - для розпізнавання тексту

### Встановлення

1. **Клонуйте репозиторій:**
```bash
git clone <repository-url>
cd rice-dev/apps/chain-rice
```

2. **Встановіть залежності:**
```bash
# Встановити всі залежності
make install
```

3. **Запустіть систему:**
```bash
# Запустити всі сервіси
make start

# Або через Docker
make docker

# Відкрити інтерфейси в браузері
make open
```

## 🎯 Як використовувати

### Основні команди

```bash
# Запустити всі сервіси
make start             # Запустити всі сервіси
make docker           # Запустити через Docker
make open             # Відкрити інтерфейси в браузері

# Окремі додатки
make chainrice        # Тільки ChainRice (бухгалтерія)
make meowtopia        # Тільки Meowtopia (кафе з котами)

# Управління
make stop             # Зупинити всі сервіси
make status           # Перевірити статус сервісів
make clean            # Очистити збірку
```

### Доступні інтерфейси

Після запуску `make open` ви матимете доступ до:

**🍚 ChainRice (Бухгалтерія):**
- **🌐 Фронтенд**: http://localhost:5173
- **🔧 API**: http://localhost:8004
- **🤖 AI сервіс**: http://localhost:8005

**🐱 Meowtopia (Кафе з котами):**
- **🏠 Фронтенд**: http://localhost:5174
- **🔧 API**: http://localhost:8006

**⛓️ Блокчейн:**
- **🌐 REST API**: http://localhost:1317
- **🔗 RPC**: http://localhost:26657

## 📊 Функції системи

### 🍚 ChainRice (Бухгалтерська система)

#### 1. AI розпізнавання чеків
- Автоматичне розпізнавання чеків з фото/PDF
- Використання EasyOCR та Tesseract
- Автоматичне заповнення даних інвойсів
- Підтримка української, польської, англійської мов

#### 2. Управління інвойсами
- Створення та редагування інвойсів
- Автоматичний розрахунок ПДВ
- Категоризація витрат
- Історія з фільтрацією

#### 3. Дашборд з графіками
- Статистика доходів та витрат
- Графіки по місяцях
- Аналіз по категоріях
- Візуалізація тенденцій

#### 4. Blockchain інтеграція
- Запис транзакцій в блокчейн
- Незмінність записів
- Audit trail для контролю

### 🐱 Meowtopia (Кафе з котами)

#### 1. Управління котами
- Каталог котів з фото
- Інформація про здоров'я та характер
- Система усиновлення
- Відстеження активності

#### 2. Меню кафе
- Управління страв та напоїв
- Категорії (їжа, напої, десерти)
- Інформація про алергени
- Рейтинг популярності

#### 3. Бронювання столиків
- Онлайн бронювання
- Управління розкладом
- Спеціальні запити клієнтів
- SMS/email сповіщення

#### 4. Система замовлень
- Прийом замовлень
- Відстеження статусу
- Розрахунок вартості
- Інтеграція з платіжними системами

### ⛓️ Спільний блокчейн
- Cosmos SDK блокчейн
- Спільна мережа для обох додатків
- Децентралізоване зберігання даних
- Smart contracts для автоматизації

## 🔧 Budowanie z Źródeł

### Frontend (React)

```bash
cd frontend

# Instalacja zależności
npm install

# Uruchomienie w trybie development
npm run dev

# Budowanie do produkcji
npm run build

# Podgląd produkcji
npm run preview
```

### Backend (Go)

```bash
# Tax API
cd cmd/tax-api
go mod tidy
go build -o ../../build/tax-api .

# Blockchain
cd ../chainrice
go mod tidy
go build -o ../../build/chainrice .
```

### Wszystko Jednocześnie

```bash
# Zbuduj wszystkie komponenty
make tax-build

# Uruchom system
make tax-dev
```

## 🗄️ Baza Danych

System używa SQLite jako domyślnej bazy danych z automatycznym tworzeniem tabel:

### Tabele

- **contractors** - Dane kontrahentów
- **tax_calculations** - Historia obliczeń podatkowych
- **tax_documents** - Dokumenty podatkowe

### Migracje

```bash
# Utwórz nową migrację
make tax-db-migrate

# Zasiej przykładowe dane
make tax-db-seed

# Reset bazy danych
make tax-db-reset
```

## 🌐 API Endpoints

### Tax API (Port 8003)

```
GET  /health                    # Status API
POST /api/v1/calculate          # Oblicz podatek
GET  /api/v1/contractors        # Lista kontrahentów
POST /api/v1/contractors        # Dodaj kontrahenta
GET  /api/v1/history           # Historia obliczeń
```

### Blockchain API (Port 1317)

```
GET  /cosmos/base/tendermint/v1beta1/node_info  # Info o node
POST /cosmos/tx/v1beta1/txs                     # Wyślij transakcję
```

## 🧪 Testowanie

```bash
# Uruchom wszystkie testy
make tax-test

# Testy frontend
cd frontend
npm test

# Testy backend
cd cmd/tax-api
go test ./...
```

## 📋 Status Usług

```bash
# Sprawdź status wszystkich usług
make tax-status-simple

# Szczegółowy status
make tax-status
```

## 🔍 Monitoring i Logi

```bash
# Pokaż logi systemu
make tax-logs

# Uruchom monitoring
make tax-monitor
```

## 🚀 Wdrażanie

### Development

```bash
make tax-dev
```

### Produkcja

```bash
make tax-deploy
```

## 🛠️ Rozwój

### Struktura Projektu

```
apps/chain-rice/
├── cmd/                    # Aplikacje Go
│   ├── chainrice/         # Blockchain node
│   └── tax-api/          # API podatkowe
├── frontend/              # React frontend
│   ├── src/
│   │   ├── components/    # Komponenty React
│   │   ├── hooks/         # Custom hooks
│   │   └── styles/        # Style CSS
│   └── package.json
├── data/                  # Dane i migracje
├── build/                # Zbudowane pliki
├── Makefile.tax          # Główny Makefile
└── README.md
```

### Dodawanie Nowych Funkcji

1. **Frontend**: Dodaj komponenty w `frontend/src/components/`
2. **Backend**: Dodaj endpointy w `cmd/tax-api/main.go`
3. **Baza danych**: Dodaj tabele w `data/sample.sql`
4. **Styling**: Użyj systemu motywów w `frontend/src/styles/`

## 🐛 Rozwiązywanie Problemów

### Frontend nie uruchamia się

```bash
# Sprawdź porty
lsof -i :5173

# Wyczyść cache npm
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### Tax API nie odpowiada

```bash
# Sprawdź czy API działa
curl http://localhost:8003/health

# Restart API
make tax-stop
make tax-simple
```

### Problemy z bazą danych

```bash
# Sprawdź plik bazy danych
ls -la chainrice_tax.db

# Usuń i odtwórz bazę
rm chainrice_tax.db
make tax-simple
```

## 📞 Wsparcie

- **Dokumentacja**: Sprawdź `ARCHITECTURE.md`
- **Issues**: Zgłoś problem w repozytorium
- **Logi**: Użyj `make tax-logs`

## 📄 Licencja

Ten projekt jest licencjonowany na licencji MIT - zobacz plik [LICENSE](LICENSE) dla szczegółów.

---

**ChainRice Tax System** - Nowoczesne rozwiązanie podatkowe dla Polski 🇵🇱
