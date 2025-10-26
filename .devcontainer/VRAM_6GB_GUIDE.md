# 🎮 Guide dla 6GB VRAM

## ⚠️ WAŻNE: Quantyzacja jest Obowiązkowa!

Z 6GB VRAM **MUSISZ** używać quantyzowanych modeli. Pełne modele nie zmieszczą się w pamięci.

---

## 📊 Quantyzacja - Co to jest?

**Quantyzacja** to proces kompresji modelu poprzez zmniejszenie precyzji wag z 32-bit float do 4-bit lub 8-bit integer.

### Typy Quantyzacji (Ollama):

| Typ        | Rozmiar | Jakość         | VRAM   | Rekomendacja             |
| ---------- | ------- | -------------- | ------ | ------------------------ |
| **Q4_K_M** | ~4GB    | Bardzo dobra   | ~4.5GB | ✅ **NAJLEPSZE dla 6GB** |
| Q5_K_M     | ~5GB    | Prawie idealna | ~5.5GB | ⚠️ Może być ciasno       |
| Q8_0       | ~7GB    | Prawie FP16    | ~7.5GB | ❌ Za duże               |
| FP16       | ~13GB   | Full           | ~14GB  | ❌ Niemożliwe            |

---

## ⏱️ Czasy Ładowania (z 6GB VRAM)

### Thoth (Mistral 7B Q4_K_M)

**Cold Start** (pierwsze uruchomienie):

- Download modelu: **2-5 minut** (zależy od internetu)
- Load do VRAM: **30-45 sekund**
- **Total**: ~3-6 minut

**Warm Start** (model już pobrany):

- Load do VRAM: **30-45 sekund**
- First token: **5-10 sekund**
- **Total**: ~35-55 sekund

### Dlaczego tak długo?

1. **Download**: Model Q4_K_M to ~4GB - musi się pobrać z ollama.com
2. **Load**: Model musi być załadowany z dysku do VRAM
3. **Warm-up**: Pierwsza inference zawsze jest wolniejsza (CUDA kernels)

---

## 🚀 Quick Start

### 1. Oczyść VRAM

```bash
cd .devcontainer
./clear-vram.sh
```

### 2. Uruchom Tylko Thoth

```bash
docker-compose up -d thoth
```

### 3. Sprawdź Logi

```bash
docker-compose logs -f thoth
```

Poczekaj aż zobaczysz:

```
✅ Model mistral:7b-instruct-q4_K_M loaded successfully
```

### 4. Monitoruj VRAM

```bash
watch -n 1 nvidia-smi
```

---

## 🎯 Optymalizacja dla 6GB

### ✅ CO ROBIĆ:

1. **Tylko jeden bóg naraz**

   ```bash
   # Stop wszystko
   docker-compose down

   # Uruchom tylko Thoth
   docker-compose up -d thoth
   ```

2. **Użyj OLLAMA_KEEP_ALIVE=3m**

   - Model wyładowuje się po 3 minutach bez użycia
   - Oszczędza VRAM gdy nie używasz

3. **Monitoruj pamięć**

   ```bash
   nvidia-smi --query-gpu=memory.used,memory.free --format=csv --loop=1
   ```

4. **Batch size = 1**
   - Przy trenowaniu LoRa używaj batch_size=1

### ❌ CZEGO NIE ROBIĆ:

1. **NIE uruchamiaj wielu bogów jednocześnie**

   ```bash
   # ❌ ZŁE - OOM error!
   docker-compose up -d thoth ra isis
   ```

2. **NIE używaj pełnych modeli**

   ```bash
   # ❌ ZŁE
   GOD_MODEL=mistral:latest  # ~13GB

   # ✅ DOBRE
   GOD_MODEL=mistral:7b-instruct-q4_K_M  # ~4GB
   ```

3. **NIE trenuj przy włączonym bogu**
   - Stop boga przed trenowaniem LoRa

---

## 📈 Performance Metrics (Q4_K_M)

### Thoth (Mistral 7B Q4):

- **Tokens/second**: 15-25 t/s (CPU: i7-12700K, GPU: RTX 3060 6GB)
- **Latency**: 50-100ms
- **Throughput**: 10-15 requests/min
- **VRAM usage**: 4.2GB
- **Jakość**: 95% full model (prawie niezauważalna różnica)

---

## 🔧 Troubleshooting

### Problem: "Out of memory" error

**Rozwiązanie**:

```bash
# 1. Stop wszystko
docker-compose down

# 2. Wyczyść VRAM
./clear-vram.sh

# 3. Sprawdź co używa GPU
nvidia-smi

# 4. Kill procesy jeśli trzeba
nvidia-smi --query-compute-apps=pid --format=csv,noheader | xargs kill -9

# 5. Uruchom ponownie
docker-compose up -d thoth
```

### Problem: Model ładuje się wieki

**Przyczyny**:

1. Wolny dysk (HDD zamiast SSD) ➡️ Przenieś na SSD
2. Pierwsza instalacja ➡️ Model musi się pobrać
3. Pełny VRAM ➡️ Wyczyść pamięć

**Rozwiązanie**:

```bash
# Sprawdź czy model jest już pobrany
docker exec ai-god-thoth ollama list

# Jeśli nie ma - pull ręcznie
docker exec ai-god-thoth ollama pull mistral:7b-instruct-q4_K_M
```

### Problem: Wolne inferencing

**Optymalizacja**:

```bash
# Dodaj do docker-compose.yml
environment:
  - OLLAMA_NUM_PARALLEL=2  # Zamiast 4
  - OLLAMA_NUM_GPU=1
  - OLLAMA_GPU_LAYERS=33   # Wszystkie warstwy na GPU
```

---

## 🎓 Dalsza Optymalizacja

### 1. Użyj mniejszych modeli dla niektórych zadań

```yaml
# Thoth może używać Mistral 7B Q4
GOD_MODEL=mistral:7b-instruct-q4_K_M  # 4GB

# Dla prostszych zadań - użyj TinyLlama
GOD_MODEL=tinyllama:1.1b-q4_K_M  # 700MB (!)

# Dla kodu - CodeLlama
GOD_MODEL=codellama:7b-instruct-q4_K_M  # 4GB
```

### 2. Offload część do CPU

```yaml
environment:
  - OLLAMA_GPU_LAYERS=20 # Tylko 20 warstw na GPU
  # Reszta na CPU - wolniejsze ale działa
```

### 3. Użyj swap dla ekstremalnych przypadków

```bash
# UWAGA: Bardzo wolne, tylko emergency
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 📚 Dodatkowe Zasoby

- [Ollama Quantization Guide](https://github.com/ollama/ollama/blob/main/docs/quantization.md)
- [Model Library](https://ollama.com/library)
- [GPU Memory Optimization](https://github.com/ollama/ollama/blob/main/docs/gpu.md)

---

## 🆘 Potrzebujesz Pomocy?

**Szybkie komendy diagnostyczne**:

```bash
# Status GPU
nvidia-smi

# Status kontenerów
docker-compose ps

# Logi Thoth
docker-compose logs -f thoth

# Ile VRAM zostało?
nvidia-smi --query-gpu=memory.free --format=csv,noheader

# Jakie modele są załadowane?
docker exec ai-god-thoth ollama ps
```

---

## 🎯 TL;DR

1. **Tylko Q4_K_M quantization** dla 6GB VRAM
2. **Jeden bóg naraz** - nie więcej!
3. **Cold start: 3-6 minut** (download + load)
4. **Warm start: 30-45 sekund** (tylko load)
5. **Użyj `./clear-vram.sh`** przed startem
6. **Monitor z `nvidia-smi`**

---

𓅝 **Niech Thoth prowadzi Cię mądrze przez ograniczenia VRAM!** 𓁹
