# 🏗️ Architektura ChainRice Tax System

**Dokumentacja architektury polskiego systemu kontroli podatkowej**

## 📋 Przegląd Systemu

ChainRice Tax System to kompleksowy system do zarządzania podatkami zbudowany w architekturze mikroserwisów, integrujący nowoczesne technologie webowe z blockchain Cosmos SDK.

### 🎯 Główne Komponenty

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │    Tax API      │    │   Blockchain    │
│   (Port 5173)   │◄──►│   (Port 8003)   │◄──►│  (Port 1317)    │
│                 │    │                 │    │                 │
│ • Kalkulator    │    │ • REST API      │    │ • Cosmos SDK    │
│ • Wykresy       │    │ • SQLite DB     │    │ • Transakcje    │
│ • Kontrahenci   │    │ • CORS          │    │ • Audit Trail   │
│ • Motywy        │    │ • JSON          │    │ • Niezmienność  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🗂️ Struktura Katalogów

```
apps/chain-rice/
├── 📁 cmd/                          # Aplikacje Go
│   ├── 📁 chainrice/                # Blockchain node
│   │   ├── 📄 main.go              # Główny plik blockchain
│   │   ├── 📄 go.mod               # Zależności blockchain
│   │   └── 📄 go.sum               # Checksumy zależności
│   └── 📁 tax-api/                 # API podatkowe
│       ├── 📄 main.go              # Główny serwer API
│       ├── 📄 go.mod               # Zależności API
│       └── 📄 go.sum               # Checksumy API
│
├── 📁 frontend/                     # React frontend
│   ├── 📁 src/
│   │   ├── 📁 components/          # Komponenty React
│   │   │   ├── 📄 App.tsx          # Główny komponent aplikacji
│   │   │   ├── 📄 TaxCalculator.tsx # Kalkulator podatków
│   │   │   ├── 📄 TaxCharts.tsx    # Komponent wykresów
│   │   │   ├── 📄 TaxHistory.tsx   # Historia obliczeń
│   │   │   ├── 📄 SettingsPanel.tsx # Panel ustawień
│   │   │   ├── 📄 ContractorForm.tsx # Formularz kontrahentów
│   │   │   ├── 📄 ContractorList.tsx # Lista kontrahentów
│   │   │   ├── 📄 ThemeSelector.tsx # Selektor motywów
│   │   │   └── 📄 ThemePreview.tsx  # Podgląd motywów
│   │   ├── 📁 hooks/               # Custom React hooks
│   │   │   └── 📄 useTheme.ts      # Hook zarządzania motywami
│   │   ├── 📁 styles/              # Style CSS
│   │   │   └── 📄 themes.css       # Definicje motywów
│   │   ├── 📄 index.css            # Główne style
│   │   └── 📄 main.tsx             # Punkt wejścia React
│   ├── 📄 package.json             # Zależności npm
│   ├── 📄 vite.config.ts           # Konfiguracja Vite
│   ├── 📄 tailwind.config.js       # Konfiguracja Tailwind
│   └── 📄 postcss.config.js        # Konfiguracja PostCSS
│
├── 📁 data/                         # Dane i migracje
│   ├── 📄 sample.sql               # Schemat bazy danych
│   └── 📄 ARCHITECTURE.md          # Ta dokumentacja
│
├── 📁 build/                        # Zbudowane pliki
│   ├── 📄 chainrice                # Binarny plik blockchain
│   └── 📄 tax-api                  # Binarny plik API
│
├── 📄 Makefile.tax                  # Główny Makefile
├── 📄 README.md                     # Dokumentacja użytkownika
├── 📄 ARCHITECTURE.md               # Ta dokumentacja
└── 📄 chainrice_tax.db             # Baza danych SQLite
```

## 🔧 Komponenty Systemu

### 1. 🌐 React Frontend (`frontend/`)

**Technologie:**
- React 18+ z TypeScript
- Vite jako bundler
- Tailwind CSS dla stylowania
- Chart.js dla wykresów
- Lucide React dla ikon

**Główne pliki:**
- `src/App.tsx` - Główny komponent aplikacji z routingiem
- `src/components/` - Wszystkie komponenty UI
- `src/hooks/useTheme.ts` - Hook zarządzania motywami
- `src/styles/themes.css` - Definicje 4 motywów wizualnych

**Port:** 5173 (z fallback na 5174, 5175)

### 2. 🇵🇱 Tax API (`cmd/tax-api/`)

**Technologie:**
- Go 1.24+
- Gorilla Mux router
- SQLite baza danych
- CORS middleware

**Funkcje:**
- RESTful API dla obliczeń podatkowych
- Zarządzanie kontrahentami
- Historia obliczeń
- Automatyczne tworzenie bazy danych

**Port:** 8003

**Endpointy:**
```
GET  /health                    # Status zdrowia API
POST /api/v1/calculate          # Oblicz podatek VAT
GET  /api/v1/contractors        # Pobierz kontrahentów
POST /api/v1/contractors        # Dodaj kontrahenta
GET  /api/v1/history           # Historia obliczeń
```

### 3. ⛓️ Blockchain (`cmd/chainrice/`)

**Technologie:**
- Cosmos SDK
- Tendermint consensus
- Go modules

**Funkcje:**
- Niezmienne zapisy podatkowe
- Audit trail transakcji
- Integracja z polskimi systemami podatkowymi

**Port:** 1317

## 🗄️ Baza Danych

### SQLite Schema (`data/sample.sql`)

**Tabela `contractors`:**
```sql
CREATE TABLE contractors (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  nip TEXT UNIQUE NOT NULL,
  regon TEXT,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Tabela `tax_calculations`:**
```sql
CREATE TABLE tax_calculations (
  id TEXT PRIMARY KEY,
  contractor_id TEXT,
  gross_amount REAL NOT NULL,
  net_amount REAL NOT NULL,
  tax_amount REAL NOT NULL,
  tax_rate REAL NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (contractor_id) REFERENCES contractors (id)
);
```

**Tabela `tax_documents`:**
```sql
CREATE TABLE tax_documents (
  id TEXT PRIMARY KEY,
  contractor_id TEXT,
  document_type TEXT NOT NULL,
  document_number TEXT NOT NULL,
  amount REAL NOT NULL,
  tax_amount REAL NOT NULL,
  issue_date DATE NOT NULL,
  due_date DATE,
  status TEXT DEFAULT 'pending',
  file_path TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (contractor_id) REFERENCES contractors (id)
);
```

## 🎨 System Motywów

### Architektura Motywów

System używa CSS Custom Properties (zmiennych CSS) dla dynamicznej zmiany motywów:

**Plik:** `frontend/src/styles/themes.css`

**4 Dostępne Motywy:**

1. **🌙 Violet Dark** - Ciemny fioletowy z eleganckimi odcieniami czerni
2. **☀️ Violet Light** - Jasny fioletowy z białym tłem
3. **🌃 Midnight Purple** - Głęboki fiolet z czarnymi akcentami
4. **🌌 Cosmic Violet** - Kosmiczny fiolet z niebieskimi odcieniami

**Hook:** `frontend/src/hooks/useTheme.ts`
- Zarządzanie stanem motywu
- Persistencja w localStorage
- Automatyczne aplikowanie CSS classes

## 🔄 Przepływ Danych

### 1. Obliczanie Podatków

```
React Frontend → Tax API → SQLite → Blockchain
     ↓              ↓         ↓         ↓
[Formularz]   [POST /api/   [Zapis]  [Transakcja]
              v1/calculate]          blockchain]
```

### 2. Zarządzanie Kontrahentami

```
React Frontend → Tax API → SQLite
     ↓              ↓         ↓
[Formularz]   [POST /api/   [Zapis]
              v1/contractors]
```

### 3. Wyświetlanie Historii

```
React Frontend ← Tax API ← SQLite
     ↓              ↑         ↑
[Wykresy/Lista] [GET /api/   [Odczyt]
                v1/history]
```

## 🚀 Proces Budowania

### Makefile Commands (`Makefile.tax`)

**Podstawowe komendy:**
```bash
make open              # Uruchom i otwórz frontend
make web-open          # Alias dla tax-web-open
make web              # Krótki alias
make tax-status-simple # Status usług
make tax-stop         # Zatrzymaj usługi
```

**Development:**
```bash
make tax-build        # Zbuduj wszystkie komponenty
make tax-test         # Uruchom testy
make tax-lint         # Sprawdź jakość kodu
```

**Database:**
```bash
make tax-db-migrate   # Migracje bazy danych
make tax-db-seed      # Zasiej przykładowe dane
make tax-db-reset     # Reset bazy danych
```

## 🔧 Konfiguracja Środowiska

### Wymagane Porty

- **5173** - React Frontend (Vite dev server)
- **8003** - Tax API (Go HTTP server)
- **1317** - Blockchain API (Cosmos SDK)

### Zmienne Środowiskowe

**Tax API:**
```bash
PORT=8003                    # Port API (domyślnie 8003)
DB_PATH=./chainrice_tax.db  # Ścieżka do bazy SQLite
```

**Frontend:**
```bash
VITE_API_URL=http://localhost:8003  # URL Tax API
VITE_BLOCKCHAIN_URL=http://localhost:1317  # URL Blockchain
```

## 🧪 Testowanie

### Frontend Testing
```bash
cd frontend
npm test                    # Unit testy
npm run test:coverage      # Testy z coverage
```

### Backend Testing
```bash
cd cmd/tax-api
go test ./...              # Unit testy Go
go test -cover ./...       # Testy z coverage
```

### Integration Testing
```bash
make tax-test              # Wszystkie testy
```

## 📊 Monitoring i Logi

### Health Checks

**Tax API:**
```bash
curl http://localhost:8003/health
# Response: {"service":"tax-api","status":"healthy","timestamp":"..."}
```

**Blockchain:**
```bash
curl http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info
```

### Logi

**Tax API Logi:**
- Console output z poziomami logowania
- Structured logging w JSON

**Frontend Logi:**
- Browser DevTools Console
- React DevTools

## 🔒 Bezpieczeństwo

### CORS Configuration
```go
c := cors.New(cors.Options{
    AllowedOrigins: []string{
        "http://localhost:5173",
        "http://localhost:3000"
    },
    AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
    AllowedHeaders: []string{"*"},
})
```

### Walidacja Danych
- Frontend: TypeScript type checking
- Backend: Go struct validation
- Database: SQL constraints

## 🚀 Deployment

### Development
```bash
make open                  # Lokalny development
```

### Production
```bash
make tax-build            # Build wszystkich komponentów
make tax-deploy           # Deploy do produkcji
```

## 🔄 Integracje

### Polskie Systemy Podatkowe
- **KSeF** (Krajowy System e-Faktur) - planowana integracja
- **e-Urząd** - planowana integracja
- **NBP API** - kursy walut

### Blockchain Integracje
- **Cosmos Hub** - główna sieć
- **IBC Protocol** - komunikacja między chainami
- **Tendermint** - consensus algorithm

## 📈 Skalowalność

### Frontend
- Vite dla szybkiego bundlingu
- Code splitting z React.lazy
- Caching z React Query

### Backend
- Gorilla Mux dla wydajnego routingu
- SQLite z indeksami dla szybkich zapytań
- Connection pooling

### Blockchain
- Cosmos SDK dla skalowalności
- Tendermint BFT consensus
- Horizontal scaling z multiple nodes

---

**ChainRice Tax System Architecture** - Kompleksowa dokumentacja architektury 🇵🇱
