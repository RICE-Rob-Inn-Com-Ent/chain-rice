# Ra Integration - Native Stable Diffusion

## ✅ **Zintegrowane! Ra nie wymaga zewnętrznego WebUI**

Ra ma **wbudowany** Stable Diffusion 2.1 FP16 w swoim kontenerze. Frontend (`localhost:3001`) komunikuje się
bezpośrednio z Ra API (`localhost:8002`).

---

## 🎯 Architektura

```
┌─────────────────────────────────────────────────┐
│  Frontend (Vite)                                │
│  http://localhost:3001/demo/ra.html             │
│                                                 │
│  Używa: lib/services/ra.ts                      │
└───────────────────┬─────────────────────────────┘
                    │
                    │ /api/ra/* → proxy Vite
                    ▼
┌─────────────────────────────────────────────────┐
│  Ra Backend (FastAPI)                           │
│  http://localhost:8002                          │
│                                                 │
│  • Stable Diffusion 2.1 FP16                    │
│  • RealESRGAN (lazy)                            │
│  • RVM (lazy)                                   │
│                                                 │
│  Kontener: rice-ra                              │
│  Kod: .backend/bot/core/ollama/ra/              │
└─────────────────────────────────────────────────┘
```

---

## 📋 Endpointy Ra API

### **GET /health**

Sprawdza status Ra i dostępne modele.

**Response:**

```json
{
  "status": "sleeping" | "active",
  "god": "Ra",
  "vram": "6GB optimized",
  "models": {
    "image_gen": "Stable Diffusion 2.1 FP16 (lazy)",
    "upscaler": "RealESRGAN (lazy)",
    "bg_removal": "RVM (lazy)"
  },
  "optimizations": ["attention_slicing", "vae_slicing", "fp16"]
}
```

---

### **POST /wake**

Oznacza Ra jako aktywnego (gotowy do generowania na GPU).

**Response:**

```json
{
  "success": true,
  "god": "Ra",
  "status": "active"
}
```

---

### **POST /sleep**

Wyłącza modele i zwalnia VRAM.

**Response:**

```json
{
  "success": true,
  "god": "Ra",
  "status": "sleeping"
}
```

---

### **POST /generate**

Generuje obraz używając Stable Diffusion.

**Request:**

```json
{
  "prompt": "Egyptian pyramid at sunset",
  "negative_prompt": "blurry, low quality",
  "steps": 30,
  "cfg_scale": 7.5,
  "width": 512,
  "height": 512
}
```

**Response:**

```json
{
  "image": "data:image/png;base64,iVBORw0KG...",
  "image_path": "/tmp/ra_output_abc123.png",
  "prompt": "Egyptian pyramid at sunset"
}
```

- `image` - Base64 data URL gotowy do użycia w `<img src={image}>`
- `image_path` - Ścieżka do pliku w kontenerze (do debugowania)

---

## 🚀 Jak uruchomić Ra?

### 1. Uruchom kontener Ra:

```bash
cd /home/mrDinkelman/rice-mono/.backend/bot/core/ollama
docker-compose up -d ra
```

### 2. Sprawdź status:

```bash
curl http://localhost:8002/health | python3 -m json.tool
```

### 3. Uruchom frontend:

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web
yarn dev
```

### 4. Otwórz demo:

```
http://localhost:3001/demo/ra.html
```

---

## 🎨 Funkcje Ra Demo

### **Text to Image**

- Prompt i negative prompt
- Sampling steps (10-50)
- CFG scale (1-20)
- Wymiary obrazu (256-1024)
- Seed control (-1 = random)
- Progress bar podczas generowania

### **Gallery**

- Historia wygenerowanych obrazów
- Klikalne miniatury
- Wyświetlanie parametrów

### **Info Display**

- Status Ra (Active/Sleeping)
- Model info (SD 2.1 FP16)
- Optymalizacje (6GB VRAM)

---

## 🔧 Proxy Configuration (Vite)

W `vite.config.ts`:

```typescript
proxy: {
  "/api/ra": {
    target: "http://localhost:8002",
    changeOrigin: true,
    secure: false,
    ws: true,
    rewrite: (path) => path.replace(/^\/api\/ra/, ""),
  },
}
```

Frontend wywołuje: `/api/ra/generate`  
Vite przekierowuje do: `http://localhost:8002/generate`

---

## 📁 Pliki

### Frontend:

- `lib/services/ra.ts` - API client dla Ra
- `widget/models/Ra.tsx` - UI dla Ra demo
- `vite.config.ts` - Proxy dla `/api/ra`

### Backend:

- `.backend/bot/core/ollama/ra/ra-server.py` - FastAPI server
- `.backend/bot/core/ollama/ra/requirements.txt` - Zależności Python
- `.backend/bot/core/ollama/ra/Dockerfile` - Kontener

---

## 🎯 Dlaczego nie Automatic1111?

| Automatic1111 WebUI | Ra Native           |
| ------------------- | ------------------- |
| Osobny port (7860)  | Zintegrowany (8002) |
| Ciężkie UI (gradio) | Lekkie FastAPI      |
| 2 kontenery         | 1 kontener          |
| Duplikacja modeli   | Wspólne modele      |
| ~4GB overhead       | ~500MB overhead     |

**Ra jest zoptymalizowany dla rice-mono!**

---

## ⚡ Optymalizacje 6GB VRAM

Ra używa:

- **FP16** zamiast FP32 (50% oszczędności pamięci)
- **Attention Slicing** - dzieli attention heads
- **VAE Slicing** - dzieli operacje VAE
- **Lazy Loading** - ładuje modele tylko gdy potrzebne
- **GPU → CPU Sleep** - automatyczne zwalnianie VRAM

---

## 🐛 Troubleshooting

### Problem: "Ra: Disconnected" w dashboard

**Rozwiązanie:**

```bash
docker-compose -f /home/mrDinkelman/rice-mono/.backend/bot/core/ollama/docker-compose.yml up -d ra
```

---

### Problem: Generowanie trwa wieczność

**Przyczyny:**

1. **CPU mode** - jeśli CUDA niedostępne, SD działa na CPU (~5-10 min)
2. **Pierwsze generowanie** - ładowanie modelu (~30s-1min)
3. **Wysokie steps** - 50 steps = 2x dłużej niż 25

**Rozwiązanie:**

- Zmniejsz steps do 20-30
- Użyj GPU (CUDA)
- Poczekaj na pierwsze ładowanie

---

### Problem: Błąd "Failed to generate image: 500"

**Sprawdź logi:**

```bash
docker logs rice-ra
```

**Możliwe przyczyny:**

- Brak VRAM (inny model zajmuje GPU)
- Błąd w prompt (zbyt długi)
- Model nie pobrany

---

## 📊 Kolejne kroki (TODO)

- [ ] Dodać img2img (image editing)
- [ ] Dodać upscaling (RealESRGAN)
- [ ] Dodać inpainting
- [ ] Dodać ControlNet
- [ ] Dodać LoRA support
- [ ] Zmienić model SD (2.1 → SDXL/SD3)

---

## 🎉 **Ra jest gotowy do użycia!**

Frontend już używa natywnego Ra API. Nie musisz instalować ani uruchamiać żadnego zewnętrznego WebUI.
