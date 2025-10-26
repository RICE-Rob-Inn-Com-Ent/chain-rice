# 🏛️ Architektura Panteonu Egipskich Bogów AI

## 🎯 Koncepcja

Każdy bóg to **kontener Docker** zawierający:

1. **Model bazowy** (Mistral, SD, etc.) - quantyzowany Q4_K_M
2. **Zestaw narzędzi specjalistycznych** (OCR, translation, detection, etc.)
3. **FastAPI server** orkiestrujący modele
4. **LoRA adapters** - możliwość fine-tuningu

---

## 📜 Thoth - Bóg Wiedzy

### Stack Technologiczny:

```
Thoth Container:
├── Ollama (Mistral 7B Q4_K_M)       # Base LLM
├── PaddleOCR                         # OCR
├── EasyNMT (Opus-MT)                 # Translation
├── Transformers (XLM-RoBERTa)        # Text analysis
├── python-doctr (Donut)              # Document understanding
└── FastAPI Server (port 8000)        # API orchestrator
```

### Porty:

- **11434** - Ollama API (Mistral)
- **8001** - Thoth Multi-Model API

### Możliwości:

- Chat z Mistral 7B
- OCR z obrazów
- Tłumaczenia (90+ języków)
- Analiza dokumentów
- LoRA fine-tuning

### Volumes:

- `thoth-models` - Modele Ollama
- `thoth-lora` - LoRA adapters

---

## 🖥️ Interfejsy Użytkownika

### 1. **Website Sales Agent (ChatWidget)**

- Lokalizacja: Prawy dolny róg na wszystkich stronach
- Funkcja: **Sales & Navigation Assistant**
- Features:
  - Pomaga w nawigacji po stronie
  - Podaje linki do: /services, /pricing, /portfolio, /contact
  - Wykrywa trigger words ("gdzie", "ile kosztuje", "projekty")
  - Możliwość upload LoRA adapter dla fine-tuningu
  - Odpowiada w ~20-30s (CPU) lub ~3-5s (GPU)

### 2. **Demo Applications** (Nowe okno)

- URL: `/demo/{godId}` (otwiera się w nowym oknie)
- Wymaga: **Logowania** (demo mode - dowolne credentials)
- Typ: **Osobna aplikacja SaaS**
- Layout: **Minimalny** - bez Navbar/Footer głównej strony
- Funkcje specyficzne dla każdego boga:
  - `/demo/thoth` - Document analysis app
  - `/demo/ra` - Image generation studio
  - `/demo/isis` - Medical imaging platform
  - `/demo/bastet` - Computer vision dashboard
  - `/demo/maat` - Legal document analyzer
  - `/demo/khnum` - Financial analytics platform

---

## 🔮 LoRA Fine-Tuning

### Gdzie wgrać plik LoRA:

#### **Opcja 1: ChatWidget (Sales Agent)**

1. Kliknij chat widget (prawy dolny róg)
2. Kliknij "🔮 LoRA"
3. Upload plik (.safetensors, .bin, .pt)
4. Kliknij "🚀 Apply"
5. Thoth załaduje adapter i będzie używał go w konwersacjach

#### **Opcja 2: LoRa Training Panel** (Główna strona)

1. Scroll do "🔮 LoRa Training Temple"
2. Kliknij "➕ Stwórz Nowy Adapter"
3. Wgraj dataset (JSON/JSONL)
4. Konfiguruj parametry (rank, alpha, learning rate)
5. Kliknij "🚀 Stwórz i Zacznij Trenowanie"
6. Obserwuj progress
7. Po zakończeniu - Apply do boga

### Formaty LoRA:

- `.safetensors` - Preferred (HuggingFace format)
- `.bin` - PyTorch binary
- `.pt` / `.pth` - PyTorch checkpoints
- `.json` - Training dataset

---

## 🏗️ Build & Deploy

### Build Thoth Container:

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# Build image
docker-compose build thoth

# Start
docker-compose up -d thoth

# Logs
docker-compose logs -f thoth
```

### First Time Setup:

```bash
# Build all gods
docker-compose build

# Start only Thoth (6GB VRAM)
docker-compose up -d thoth

# Check health
curl http://localhost:8001/health
```

---

## 📊 Resource Usage (6GB VRAM)

### Thoth (Mistral 7B Q4 + Tools):

| Component    | VRAM       | RAM         | Load Time  |
| ------------ | ---------- | ----------- | ---------- |
| Mistral Q4   | ~4.2 GB    | ~500 MB     | 30-45s     |
| PaddleOCR    | -          | ~300 MB     | lazy       |
| EasyNMT      | -          | ~400 MB     | lazy       |
| Transformers | -          | ~200 MB     | lazy       |
| **Total**    | **4.2 GB** | **~1.4 GB** | **30-45s** |

### Wolne miejsce:

- VRAM: **~1.8 GB** (bezpieczny margines)
- RAM: **Zależy od systemu**

---

## 🎯 Workflow Usage

### Scenario 1: Sales Agent

```
User browsing RICE website
  ↓
Clicks ChatWidget (bottom right)
  ↓
Asks: "Ile kosztują usługi?"
  ↓
Thoth responds + gives links:
  - [Zobacz cennik]
  - [Kontakt]
  ↓
User clicks link → goes to /pricing
```

### Scenario 2: Document Analysis (Demo App)

```
User clicks Thoth → Demo
  ↓
Opens new window: /demo/thoth
  ↓
Login screen (demo - any credentials)
  ↓
Main app: Document analysis
  ↓
Upload PDF → OCR → Mistral analysis
  ↓
Get structured results
```

### Scenario 3: Fine-tuning with LoRA

```
User opens ChatWidget
  ↓
Clicks "🔮 LoRA"
  ↓
Uploads adapter file (.safetensors)
  ↓
Thoth loads adapter
  ↓
Now responds with fine-tuned knowledge!
```

---

## 🚀 Future: All Gods

Każdy bóg będzie miał podobny Dockerfile z odpowiednimi narzędziami:

### Ra (Graphics):

```
- Stable Diffusion 2.1
- FLUX.1
- Tripo SR (3D)
- RealESRGAN (upscaling)
- RVM (background removal)
```

### Isis (Medical):

```
- Mistral 7B Q4
- Monai (medical imaging)
- LLaVa-13B (visual QA)
- DICOM processing tools
```

### Bastet (Vision):

```
- InsightFace (face recognition)
- MMPose (pose estimation)
- MMDetection (object detection)
- LLaVa-13B (image captioning)
```

### Maat (Legal):

```
- Mistral 7B Q4
- XLM-RoBERTa (multilingual)
- Donut (document parsing)
- Legal NER models
```

### Khnum (Finance):

```
- Mistral 7B Q4
- PlotGPT-7B (visualization)
- RecBole (recommendations)
- Financial analysis tools
```

---

## 📝 Summary

**Nowa architektura**:

- ✅ Każdy bóg = Dockerfile z zestawem narzędzi
- ✅ Demo apps = osobne SaaS aplikacje (wymagają logowania)
- ✅ ChatWidget = Sales agent + LoRA fine-tuning
- ✅ Wszystkie modele quantyzowane Q4_K_M (6GB VRAM)
- ✅ Lazy loading narzędzi (oszczędzanie RAM)
- ✅ FastAPI jako orkiestrator

**Główny benefit**: Jeden bóg = Kompletny ekosystem narzędzi, nie tylko jeden model!

---

𓅝 **Thoth is ready to serve!** 𓁹
