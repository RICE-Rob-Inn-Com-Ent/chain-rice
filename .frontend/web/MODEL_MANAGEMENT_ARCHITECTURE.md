# Model Management Architecture

## 🎯 Przegląd

Rice Mono wykorzystuje **2 różne backendy** dla AI modeli:

1. **Ollama** - dla LLM (text models)
2. **Ra FastAPI** - dla Stable Diffusion (image models)

---

## 📊 Architektura

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND (Vite - Port 3001)                  │
│                                                                 │
│  ┌─────────────────────┐    ┌─────────────────────────────┐   │
│  │  Model Management   │    │  Dashboard                  │   │
│  │  Page               │    │  (God Cards)                │   │
│  │                     │    │                             │   │
│  │  • Ollama Section   │    │  • Thoth   (Ollama)         │   │
│  │  • Ra Section ☀️   │    │  • Ra      (FastAPI) ☀️    │   │
│  └─────────────────────┘    │  • Isis    (Ollama)         │   │
│                              │  • Bastet  (Ollama)         │   │
│                              │  • Maat    (Ollama)         │   │
│                              │  • Khnum   (Ollama)         │   │
│                              └─────────────────────────────┘   │
└───────────┬──────────────────────────────┬──────────────────────┘
            │                              │
            │ /api/ollama/*                │ /api/ra/*
            │ (Vite Proxy)                 │ (Vite Proxy)
            ▼                              ▼
┌─────────────────────────┐    ┌─────────────────────────────┐
│  OLLAMA BACKEND         │    │  RA BACKEND (FastAPI)       │
│  localhost:11434        │    │  localhost:8002             │
│                         │    │                             │
│  API:                   │    │  API:                       │
│  • /api/tags            │    │  • /health                  │
│  • /api/ps              │    │  • /wake                    │
│  • /api/pull            │    │  • /sleep                   │
│  • /api/generate        │    │  • /generate                │
│                         │    │                             │
│  Models:                │    │  Models:                    │
│  • mistral:7b           │    │  • SD 2.1 FP16              │
│  • llama2:7b            │    │  • RealESRGAN               │
│  • llava:7b             │    │  • RVM                      │
│  • codellama:7b         │    │                             │
│                         │    │  Container: rice-ra         │
│  Container: rice-thoth  │    │  Code: .backend/.../ra/     │
│  Code: .backend/.../    │    │                             │
└─────────────────────────┘    └─────────────────────────────┘
```

---

## 🔍 Dlaczego 2 backendy?

### Ollama (LLM)

- ✅ **Wspiera**: Text generation, chat, embeddings
- ✅ **Modele**: Mistral, Llama, CodeLlama, LLaVA
- ✅ **Format**: GGUF (quantized)
- ✅ **Zarządzanie**: Unified CLI (`ollama pull`, `ollama list`)
- ✅ **API**: Standardowe REST API

### Ra FastAPI (Stable Diffusion)

- ✅ **Wspiera**: Image generation, img2img, upscaling
- ✅ **Modele**: Stable Diffusion 2.1, RealESRGAN, RVM
- ✅ **Format**: PyTorch (FP16/FP32)
- ✅ **Zarządzanie**: Python, HuggingFace Diffusers
- ✅ **API**: Custom FastAPI endpoints

**Stable Diffusion wymaga innej architektury niż LLM!**

---

## 📁 Struktura plików

### Frontend (Model Management)

```
.frontend/web/
├── app/
│   ├── Models.tsx                 ← Model Management page
│   │   ├── Ra Section (NEW!)      ← Stable Diffusion status
│   │   └── Ollama Section         ← Ollama models list
│   └── Dashboard.tsx              ← God cards (6 gods)
│
├── lib/
│   ├── services/
│   │   ├── ollama.ts              ← Ollama API client
│   │   └── ra.ts (NEW!)           ← Ra API client
│   └── hooks/
│       └── useOllama.ts           ← Ollama state hook
│
└── widget/
    └── models/
        └── Ra.tsx                 ← Ra demo interface
```

### Backend

```
.backend/bot/core/ollama/
├── thoth/                         ← Ollama + Mistral 7B
│   └── Dockerfile
├── isis/                          ← Ollama + Llama2 7B
│   └── Dockerfile
├── bastet/                        ← Ollama + LLaVA 7B
│   └── Dockerfile
├── maat/                          ← Ollama + Mistral 7B
│   └── Dockerfile
├── khnum/                         ← Ollama + CodeLlama 7B
│   └── Dockerfile
│
└── ra/ (DIFFERENT!)               ← FastAPI + Stable Diffusion
    ├── ra-server.py               ← Python FastAPI server
    ├── requirements.txt           ← diffusers, torch, etc.
    └── Dockerfile
```

---

## 🔌 API Endpoints

### Ollama API (`localhost:11434`)

| Endpoint        | Method | Opis                    |
| --------------- | ------ | ----------------------- |
| `/api/tags`     | GET    | Lista wszystkich modeli |
| `/api/ps`       | GET    | Running models          |
| `/api/pull`     | POST   | Pobierz model           |
| `/api/generate` | POST   | Generuj tekst           |

**Frontend wywołuje**: `/api/ollama/api/tags` (proxy Vite)  
**Vite proxy przekierowuje do**: `http://localhost:11434/api/tags`

---

### Ra API (`localhost:8002`)

| Endpoint    | Method | Opis                     |
| ----------- | ------ | ------------------------ |
| `/health`   | GET    | Status Ra + lista modeli |
| `/wake`     | POST   | Ładuj modele do GPU      |
| `/sleep`    | POST   | Zwolnij GPU              |
| `/generate` | POST   | Generuj obraz (SD)       |

**Frontend wywołuje**: `/api/ra/health` (proxy Vite)  
**Vite proxy przekierowuje do**: `http://localhost:8002/health`

---

## 🎨 Model Management UI

### Sekcja 1: Ra (Stable Diffusion)

```tsx
// app/Models.tsx
<div className="mb-8">
  <h2>☀️ Ra - Stable Diffusion (Non-Ollama)</h2>

  {/* Ra Status Card */}
  <div className="bg-gradient-to-br from-orange-900 to-amber-900">
    Status: {raStatus?.status}
    Models: • Stable Diffusion 2.1 FP16 (lazy) • RealESRGAN (lazy) • RVM (lazy) Optimizations: • attention_slicing •
    vae_slicing • fp16 [Try Demo] → /demo/ra.html
  </div>
</div>
```

### Sekcja 2: Ollama Models

```tsx
<h2>🤖 Ollama Models</h2>;

{
  models.map((model) => <ModelCard name={model.name} size={model.size} status={isRunning ? "active" : "idle"} />);
}
```

---

## 🚀 Workflow użytkownika

### Sprawdzanie statusu Ra:

1. Otwórz **Model Management** (`/` → sidebar → "Models")
2. Sekcja **"Ra - Stable Diffusion (Non-Ollama)"** jest na górze
3. Zobacz status: **Sleeping** (CPU) lub **Active** (GPU)
4. Kliknij **"Try Demo"** aby otworzyć interface generowania

### Sprawdzanie Ollama models:

1. Ta sama strona **Model Management**
2. Przewiń do sekcji **"Ollama Models"**
3. Zobacz listę wszystkich modeli z Ollama
4. Status każdego: **Running** lub **Idle**

---

## 💡 FAQ

### Q: Dlaczego Ra nie jest w Ollama?

**A:** Ollama jest zoptymalizowany dla **LLM (text models)** w formacie GGUF. Stable Diffusion to **image model**
wymagający PyTorch i HuggingFace Diffusers. To różne technologie, więc Ra ma własny backend.

---

### Q: Czy mogę dodać Ra do Ollama?

**A:** Nie bezpośrednio. Ollama nie wspiera natywnie Stable Diffusion. Ale możesz:

- Używać Ra przez FastAPI (obecne rozwiązanie)
- Zintegrować przez API calls (już zrobione!)
- Dodać inne image models jako osobne serwisy (jak Ra)

---

### Q: Gdzie są modele dla innych bogów?

| Bóg           | Backend | Modele              | Status        |
| ------------- | ------- | ------------------- | ------------- |
| **Thoth** 📚  | Ollama  | mistral:7b-instruct | ✅ Działa     |
| **Ra** ☀️     | FastAPI | SD 2.1 FP16         | ✅ Działa     |
| **Isis** ✨   | Ollama  | llama2:7b           | ⏳ Pobieranie |
| **Bastet** 🐱 | Ollama  | llava:7b            | ⏳ Pobieranie |
| **Maat** ⚖️   | Ollama  | mistral:7b-instruct | ✅ Gotowy     |
| **Khnum** 🏺  | Ollama  | codellama:7b        | ⏳ Pobieranie |

---

### Q: Jak dodać nowy model Ollama?

```bash
# Terminal
ollama pull <model-name>

# Frontend automatycznie wykryje nowy model
# (polling co 2s w useOllama hook)
```

---

### Q: Jak sprawdzić czy Ra działa?

```bash
# Terminal
curl http://localhost:8002/health

# Lub w przeglądarce:
http://localhost:3001/demo/ra.html
```

---

## 🔧 Troubleshooting

### Problem: "Ra: Disconnected" w Model Management

**Przyczyna:** Ra kontener nie działa

**Rozwiązanie:**

```bash
cd /home/mrDinkelman/rice-mono/.backend/bot/core/ollama
docker-compose up -d ra
sleep 3
curl http://localhost:8002/health
```

---

### Problem: "Ollama: Disconnected"

**Przyczyna:** Ollama nie działa lub kontener zatrzymany

**Rozwiązanie:**

```bash
# Sprawdź czy Ollama działa
curl http://localhost:11434/api/tags

# Lub restart kontenera Thoth (który ma Ollama)
docker-compose -f /home/mrDinkelman/rice-mono/.backend/bot/core/ollama/docker-compose.yml up -d thoth
```

---

### Problem: "No models in either section"

**Przyczyna:** Żaden backend nie działa

**Rozwiązanie:**

```bash
# 1. Uruchom wszystkie kontenery
cd /home/mrDinkelman/rice-mono/.backend/bot/core/ollama
docker-compose up -d

# 2. Sprawdź status
curl http://localhost:11434/api/tags  # Ollama
curl http://localhost:8002/health      # Ra

# 3. Refresh frontend
# (automatycznie zdetekuje w ciągu 2-5s)
```

---

## 📚 Powiązane pliki

### Dokumentacja:

- `RA_INTEGRATION.md` - Szczegóły integracji Ra
- `LORA_TRAINING_GUIDE.md` - Trening modeli
- `.backend/bot/core/ollama/docker-compose.yml` - Konfiguracja kontenerów

### Kod:

- `app/Models.tsx` - Model Management page (zaktualizowane!)
- `lib/services/ra.ts` - Ra API client
- `lib/services/ollama.ts` - Ollama API client
- `.backend/bot/core/ollama/ra/ra-server.py` - Ra backend

---

## ✅ Status

```
Ra Integration:        ✅ Complete
Ollama Integration:    ✅ Complete
Model Management UI:   ✅ Updated with Ra section
Documentation:         ✅ Complete
```

---

## 🎉 Gotowe!

Teraz **Model Management** pokazuje **WSZYSTKIE** modele:

- ☀️ **Ra** (Stable Diffusion) - osobna sekcja na górze
- 🤖 **Ollama Models** - lista modeli LLM poniżej

Odśwież stronę i zobacz! 🚀

---

**Created:** 2025-10-29  
**Updated Models.tsx:** ✅ Added Ra section  
**Backend:** Dual-backend architecture (Ollama + Ra FastAPI)
