# CerAI Core

Główny moduł bota CerAI dla Ceramix.

## Struktura

```
core/
├── cerai_server.py       # Główny FastAPI serwer CerAI
├── __init__.py           # Moduł Python
├── requirements.txt      # Zależności Python
├── receipts/            # Folder z przykładowymi paragonami
│   ├── README.md
│   ├── expected_output.json
│   └── [sample images]  # Dodaj tutaj przykładowe paragony (JPG, PNG, PDF)
├── test_receipts.py     # Skrypt testowy do testowania OCR
├── rag_example.py       # Przykład RAG (referencja)
└── langgraph/           # Przykłady LangGraph (referencja)
```

## Pliki

### cerai_server.py
Główny serwer FastAPI z endpointami:
- `/api/chat` - Chat z botem (accounting/client_management)
- `/api/ocr` - OCR dla plików obrazów
- `/api/ocr/base64` - OCR dla obrazów w base64
- `/api/reports/generate` - Generowanie raportów
- `/api/health` - Health check

### receipts/
Folder z przykładowymi paragonami i fakturai do testowania OCR.
Dodaj tutaj przykładowe obrazy paragonów (JPG, PNG, PDF).

### test_receipts.py
Skrypt testowy do przetestowania OCR na przykładowych paragonach:
```bash
python core/test_receipts.py
```

## Docker

Kontener jest skonfigurowany w `docker-compose.ceramix.yml` jako `ceramix-bot`.

## Uruchomienie

```bash
# Z poziomu głównego katalogu projektu
docker compose -f docker-compose.yml -f .devcontainer/docker-compose.dev.yml -f .project/ceramix/docker-compose.ceramix.yml up ceramix-bot

# Lub bezpośrednio
cd .project/ceramix/bot
docker build -t ceramix-bot .
docker run -p 8000:8000 ceramix-bot
```

## Dodawanie przykładowych paragonów

1. Umieść pliki obrazów (JPG, PNG, PDF) w folderze `receipts/`
2. Opcjonalnie: zaktualizuj `expected_output.json` z oczekiwanymi danymi
3. Uruchom test: `python core/test_receipts.py`




