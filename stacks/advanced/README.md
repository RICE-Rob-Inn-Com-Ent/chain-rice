# Zaawansowane przykłady (Senior) — Stack demonstracyjny

Ten katalog zawiera wysokopoziomowe, seniorskie przykłady architektoniczne i techniczne w wielu językach. Każdy przykład skupia się na aspektach istotnych w pracy Senior/Staff (spójność domenowa, testowalność, obserwowalność, odporność, wydajność, bezpieczeństwo).

## Ocena dojrzałości języków (gwiazdki)

| Język | Ekosystem web | Wydajność | Narzędzia | Obserwowalność | Ogółem |
|-------|----------------|-----------|-----------|----------------|--------|
| Go    | ⭐⭐⭐⭐☆         | ⭐⭐⭐⭐⭐     | ⭐⭐⭐⭐☆    | ⭐⭐⭐⭐☆         | ⭐⭐⭐⭐☆ |
| Python| ⭐⭐⭐⭐☆         | ⭐⭐⭐☆      | ⭐⭐⭐⭐⭐    | ⭐⭐⭐⭐☆         | ⭐⭐⭐⭐☆ |
| TS/JS | ⭐⭐⭐⭐⭐         | ⭐⭐⭐☆      | ⭐⭐⭐⭐⭐    | ⭐⭐⭐⭐☆         | ⭐⭐⭐⭐☆ |
| Rust  | ⭐⭐⭐☆          | ⭐⭐⭐⭐⭐     | ⭐⭐⭐☆     | ⭐⭐⭐⭐☆         | ⭐⭐⭐⭐  |

Uwaga: Oceny są subiektywne i oparte na doświadczeniu projektowym oraz dojrzałości ekosystemów.

## Przykłady

- Go
  - `go/concurrency/pool.go`: ograniczanie równoległości i zarządzanie błędami (fan-in/fan-out, semafora, context).
- Python
  - `python/asyncio/structured_concurrency.py`: zadania nadrzędne/podrzędne, timeouts, anulowanie, backoff.
- TypeScript
  - `ts/architecture/trpc-zod-example.ts`: walidacja kontraktów (Zod) + typowany RPC (tRPC) + rozdział warstw.
- Rust
  - `rust/axum/observability.rs`: Axum z metrykami Prometheus i trace'ingiem OpenTelemetry.
- SQL
  - `sql/indexing/advanced_indexes.sql`: indeksy częściowe, BRIN, wielokolumnowe, przykłady na realnych zapytaniach.

## Zasady

- Każdy przykład powinien być maksymalnie czytelny i komentować „dlaczego”, nie „co”.
- Preferujemy niewielkie, kompletne pliki, które można szybko uruchomić/testować.
- Wspieramy obserwowalność (metryki, trace, logowanie) i odporność (timeouts, circuit-breakers).