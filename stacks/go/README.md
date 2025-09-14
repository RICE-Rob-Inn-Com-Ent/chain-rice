# 🏗️ ChainRice Go Services

**Modułowa architektura usług Go dla systemu kontroli podatkowej**

## 📋 Przegląd Architektury

ChainRice Go Services to zbiór modularnych usług napisanych w Go, które obsługują różne aspekty systemu podatkowego:

### 🎯 Główne Moduły

```
go/
├── 📁 blockchain/          # Blockchain Cosmos SDK
│   ├── 📁 app/            # Aplikacja blockchain
│   ├── 📁 cmd/            # Komendy CLI
│   ├── 📁 x/              # Moduły blockchain
│   └── 📁 config/         # Konfiguracja blockchain
│
├── 📁 accounting-api/      # API księgowości
│   ├── 📁 cmd/            # Główna aplikacja
│   ├── 📁 internal/       # Logika wewnętrzna
│   ├── 📁 pkg/            # Biblioteki współdzielone
│   └── 📁 api/            # Definicje API
│
├── 📁 tax-api/            # API podatkowe
│   ├── 📁 cmd/            # Główna aplikacja
│   ├── 📁 internal/       # Logika wewnętrzna
│   └── 📁 pkg/            # Biblioteki współdzielone
│
├── 📁 shared/             # Współdzielone komponenty
│   ├── 📁 types/          # Typy współdzielone
│   ├── 📁 database/       # Warstwa bazy danych
│   ├── 📁 config/         # Konfiguracja
│   └── 📁 utils/          # Narzędzia pomocnicze
│
└── 📁 docs/               # Dokumentacja
```

## 🔧 Struktura Modułów

### 1. 🌐 Blockchain Module (`blockchain/`)

**Technologie:**
- Cosmos SDK v0.53.0
- CometBFT v0.38.17
- Go 1.24+

**Funkcje:**
- Niezmienne zapisy podatkowe
- Audit trail transakcji
- Integracja z polskimi systemami podatkowymi

### 2. 📊 Accounting API (`accounting-api/`)

**Technologie:**
- Gin HTTP framework
- gRPC
- SQLite/PostgreSQL
- Protocol Buffers

**Funkcje:**
- Zarządzanie fakturami
- Dashboard finansowy
- Raporty księgowe
- Upload plików

### 3. 🧾 Tax API (`tax-api/`)

**Technologie:**
- Gorilla Mux
- SQLite
- CORS middleware

**Funkcje:**
- Obliczenia podatkowe
- Zarządzanie kontrahentami
- Historia obliczeń
- Integracja z blockchain

### 4. 🔗 Shared Components (`shared/`)

**Funkcje:**
- Wspólne typy danych
- Warstwa bazy danych
- Konfiguracja
- Narzędzia pomocnicze

## 🚀 Uruchamianie

### Blockchain
```bash
cd blockchain
go run cmd/chainrice/main.go start
```

### Accounting API
```bash
cd accounting-api
go run cmd/accounting-api/main.go
```

### Tax API
```bash
cd tax-api
go run cmd/tax-api/main.go
```

## 📦 Zarządzanie Zależnościami

Każdy moduł ma własny `go.mod` z odpowiednimi zależnościami:

```bash
# Blockchain
cd blockchain && go mod tidy

# Accounting API
cd accounting-api && go mod tidy

# Tax API
cd tax-api && go mod tidy
```

## 🧪 Testowanie

```bash
# Wszystkie testy
go test ./...

# Testy konkretnego modułu
cd blockchain && go test ./...
cd accounting-api && go test ./...
cd tax-api && go test ./...
```

## 📚 Dokumentacja

- [Blockchain Architecture](blockchain/README.md)
- [Accounting API](accounting-api/README.md)
- [Tax API](tax-api/README.md)
- [Shared Components](shared/README.md)

---

**ChainRice Go Services** - Modułowa architektura usług Go 🇵🇱
