# Prisma + MongoDB Setup dla Meowtopia

## Przegląd

Meowtopia używa **podwójnej bazy danych**:
- **PostgreSQL** (główna baza) - zarządzana przez Prisma
- **MongoDB** (synchronizowana) - dla szybszych zapytań i analityki

## Architektura

```
┌─────────────┐
│  Next.js    │
│  Application│
└──────┬──────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│ PostgreSQL  │   │   MongoDB   │
│  (Prisma)   │   │ (Synchronized)
└─────────────┘   └─────────────┘
```

### PostgreSQL (Prisma)
- Główna baza danych
- Relacyjne dane (użytkownicy, zamówienia, produkty)
- Transakcje ACID
- Migracje zarządzane przez Prisma

### MongoDB
- Synchronizowana kopia danych
- Szybsze zapytania dla analityki
- Opcjonalna (aplikacja działa bez MongoDB)
- Automatyczna synchronizacja przy zmianach

## Instalacja

### 1. Zainstaluj zależności

```bash
bun install
```

### 2. Skonfiguruj zmienne środowiskowe

Dodaj do `.env.local`:

```env
# PostgreSQL (wymagane)
DATABASE_URL="postgresql://meowtopia_user:meowtopia_password@devcontainer-postgres:5432/meowtopia?sslmode=disable"

# MongoDB (opcjonalne)
MEOWTOPIA_MONGODB_URL="mongodb://devcontainer-mongodb:27017"
MEOWTOPIA_MONGODB_DB="meowtopia"
```

### 3. Utwórz tabele w PostgreSQL

```bash
# Opcja 1: Użyj Prisma Migrate (zalecane dla produkcji)
bun run db:migrate

# Opcja 2: Użyj Prisma Push (szybkie dla developmentu)
bun run db:push
```

### 4. Wygeneruj Prisma Client

```bash
bun run db:generate
```

### 5. Zainicjalizuj MongoDB (opcjonalne)

```bash
bun run db:init
```

To utworzy kolekcje i indeksy w MongoDB.

## Użycie

### Synchronizacja danych

Dane są automatycznie synchronizowane z MongoDB przy:
- Rejestracji użytkownika (`/api/auth/register`)
- Aktualizacji użytkownika
- Tworzeniu produktów
- Tworzeniu zamówień
- Aktualizacji koszyka

### Funkcje synchronizacji

```typescript
import { syncUserToMongoDB, syncProductToMongoDB, syncOrderToMongoDB } from '@/prisma/migrate-to-both-dbs';

// Synchronizuj użytkownika
await syncUserToMongoDB(userId, userData);

// Synchronizuj produkt
await syncProductToMongoDB(productId, productData);

// Synchronizuj zamówienie
await syncOrderToMongoDB(orderId, orderData);
```

### Dostęp do MongoDB

```typescript
import { getDatabase } from '@/lib/mongodb';

const db = await getDatabase();
const usersCollection = db.collection('users');
const user = await usersCollection.findOne({ email: 'user@example.com' });
```

## Struktura plików

```
meowtopia/web/
├── prisma/
│   ├── schema.prisma              # Schemat Prisma (PostgreSQL)
│   ├── migrate-to-both-dbs.ts     # Funkcje synchronizacji
│   └── init-both-dbs.ts           # Skrypt inicjalizacyjny
├── lib/
│   ├── prisma.ts                  # Prisma Client
│   └── mongodb.ts                  # MongoDB Client
└── app/
    └── api/
        └── auth/
            └── register/
                └── route.ts       # Przykład synchronizacji
```

## Kolekcje MongoDB

- `users` - Użytkownicy (synchronizowane z PostgreSQL)
- `products` - Produkty (synchronizowane z PostgreSQL)
- `orders` - Zamówienia (synchronizowane z PostgreSQL)
- `carts` - Koszyki (synchronizowane z PostgreSQL)

## Uwagi

1. **MongoDB jest opcjonalne** - aplikacja działa bez MongoDB, ale synchronizacja nie będzie działać
2. **Synchronizacja nie blokuje** - błędy synchronizacji MongoDB nie przerywają operacji PostgreSQL
3. **Spójność danych** - PostgreSQL jest źródłem prawdy, MongoDB jest tylko kopią
4. **Indeksy** - MongoDB automatycznie tworzy indeksy przy inicjalizacji

## Rozwiązywanie problemów

### Prisma nie może połączyć się z PostgreSQL

Sprawdź `DATABASE_URL` w `.env.local` i upewnij się, że PostgreSQL działa.

### MongoDB synchronizacja nie działa

1. Sprawdź `MEOWTOPIA_MONGODB_URL` w `.env.local`
2. Upewnij się, że MongoDB działa
3. Sprawdź logi aplikacji - błędy synchronizacji są logowane, ale nie przerywają działania

### Tabele nie są tworzone

Uruchom:
```bash
bun run db:push
```

Lub:
```bash
bun run db:migrate
```

## Produkcja

W produkcji:
1. Użyj Prisma Migrate zamiast `db:push`
2. Skonfiguruj MongoDB connection pooling
3. Monitoruj synchronizację MongoDB
4. Rozważ użycie MongoDB Atlas dla lepszej wydajności



















































