## Backend (FastAPI)

### Run locally
```bash
cd meowtopia/backend
poetry install
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Docker (hot reload)
```bash
docker compose --profile app up -d meowtopia-backend meowtopia-db
```

### Test
```bash
pytest -q
```
