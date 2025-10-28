# 🎯 GiPT-1 AI Models - Kompletna Lista

## 📚 Thoth - Bóg Mądrości i Tekstu
**Port:** 8001 | **VRAM:** 4-6GB

### Modele:
- **Mistral 7B Q4** - Text generation, Q&A, summarization
- **PaddleOCR** - OCR dla dokumentów (PDF, obrazy)
- **Opus-MT** - Tłumaczenie maszynowe (100+ języków)
- **Donut** - Document understanding (faktury, CV, formularze)

### Use Cases:
- Chatboty i asystenci AI
- Analiza dokumentów biznesowych
- Tłumaczenia w czasie rzeczywistym
- Streszczanie długich tekstów

---

## ☀️ Ra - Bóg Światła i Kreacji
**Port:** 8002 | **VRAM:** 6GB

### Modele:
- **Stable Diffusion 2.1 FP16** - Generowanie obrazów (512x512, 768x768)
- **RealESRGAN** - Upscaling 4x
- **RVM** - Background removal
- **ControlNet** - Style transfer i guided generation

### Use Cases:
- Generowanie grafik marketingowych
- Edycja zdjęć produktowych
- Tworzenie illustracji
- Przetwarzanie obrazów w czasie rzeczywistym

---

## ✨ Isis - Bogini Uzdrawiania i Audio
**Port:** 8003 | **VRAM:** 4-6GB

### Modele:
- **MONAI** - Medical imaging (X-ray, CT, MRI analysis)
- **XTTS** - Text-to-speech (25+ języków)
- **XTTS** - Voice cloning (5s sample)
- **MusicGen** - Music generation

### Use Cases:
- Diagnostyka medyczna wspomagana AI
- Generowanie audiobook'ów
- Klonowanie głosu dla content creators
- Tworzenie muzyki tła

---

## 🐱 Bastet - Bogini Wzroku
**Port:** 8004 | **VRAM:** 4-6GB

### Modele:
- **InsightFace** - Face recognition, age/gender detection
- **MMPose** - Pose estimation (17 keypoints)
- **MMDetection** - Object detection (COCO 80 classes)
- **LLaVa 7B** - Visual Question Answering

### Use Cases:
- Systemy bezpieczeństwa (monitoring)
- Analiza ruchu w sklepach
- Fitness apps (pose tracking)
- Automatyczna moderacja treści wizualnych

---

## ⚖️ Maat - Bogini Sprawiedliwości
**Port:** 8005 | **VRAM:** 4-6GB

### Modele:
- **Mistral 7B Q4 + Legal LoRA** - Analiza prawna
- **XLM-RoBERTa** - Multilingual text analysis
- **PlotGPT 7B** - Data visualization
- **Custom Sentiment** - Sentiment analysis

### Use Cases:
- Analiza umów i dokumentów prawnych
- Compliance checking
- Sentiment analysis dla social media
- Wizualizacja danych biznesowych

---

## 🏺 Khnum - Bóg Tworzenia 3D
**Port:** 8006 | **VRAM:** 5-6GB

### Modele:
- **Tripo SR** - Text-to-3D, Image-to-3D
- **RecBole** - Recommendation systems
- **StarCoder 7B** - Code generation (Python, JS, Go)
- **Unity ML Agents** - Game AI (pathfinding, NPC behavior)

### Use Cases:
- Tworzenie assetów 3D dla gier
- E-commerce (recommendation engine)
- Code assistant dla programistów
- Procedural content generation w grach

---

## 📦 Pakiety Cennikowe

### 🆓 Free (0 zł/miesiąc)
- Mistral 7B Q4 + SD 2.1 (512x512)
- 100 requests/dzień
- API access
- Community support

### 💙 Simple (299 zł/miesiąc)
- Wszystko z Free +
- Mistral 13B
- LLaVa 13B
- 5,000 requests/dzień
- Priority support

### 💜 Premium (999 zł/miesiąc)
- Wszystkie 6 modeli AI
- Fine-tuning (LoRA)
- 50,000 requests/dzień
- 24/7 dedicated support

### 🏆 Enterprise (Indywidualnie)
- Dedykowane GPU
- Custom models & LoRA
- Unlimited requests
- SLA 99.9%

---

## 🔧 Optymalizacje dla 6GB VRAM

Wszystkie modele używają:
- **Quantization** (Q4, FP16)
- **Attention slicing** dla dużych obrazów
- **VAE slicing** w SD 2.1
- **Gradient checkpointing**
- **8-bit Adam optimizer**
- **LoRA adapters** zamiast full fine-tuning

---

## 🚀 Quick Start

```bash
# Uruchom wszystkie modele
make web-dev

# Sprawdź status
curl http://localhost:8001/health
curl http://localhost:8002/health
# ... etc

# Frontend
open http://localhost:3001
```

---

## 📊 Model Performance (6GB VRAM)

| Model | Inference Time | Throughput |
|-------|---------------|------------|
| Mistral 7B | ~50ms/token | 20 tokens/s |
| SD 2.1 (512x512) | ~3s | 0.33 img/s |
| LLaVa 7B | ~100ms/token | 10 tokens/s |
| InsightFace | ~20ms | 50 faces/s |
| XTTS | ~200ms/s audio | 5x realtime |
| Tripo SR | ~10s | 0.1 models/s |

---

Made with ❤️ by Code-Rice Team

