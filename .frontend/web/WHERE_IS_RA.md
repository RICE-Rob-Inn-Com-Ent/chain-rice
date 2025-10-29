# 🔍 Gdzie znaleźć Stable Diffusion (Ra)?

## ❓ "Why I don't see Stable Diffusion in model management?"

**Odpowiedź:** Teraz WIDZISZ! ✅

Ra jest w **Model Management**, ale w **osobnej sekcji** (nie w Ollama models).

---

## 📍 Lokalizacje Ra

### 1️⃣ **Model Management Page** (NOWE!)

```
http://localhost:3001
  ↓ klik "Models" w sidebar
  ↓

╔═══════════════════════════════════════════════════════════════════╗
║                    MODEL MANAGEMENT                               ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  ☀️ Ra - Stable Diffusion (Non-Ollama)                           ║
║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  ║
║  ┃ 🎨 Stable Diffusion 2.1 FP16                            ┃  ║
║  ┃ FastAPI Backend • Port 8002 • 6GB VRAM Optimized        ┃  ║
║  ┃                                                          ┃  ║
║  ┃ Status: Sleeping (CPU) 🟡                               ┃  ║
║  ┃                                                          ┃  ║
║  ┃ Models:                                                  ┃  ║
║  ┃ ┌─────────────────┬─────────────┬──────────────────┐    ┃  ║
║  ┃ │ Image Gen       │ Upscaler    │ BG Removal       │    ┃  ║
║  ┃ │ SD 2.1 FP16     │ RealESRGAN  │ RVM              │    ┃  ║
║  ┃ └─────────────────┴─────────────┴──────────────────┘    ┃  ║
║  ┃                                                          ┃  ║
║  ┃ Optimizations: attention_slicing • vae_slicing • fp16   ┃  ║
║  ┃                                                          ┃  ║
║  ┃                            [Try Demo] [Settings]        ┃  ║
║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  ║
║                                                                   ║
║  ℹ️ Ra uses its own FastAPI backend, not Ollama                  ║
║                                                                   ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                                   ║
║  🤖 Ollama Models                                                 ║
║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  ║
║  ┃ 📚 mistral:7b-instruct-q4_K_M                           ┃  ║
║  ┃ Status: Idle • Size: 4.1 GB                             ┃  ║
║  ┃ [Load] [Delete]                                         ┃  ║
║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  ║
║                                                                   ║
║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  ║
║  ┃ 📚 llama2:7b                                            ┃  ║
║  ┃ Status: Downloading... 45% ▓▓▓▓▓▓▓░░░░░░░░             ┃  ║
║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

### 2️⃣ **Dashboard**

```
http://localhost:3001
  ↓

Karta Ra:
┌────────────────────────────────────┐
│ ☀️ Ra                              │
│ Bóg Światła i Kreacji              │
│                                    │
│ Status: IDLE 🔵                    │
│                                    │
│ [Wake Model] [Try Demo →]          │
│ [Train LoRA]                       │
└────────────────────────────────────┘
```

---

### 3️⃣ **Ra Demo**

```
http://localhost:3001/demo/ra.html

Pełny interface Stable Diffusion:
• Text to Image
• Image to Image  
• Extras (upscaling)
• Gallery
• Parametry (steps, CFG, size, seed)
```

---

## 🎯 Kluczowe różnice

| Aspekt | Ollama Models | Ra (Stable Diffusion) |
|--------|---------------|----------------------|
| **Lokalizacja w UI** | Sekcja "Ollama Models" | Sekcja "Ra - Stable Diffusion" |
| **Backend** | Ollama (11434) | FastAPI (8002) |
| **API** | `/api/ollama/*` | `/api/ra/*` |
| **Typ modeli** | LLM (text) | Diffusion (image) |
| **Format** | GGUF | PyTorch FP16 |
| **Zarządzanie** | `ollama pull` | Python/HuggingFace |

---

## ✅ Checklist

Sprawdź czy widzisz Ra:

- [ ] Otwórz http://localhost:3001
- [ ] Kliknij "Models" w lewym sidebar
- [ ] Przewiń na górę - pierwsza sekcja to "☀️ Ra - Stable Diffusion"
- [ ] Zobacz status Ra (Sleeping/Active/Disconnected)
- [ ] Zobacz 3 modele Ra (SD 2.1, RealESRGAN, RVM)
- [ ] Zobacz optymalizacje (attention_slicing, vae_slicing, fp16)
- [ ] Kliknij "Try Demo" - otwiera się /demo/ra.html

Jeśli wszystko ✅ - Ra działa poprawnie!

---

## 🚀 Quick Links

- **Model Management**: http://localhost:3001 (sidebar → Models)
- **Ra Demo**: http://localhost:3001/demo/ra.html
- **Ra Health Check**: `curl http://localhost:8002/health`
- **Documentation**: `RA_INTEGRATION.md`

---

**Status:** ✅ Ra jest widoczny w Model Management!  
**Problem solved:** Ra teraz ma dedykowaną sekcję w UI
