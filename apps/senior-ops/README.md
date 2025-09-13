# senior-ops — Mikrousługa Go (Hexagonal + gRPC/HTTP)

Zaawansowana mikrousługa operacyjna zbudowana w Go, pokazująca praktyki Senior/Staff:
- Architektura heksagonalna (domain ↔ application ↔ adapters)
- Transport: gRPC (public API) oraz HTTP (admin/metrics)
- Obserwowalność: Prometheus, OpenTelemetry traces, strukturalne logi
- Odporność: context timeouts, backoff, circuit-breakers (hook do gobreaker)
- Testowalność: testy jednostkowe i kontraktowe (gomock/testcontainers — TODO)

## Uruchomienie lokalne

```bash
make dev         # uruchamia środowisko deweloperskie (top-level)
```

Lub bezpośrednio:
```bash
cd apps/senior-ops
GO111MODULE=on go run ./cmd/server
```

HTTP: `http://localhost:8088/health`  
Metrics: `http://localhost:8088/metrics`  
gRPC: `localhost:9098`

## Struktura

```
apps/senior-ops/
  cmd/server/main.go           # bootstrap i DI
  internal/
    domain/                   # reguły biznesowe
    app/                      # use-case'y (orchestration)
    adapters/
      grpc/                   # serwer gRPC
      http/                   # serwer HTTP (admin/health/metrics)
      repo/                   # przykład adaptera (in-memory / postgres)
    observability/            # metryki, tracing, logger
  proto/                      # definicje gRPC
  go.mod / go.sum
  Dockerfile
```

## Funkcjonalność demo

- `CreateJob` / `GetJob` — rejestracja i pobieranie zadań operacyjnych (idempotentne)
- Metryki: czas przetwarzania, liczba błędów, QPS
- Trace: propagacja contextu w warstwach (otel http/grpc)

## Jakość

- Linter: `golangci-lint`
- Testy: `go test ./...`

## Produkcja

- Healthchecks (readiness/liveness)
- Konfiguracja przez zmienne środowiskowe
- GRPC + h2c dla reverse proxy