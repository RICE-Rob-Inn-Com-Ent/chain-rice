# Redis & Kafka Setup dla Meowtopia

## Przegląd

Meowtopia używa **Redis** do cache'owania i **Kafka** do event streaming dla skalowalnej architektury.

## Architektura

```
┌─────────────┐
│  Next.js    │
│  Application│
└──────┬──────┘
       │
       ├─────────────────┐
       │                   │
       ▼                   ▼
┌─────────────┐   ┌─────────────┐
│   Redis     │   │   Kafka     │
│   (Cache)   │   │  (Events)   │
└─────────────┘   └─────────────┘
```

### Redis
- **Cache** - cache'owanie danych dashboardu, ratingów, wyświetleń
- **Session storage** - opcjonalne przechowywanie sesji
- **Rate limiting** - ograniczenie liczby requestów
- **Analytics cache** - szybki dostęp do danych analitycznych

### Kafka
- **Event streaming** - przesyłanie eventów w czasie rzeczywistym
- **Analytics events** - zdarzenia analityczne (dashboard_charts_generated, ratings_aggregated, etc.)
- **Product events** - zdarzenia produktowe (offer_created, product_updated, etc.)
- **Order events** - zdarzenia zamówień
- **Dashboard updates** - aktualizacje dashboardu w czasie rzeczywistym

## Instalacja

### 1. Zainstaluj zależności

```bash
cd .project/meowtopia/web
bun install
```

### 2. Skonfiguruj zmienne środowiskowe

Dodaj do `.env.local` lub `.env.project`:

```env
# Redis (wymagane dla cache)
REDIS_HOST=devcontainer-redis
REDIS_PORT=6379
REDIS_DB=0
REDIS_URL=redis://devcontainer-redis:6379/0

# Kafka (wymagane dla event streaming)
KAFKA_BROKER=devcontainer-kafka:29092
KAFKA_CLIENT_ID=meowtopia-web
```

### 3. Uruchom serwisy

Redis i Kafka są już skonfigurowane w `docker-compose.yml`:

```bash
# Uruchom Redis
docker-compose --profile core up -d redis

# Uruchom Kafka (wymaga Zookeeper)
docker-compose --profile messaging up -d zookeeper kafka
```

## Użycie

### Redis - Cache

```typescript
import { redisHelpers } from "@/lib/redis";

// Cache danych
await redisHelpers.cacheSet("key", data, 300); // 5 minut
const cached = await redisHelpers.cacheGet("key");

// Inwalidacja cache
await redisHelpers.cacheDelete("key");
await redisHelpers.cacheInvalidatePattern("dashboard:*");
```

### Kafka - Event Streaming

```typescript
import { kafkaHelpers } from "@/lib/kafka";

// Wyślij event analityczny
await kafkaHelpers.sendAnalyticsEvent("dashboard_charts_generated", {
  period: "month",
  dataPoints: { orders: 10, revenue: 5 },
});

// Wyślij event produktowy
await kafkaHelpers.sendProductEvent("offer_created", {
  id: productId,
  name: productName,
  type: "special_offer",
});

// Wyślij event zamówienia
await kafkaHelpers.sendOrderEvent("order_created", orderData);
```

## Kafka Topics

Meowtopia używa następujących topiców:

- `meowtopia-analytics` - eventy analityczne
- `meowtopia-dashboard` - aktualizacje dashboardu
- `meowtopia-orders` - eventy zamówień
- `meowtopia-products` - eventy produktowe

## Redis Keys Structure

- `cache:*` - dane cache'owane
- `session:*` - sesje użytkowników
- `ratelimit:*` - rate limiting
- `analytics:*` - dane analityczne

## Integracja z Dashboardem

Dashboard automatycznie:
1. **Cache'uje** dane wykresów w Redis (5 minut)
2. **Wysyła eventy** do Kafka przy generowaniu danych
3. **Pobiera** dane z cache jeśli dostępne
4. **Inwaliduje cache** przy zmianach danych

## Monitoring

### Redis
- Redis Commander: http://localhost:8082
- Sprawdź połączenie: `redis-cli ping`

### Kafka
- Kafka UI: http://localhost:8083 (jeśli skonfigurowane)
- Sprawdź topici: `kafka-topics --list --bootstrap-server localhost:9092`

## Notatki

1. **Redis jest opcjonalny** - aplikacja działa bez Redis, ale bez cache'owania
2. **Kafka jest opcjonalny** - aplikacja działa bez Kafka, ale bez event streaming
3. **Cache invalidation** - automatyczna przy zmianach danych
4. **Event streaming** - wszystkie ważne operacje wysyłają eventy do Kafka



