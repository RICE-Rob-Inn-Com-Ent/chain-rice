# CerAI LoRA - Fine-tuning dla Polskich Faktur

Kontener Docker do trenowania i używania adapterów LoRA (Low-Rank Adaptation) dla modeli AI w CerAI.

## Przegląd

Ten kontener umożliwia:
- **Trenowanie adapterów LoRA** dla modeli Bielik (polski język) i formatter (JSON output)
- **Ładowanie adapterów** do inference
- **Optymalizację pamięci** - 8-bit quantization dla 8GB VRAM
- **Zarządzanie modelami** - cache i persistent storage

## Struktura

```
cerai-lora/
├── Dockerfile              # Obraz z PyTorch, CUDA, PEFT
├── docker-compose.yml      # Konfiguracja kontenera
├── requirements.txt        # Zależności Python
├── scripts/
│   ├── train_lora.py      # Skrypt trenowania
│   └── load_lora.py       # Skrypt ładowania adapterów
├── models/                 # Cache modeli (volume)
├── adapters/              # Wytrenowane adaptery LoRA (volume)
└── data/                  # Dane treningowe (volume)
```

## Modele

### Bielik (Polski język)
- **Base model**: `allegro/herbert-base-cased` (lub inny polski model)
- **Adapter**: `bielik-invoice-extraction`
- **Zastosowanie**: Ekstrakcja danych z polskich faktur

### Formatter (JSON output)
- **Base model**: `Qwen/Qwen2.5-3B-Instruct`
- **Adapter**: `formatter-json-output`
- **Zastosowanie**: Formatowanie odpowiedzi do JSON

## Uruchomienie

### 1. Uruchom kontener

**Szybki start (zalecane):**
```bash
cd .project/ceramix/bot/core/cerai-lora
./start.sh
```

**Lub ręcznie:**
```bash
cd .project/ceramix
docker compose --profile ceramix build cerai-lora
docker compose --profile ceramix up -d cerai-lora
```

**Uwaga:** Kontener wymaga profilu `ceramix` do uruchomienia, ponieważ jest częścią stacku ceramix.

### 2. Trenuj adaptery

```bash
# Trenuj wszystkie adaptery (używa domyślnych danych)
docker exec -it cerai-lora python scripts/train_lora.py

# Lub z własnymi danymi
docker exec -it cerai-lora python scripts/train_lora.py \
  --data-path /app/data/custom_training.json
```

### 3. Sprawdź dostępne adaptery

```bash
docker exec -it cerai-lora python scripts/load_lora.py
```

## Konfiguracja

### Zmienne środowiskowe

```yaml
# Modele
MODEL_NAME_BIELIK: "allegro/herbert-base-cased"
MODEL_NAME_FORMATTER: "Qwen/Qwen2.5-3B-Instruct"

# LoRA parameters
LORA_R: 8                    # Rank
LORA_ALPHA: 16              # Alpha scaling
LORA_DROPOUT: 0.1           # Dropout

# Training
BATCH_SIZE: 4
GRADIENT_ACCUMULATION_STEPS: 4
LEARNING_RATE: 2e-4
NUM_EPOCHS: 3
MAX_LENGTH: 512

# Optional: Weights & Biases
WANDB_API_KEY: ""           # Dla tracking eksperymentów
```

## Format danych treningowych

### Bielik (ekstrakcja faktur)

```json
[
  {
    "text": "Przeanalizuj tę fakturę i wyciągnij kluczowe informacje:\n\nFAKTURA\nNumer: 11646/F/229/25\n..."
  },
  {
    "text": "Kolejny przykład faktury..."
  }
]
```

### Formatter (JSON output)

```json
[
  {
    "text": "Sformatuj te dane do JSON:\n\nNumer faktury: 11646/F/229/25\n...\n\nZwróć JSON z polami: invoice_number, date, seller..."
  }
]
```

## Integracja z CerAI Server

W `cerai_server.py`:

```python
from scripts.load_lora import LoRALoader

# Load adapters
loader = LoRALoader(adapters_dir="/app/adapters")

# Load Bielik adapter
bielik_model, bielik_tokenizer = loader.load_adapter(
    base_model_name="allegro/herbert-base-cased",
    adapter_name="bielik-invoice-extraction"
)

# Load Formatter adapter
formatter_model, formatter_tokenizer = loader.load_adapter(
    base_model_name="Qwen/Qwen2.5-3B-Instruct",
    adapter_name="formatter-json-output"
)
```

## Wymagania sprzętowe

- **GPU**: NVIDIA z CUDA support (minimum 8GB VRAM)
- **RAM**: 16GB+ recommended
- **Storage**: ~20GB dla modeli i adapterów

## Optymalizacja dla 8GB VRAM

Kontener używa:
- **8-bit quantization** (bitsandbytes)
- **Gradient accumulation** (batch_size=4, accumulation=4)
- **LoRA** zamiast full fine-tuning (znacznie mniej pamięci)

## Volumes

- `cerai-lora-models`: Cache modeli HuggingFace
- `cerai-lora-adapters`: Wytrenowane adaptery LoRA
- `cerai-lora-data`: Dane treningowe

## Monitoring

### TensorBoard

```bash
# Uruchom TensorBoard
docker exec -it cerai-lora tensorboard --logdir /app/adapters --port 6006

# Otwórz w przeglądarce
http://localhost:6006
```

### Weights & Biases

Ustaw `WANDB_API_KEY` w docker-compose.yml dla automatycznego tracking.

## Troubleshooting

### Out of Memory

- Zmniejsz `BATCH_SIZE` do 2 lub 1
- Zwiększ `GRADIENT_ACCUMULATION_STEPS`
- Użyj mniejszego base modelu

### Model not found

- Sprawdź czy model istnieje na HuggingFace
- Upewnij się że `TRANSFORMERS_CACHE` jest ustawiony

### Adapter not loading

- Sprawdź czy adapter został wytrenowany: `ls /app/adapters/`
- Sprawdź logi: `docker logs cerai-lora`

## Referencje

- [PEFT Documentation](https://huggingface.co/docs/peft)
- [LoRA Paper](https://arxiv.org/abs/2106.09685)
- [Transformers Documentation](https://huggingface.co/docs/transformers)

