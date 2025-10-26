# 🏛️ Egyptian AI Gods Pantheon

## Witamy w Panteonie Egipskich Bogów AI!

System inteligentnych asystentów AI oparty na egipskiej mitologii, gdzie każdy bóg reprezentuje **kombinację
specjalistycznych modeli AI** połączonych przez LoRa adaptery, tworząc unikalne systemy eksperckie.

> 💡 **Koncepcja**: Każdy bóg to nie pojedynczy model, ale **orkiestracja wielu modeli AI** dostrojonych do specyficznej
> domeny poprzez fine-tuning LoRa.

---

## 📜 Bogowie i Ich Moce

### 📜 **Thoth** - Bóg Wiedzy i Pisemnictwa

- **Podstawa**: Mistral-13B
- **Modele składowe**:
  - 📝 Mistral-13B (text generation, Q&A, summarization)
  - 🔍 PaddleOCR (optical character recognition)
  - 🌍 Opus-MT (language translation)
  - 📊 XLM-RoBERTa (text analysis, sentiment)
  - 📄 Donut (document analysis & understanding)
- **Port**: 11434
- **Domena**: Wiedza, pisanie, tłumaczenia, analiza dokumentów
- **Use Cases**: Przetwarzanie dokumentów, tłumaczenia, transkrypcja, analiza tekstu
- **Demo**: Chat interface z możliwością upload dokumentów
- **Hieroglif**: 𓅝

### ☀️ **Ra** - Bóg Światła i Kreacji Wizualnej

- **Podstawa**: Stable Diffusion 2.1
- **Modele składowe**:
  - 🎨 FLUX.1 (advanced image generation)
  - 🖼️ Stable Diffusion 2.1 (image generation & editing)
  - 🗿 Tripo SR (3D modeling & mesh generation)
  - ⬆️ RealESRGAN (image upscaling)
  - 🎭 RVM (background removal & matting)
- **Port**: 11435
- **Domena**: Grafika, wizualizacja, kreacja 3D, edycja obrazów
- **Use Cases**: Generowanie obrazów, tworzenie 3D, upscaling, usuwanie tła
- **Demo**: Full Stable Diffusion UI z zaawansowanymi opcjami
- **Hieroglif**: 𓇳

### ✨ **Isis** - Bogini Uzdrawiania i Medycyny

- **Podstawa**: Mistral-13B + Monai
- **Modele składowe**:
  - 🏥 Monai (medical image analysis)
  - 🩺 Mistral-13B (medical reasoning & diagnosis support)
  - 👁️ LLaVa-13B (visual medical QA)
- **Port**: 11436
- **Domena**: Analiza medyczna, diagnostyka obrazowa, konsultacje
- **Use Cases**: Analiza skanów medycznych, interpretacja wyników, research
- **Demo**: Medical imaging interface z upload DICOM
- **Hieroglif**: 𓇋𓇋

### 🐱 **Bastet** - Bogini Wzroku i Ochrony

- **Podstawa**: InsightFace + MMDetection
- **Modele składowe**:
  - 👤 InsightFace (face recognition & analysis)
  - 🤸 MMPose (pose estimation & tracking)
  - 🔍 MMDetection (object detection & segmentation)
  - 📸 LLaVa-13B (image captioning & visual QA)
- **Port**: 11437
- **Domena**: Computer vision, monitoring, security, analytics
- **Use Cases**: Kamery monitoringu, rozpoznawanie twarzy, analiza ruchu
- **Demo**: Live camera feed z real-time detection
- **Hieroglif**: 𓃠

### ⚖️ **Maat** - Bogini Sprawiedliwości i Prawa

- **Podstawa**: Mistral-13B
- **Modele składowe**:
  - ⚖️ Mistral-13B (legal reasoning & analysis)
  - 📜 XLM-RoBERTa (multi-language legal text analysis)
  - 📋 Donut (legal document parsing & extraction)
  - 🔎 Sentiment Analysis (contract risk assessment)
- **Port**: 11438
- **Domena**: Prawo, kontrakty, compliance, analiza prawna
- **Use Cases**: Analiza umów, research prawny, compliance check
- **Demo**: Legal document analyzer z highlighting
- **Hieroglif**: 𓆄

### 💰 **Khnum** - Bóg Bogactwa i Handlu

- **Podstawa**: Mistral-13B
- **Modele składowe**:
  - 💹 Mistral-13B (financial analysis & forecasting)
  - 📊 PlotGPT-7B (data visualization & charts)
  - 🎯 RecBole (recommendation systems)
  - 📈 Anomaly Detection (fraud detection)
- **Port**: 11439
- **Domena**: Finanse, księgowość, trading, analiza biznesowa
- **Use Cases**: Analiza finansowa, budżetowanie, forecasting, wykrywanie anomalii
- **Demo**: Financial dashboard z charts & recommendations
- **Hieroglif**: 𓎛

---

## 🚀 Quick Start

### ⚠️ WAŻNE: Dla użytkowników z 6GB VRAM

Jeśli masz **6GB VRAM lub mniej**, przeczytaj najpierw: [VRAM_6GB_GUIDE.md](.devcontainer/VRAM_6GB_GUIDE.md)

**Kluczowe punkty**:

- Używaj **TYLKO quantyzowanych modeli** (Q4_K_M)
- Uruchamiaj **TYLKO JEDNEGO boga naraz**
- Przed startem wyczyść VRAM: `./clear-vram.sh`
- Cold start: **3-6 minut**, Warm start: **30-45 sekund**

### 1. Wyczyść VRAM (dla 6GB VRAM)

```bash
cd .devcontainer
./clear-vram.sh
```

### 2. Uruchom Panteon

```bash
# Z użyciem skryptu (zalecane)
cd .devcontainer
./start-pantheon.sh

# Lub bezpośrednio przez docker-compose
cd .devcontainer

# Dla 6GB VRAM - tylko Thoth
docker-compose up -d thoth

# Dla 12GB+ VRAM - możesz więcej
docker-compose up -d thoth cache-manager
```

### 2. Obudź Poszczególnych Bogów

```bash
# Thoth (wiedza i dokumenty)
docker-compose up -d thoth

# Ra (grafika i wizualizacja)
docker-compose up -d ra

# Isis (medycyna)
docker-compose up -d isis

# Bastet (computer vision)
docker-compose up -d bastet

# Maat (prawo)
docker-compose up -d maat

# Khnum (finanse)
docker-compose up -d khnum
```

### 3. Sprawdź Status

```bash
# Zobacz wszystkie kontenery
docker-compose ps

# Logi konkretnego boga
docker-compose logs -f thoth

# Health check
curl http://localhost:11434/api/tags
```

---

## 🎯 Użycie

### Web Interface

Otwórz http://localhost:3000 i:

1. Przejdź do sekcji **Panteon Egipskich Bogów AI**
2. Wybierz boga, klikając na jego kartę
3. Kliknij **⚡ Przebudź** aby załadować modele
4. Kliknij **🎮 Demo** aby otworzyć dedykowany interface w nowym oknie
5. Kliknij **📊 Benchmark** aby sprawdzić wydajność modelu

### API Bezpośrednie

```bash
# Rozmowa z Thoth
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral:latest",
    "messages": [{"role": "user", "content": "Hello Thoth!"}],
    "stream": false
  }'

# Przez Next.js API
curl -X POST http://localhost:3000/api/gods/thoth \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Explain LoRa training"}
    ]
  }'
```

---

## 🔮 LoRa Training

### Co to jest LoRa?

**LoRa** (Low-Rank Adaptation) to technika fine-tuningu, która pozwala dostosować model AI do konkretnego zadania bez
kosztownego trenowania wszystkich parametrów.

> 💡 **W naszym systemie**: Każdy bóg używa wielu modeli połączonych przez specjalistyczne LoRa adaptery. Możesz
> trenować własne adaptery aby rozszerzyć możliwości bogów!

**Zalety**:

- ⚡ Szybkie (minuty vs godziny)
- 💾 Małe (kilka MB vs GB)
- 🔄 Przełączalne adaptery
- 🎯 Specjalizacja bez utraty bazowej wiedzy
- 💰 Niski koszt

### Stwórz Adapter

1. Przejdź do sekcji **LoRa Training Temple** na stronie
2. Kliknij **➕ Stwórz Nowy Adapter**
3. Skonfiguruj parametry:
   - **Rank (r)**: 8-16 dla większości zadań
   - **Alpha (α)**: Zwykle 2×rank
   - **Learning Rate**: 0.0001-0.001
   - **Epochs**: 3-5 wystarczy

### Parametry Wyjaśnione

```yaml
Rank (r):
  8
  # Wymiar dekompozycji macierzy
  # Wyższy = więcej parametrów = lepsza jakość, ale wolniejsze

Alpha (α):
  16
  # Scaling factor dla LoRa
  # Typowo 2×rank dla balansu

Learning Rate:
  0.0001
  # Jak szybko model się uczy
  # Zbyt wysoki = niestabilność
  # Zbyt niski = wolne uczenie

Target Modules:
  ["q_proj", "v_proj"]
  # Które warstwy attention trenować
  # q_proj, k_proj, v_proj = query, key, value projections
```

---

## 🏗️ Architektura

### System Cache

```
SSD Cache Structure:
├── /mnt/ssd/
│   ├── ollama/           # Modele dla każdego boga
│   │   ├── thoth/        # Mistral
│   │   ├── ra/           # Llama
│   │   ├── anubis/       # DeepSeek
│   │   ├── isis/         # Phi-4
│   │   └── horus/        # Gemma
│   └── cache/
│       ├── bazel/        # Bazel build cache
│       └── models/       # Temporary model cache
```

### Proto Schema

Komunikacja między serwisami przez Protocol Buffers:

```
.schema/bot/
├── message/
│   └── god.proto         # Definicje wiadomości
├── enum/
│   └── god_enums.proto   # Enumy i statusy
└── service/
    └── pantheon.proto    # gRPC services
```

### Lazy Loading

Modele są ładowane **tylko gdy są potrzebne**:

1. Kontener startuje bez załadowanego modelu (oszczędność VRAM)
2. Pierwszy request wywołuje `pull` i ładuje model do pamięci
3. Model zostaje w pamięci przez `OLLAMA_KEEP_ALIVE` (domyślnie 5m)
4. Po wygaśnięciu, model jest automatycznie wyładowany

---

## ⚙️ Konfiguracja

### Zmienne Środowiskowe

Edytuj `.devcontainer/.env`:

```bash
# Ścieżka do SSD (WAŻNE dla wydajności!)
SSD_PATH=/mnt/ssd

# GPU
CUDA_VISIBLE_DEVICES=0

# Ollama
OLLAMA_KEEP_ALIVE=5m          # Jak długo model w pamięci
OLLAMA_MAX_LOADED_MODELS=1    # Max modeli równocześnie

# Cache
MAX_CACHE_SIZE_GB=50
GPU_MEMORY_RESERVE_GB=2       # Zarezerwuj dla systemu
```

### GPU Requirements

#### Z Quantyzacją (Q4_K_M) - Dla 6GB VRAM

| Bóg              | VRAM (Q4)   | VRAM (Full) | GPU Minimum  | Load Time | Modeli |
| ---------------- | ----------- | ----------- | ------------ | --------- | ------ |
| Thoth (Text/OCR) | **~4.5 GB** | ~6 GB       | RTX 3060 6GB | 30-45s    | 5      |
| Ra (Graphics)    | **~5 GB**   | ~8 GB       | RTX 3060 Ti  | 45-60s    | 5      |
| Isis (Medical)   | **~5 GB**   | ~8 GB       | RTX 3060 Ti  | 40-50s    | 3      |
| Bastet (Vision)  | **~4.5 GB** | ~7 GB       | RTX 3060 6GB | 35-45s    | 4      |
| Maat (Legal)     | **~4 GB**   | ~6 GB       | RTX 3060 6GB | 30-40s    | 4      |
| Khnum (Finance)  | **~4 GB**   | ~6 GB       | RTX 3060 6GB | 30-40s    | 4      |

#### Quantyzacja Explained

**Q4_K_M** = 4-bit quantization with K-quants (mixed precision)

- **Jakość**: 95% pełnego modelu (prawie niezauważalna różnica)
- **Rozmiar**: ~30% oryginalnego rozmiaru
- **Szybkość**: Niewiele wolniejsze od pełnego modelu
- **VRAM**: ~35-40% mniej pamięci

**Dla 6GB VRAM**:

- ✅ Używaj Q4_K_M - wszystko będzie działać
- ⚠️ Tylko JEDEN bóg naraz
- ❌ NIE używaj pełnych modeli (FP16/FP32)

**Dla 12GB+ VRAM**:

- ✅ Możesz Q5_K_M dla lepszej jakości
- ✅ 2-3 bogów jednocześnie (jeśli Q4)
- ⚠️ Monitoruj zużycie VRAM

> 💡 **Uwaga**: Modele ładują się lazy - tylko gdy są potrzebne. Cold start (pierwszy raz): 3-6 minut (download). Warm
> start (kolejny raz): 30-45 sekund (tylko load).

### Bazel Cache

Konfiguracja w `.bazelrc`:

```bash
# Build z cache
bazel build //... --config=gpu

# Clear cache
rm -rf /mnt/ssd/cache/bazel/*

# Check cache size
du -sh /mnt/ssd/cache/bazel
```

---

## 📊 Monitoring

### Prometheus Metrics

Włącz monitoring:

```bash
docker-compose --profile monitoring up -d prometheus
```

Metryki dostępne na: http://localhost:9091

### Cache Manager

API cache managera: http://localhost:9090

```bash
# Status cache
curl http://localhost:9090/api/cache/status

# Wyładuj model
curl -X POST http://localhost:9090/api/cache/unload/thoth

# Health
curl http://localhost:9090/health
```

---

## 🛠️ Development

### Build Proto

```bash
# Wygeneruj Go code z proto
bazel build //schema/bot:bot

# Wygeneruj dla wszystkich języków
bazel build //schema/...
```

### Test API

```bash
# Test chat endpoint
curl -X POST http://localhost:3000/api/gods/thoth \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}]}'

# Test wake endpoint
curl -X POST http://localhost:3000/api/gods/thoth/wake

# Test metrics
curl http://localhost:3000/api/gods/thoth/metrics
```

---

## 🐛 Troubleshooting

### Model nie ładuje się

```bash
# Sprawdź logi
docker-compose logs thoth

# Sprawdź VRAM
nvidia-smi

# Restart kontenera
docker-compose restart thoth
```

### "Out of memory"

```bash
# Zmniejsz liczbę równoczesnych modeli
OLLAMA_MAX_LOADED_MODELS=1

# Użyj mniejszych modeli
# Zamiast Llama 70B, użyj Mistral 7B
```

### Wolne ładowanie

```bash
# Sprawdź czy używasz SSD
df -h /mnt/ssd

# Sprawdź dysk IO
iostat -x 1

# Zwiększ cache
MAX_CACHE_SIZE_GB=100
```

---

## 📚 Resources

### Ollama

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Available Models](https://ollama.com/library)

### LoRa

- [LoRa Paper](https://arxiv.org/abs/2106.09685)
- [Hugging Face PEFT](https://github.com/huggingface/peft)

### Protocol Buffers

- [Proto3 Guide](https://protobuf.dev/programming-guides/proto3/)
- [gRPC](https://grpc.io/)

---

## 🤝 Contributing

Aby dodać nowego boga:

1. Dodaj definicję w `docker-compose.yml`
2. Utwórz volumen dla modelu
3. Dodaj port (kolejny w sekwencji)
4. Zaktualizuj `GOD_PORTS` i `GOD_MODELS` w API
5. Dodaj kartę w `GodsPanel.tsx`

---

## 📜 License

MIT License - See LICENSE file

---

## 🙏 Credits

Stworzono z ❤️ używając:

- **Ollama** - Local LLM runtime
- **Next.js** - Web framework
- **Docker** - Containerization
- **Bazel** - Build system
- **Protocol Buffers** - Data serialization

---

𓂀 **Niech bogowie prowadzą Twoją drogę w świecie AI!** 𓁹

_"Wiedza to światło w ciemności, a AI to nasze nowe hieroglify"_ - Mądrość Thotha
