# Quick Start - CerAI LoRA Container

## Uruchomienie kontenera

Kontener `cerai-lora` jest częścią stacku ceramix i wymaga profilu `ceramix` do uruchomienia.

### 1. Zbuduj i uruchom kontener

```bash
cd /home/mrDinkelman/rice-mono/.project/ceramix

# Zbuduj obraz
docker compose --profile ceramix build cerai-lora

# Uruchom kontener
docker compose --profile ceramix up -d cerai-lora

# Sprawdź status
docker compose --profile ceramix ps cerai-lora
```

### 2. Sprawdź logi

```bash
docker compose --profile ceramix logs -f cerai-lora
```

### 3. Uruchom trening

```bash
# Przez docker exec
docker exec -it cerai-lora python scripts/train_lora.py

# Lub użyj skryptu zarządzania
cd /home/mrDinkelman/rice-mono/.project/ceramix/bot/core/cerai-lora
./scripts/manage_lora.sh train
```

### 4. Testuj API

```bash
# Health check
curl http://localhost:8007/health

# Lista adapterów
curl http://localhost:8007/adapters

# Lista plików treningowych
curl http://localhost:8007/training-data
```

## Alternatywnie: Uruchomienie bez GPU (dla testów)

Jeśli nie masz GPU lub chcesz przetestować bez CUDA, możesz zmodyfikować `docker-compose.yml`:

```yaml
cerai-lora:
  # ... inne ustawienia ...
  deploy:
    # Usuń sekcję resources jeśli nie masz GPU
    # resources:
    #   reservations:
    #     devices:
    #       - driver: nvidia
    #         count: 1
    #         capabilities: [gpu]
```

I użyj CPU-only wersji PyTorch w `requirements.txt` (zmień `torch` na `torch --index-url https://download.pytorch.org/whl/cpu`).

## Troubleshooting

### Kontener nie startuje

```bash
# Sprawdź logi
docker compose --profile ceramix logs cerai-lora

# Sprawdź czy port 8007 jest wolny
netstat -tuln | grep 8007

# Sprawdź czy sieć crice istnieje
docker network ls | grep crice
```

### Brak GPU

Jeśli nie masz GPU, kontener może działać na CPU (będzie wolniejszy). Upewnij się, że:
- Usunąłeś sekcję `deploy.resources` z docker-compose.yml
- Używasz CPU-only wersji PyTorch

### Błąd: "No such container"

Upewnij się, że:
1. Kontener jest uruchomiony: `docker compose --profile ceramix ps`
2. Używasz poprawnej nazwy: `cerai-lora`
3. Używasz profilu `ceramix`: `docker compose --profile ceramix exec cerai-lora ...`



