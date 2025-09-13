# astro-vision — FastAPI + Celery + Redis + Postgres

Aplikacja demonstracyjna (poziom Senior) do przetwarzania obrazów wsadowych i asynchronicznych:
- FastAPI (REST + OpenAPI)
- Celery (kolejki zadań, retriable, backoff)
- Redis (broker), PostgreSQL (wyniki/metadane)
- Obserwowalność: Prometheus (via exporter), strukturalne logi

## Uruchomienie lokalne

```bash
make dev            # środowisko globalne
```

Bezpośrednio:
```bash
cd apps/astro-vision
poetry install --no-root
poetry run uvicorn app.main:app --reload --port 8089
```

Celery worker:
```bash
poetry run celery -A app.worker worker -l info
```

## Endpoints

- `GET /health` — zdrowie
- `POST /jobs` — utwórz zadanie z obrazem (URL lub upload)
- `GET /jobs/{id}` — status i wynik

## Struktura

```
apps/astro-vision/
  app/
    main.py         # FastAPI bootstrap
    deps.py         # DI, połączenia
    models.py       # SQLAlchemy modele
    schemas.py      # Pydantic schematy
    worker.py       # Celery zadania
  Dockerfile.api
  Dockerfile.worker
  pyproject.toml
  poetry.lock (opcjonalnie)
```