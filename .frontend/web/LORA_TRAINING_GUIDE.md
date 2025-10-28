# 🧬 LoRA Training System - Complete Guide

## 🎯 Co zostało zrobione?

Stworzyłem **6 dedykowanych interfejsów treningowych LoRA** - jeden dla każdego boga egipskiego. Każdy interfejs ma pola
specyficzne dla typu danych, który dany bóg przetwarza.

## 📚 Thoth - NLP Stack

### Co można trenować:

1. **Text Generation** - Mistral 7B na custom rozmowach
2. **OCR & Document Analysis** - PaddleOCR na skanach dokumentów
3. **Translation** - Opus-MT na parach tłumaczeń

### Przykładowe dane:

```
# Text Generation
User: Jak działa AI?
Assistant: AI to system, który...

# OCR Documents
- Skany faktur, dokumentów, paragonów (.jpg, .png, .pdf)
- Pliki JSON z tekstem do każdego skanu

# Translation
pl,en
"Dzień dobry","Good morning"
"Jak się masz?","How are you?"
```

## ☀️ Ra - Image & Video Generation

### Co można trenować:

1. **Image Generation** - Stable Diffusion 2.1 LoRA
2. **Image Upscaling** - RealESRGAN
3. **Style Transfer** - Custom style models

### Przykładowe dane:

```
# Image Generation
- 20-100 obrazów (min 512x512)
- Caption do każdego: "a photo of [subject] in [style]"
- Trigger word: "sks" lub "my_style"

# Upscaling
- Pary: low-res (256px) + high-res (2048px)
- Te same nazwy plików!

# Style Transfer
- 10-50 obrazów w danym stylu
- Opis stylu (kolory, tekstury, technika)
```

## ✨ Isis - Medical & Audio AI

### Co można trenować:

1. **Medical Imaging** - MONAI segmentacja
2. **Voice Cloning** - XTTS fine-tuning
3. **Music Generation** - MusicGen

### Przykładowe dane:

```
# Medical Imaging
- DICOM/PNG skany (CT, MRI, X-Ray)
- Maski segmentacji (pixel-wise labels)
⚠️ UWAGA: Zanonimizuj dane (HIPAA/GDPR)!

# Voice Cloning
- 10-30 min czystego audio (WAV 22050Hz)
- Transkrypcje:
audio1.wav|To jest przykładowa transkrypcja.
audio2.wav|Druga transkrypcja...

# Music Generation
- 20-50 utworów podobnego stylu (WAV/MP3)
- Opcjonalnie opisy: "upbeat electronic with bass"
```

## 🐱 Bastet - Computer Vision

### Co można trenować:

1. **Face Recognition** - InsightFace
2. **Object Detection** - MMDetection
3. **Pose Estimation** - MMPose

### Przykładowe dane:

```
# Face Recognition
faces/
├── osoba_1/
│   ├── zdjecie1.jpg
│   ├── zdjecie2.jpg
│   └── ... (10-50 zdjęć)
├── osoba_2/
│   └── ...

# Object Detection
- Zdjęcia + annotacje COCO/YOLO
- Klasy: "car, person, dog, bicycle"
🛠️ Użyj: LabelImg, CVAT, RoboFlow

# Pose Estimation
- Zdjęcia ludzi w różnych pozach
- JSON z keypoints (format COCO - 17 punktów)
```

## ⚖️ Maat - Legal & Analytics

### Co można trenować:

1. **Legal Analysis** - Mistral 7B na dokumentach prawnych
2. **Sentiment Analysis** - XLM-RoBERTa
3. **Text Summarization** - Abstractive summarization

### Przykładowe dane:

```
# Legal Analysis
- Umowy, wyroki, opinie prawne (PDF/DOCX/TXT)
- Q&A pary:
Question: Jakie są wymogi umowy sprzedaży?
Answer: Zgodnie z art. 158 KC...
⚠️ UWAGA: Zanonimizuj dane klientów (RODO)!

# Sentiment Analysis
text,sentiment
"Produkt świetny, polecam!",positive
"Rozczarowanie, słaba jakość",negative
"Przeciętny",neutral

# Summarization
full_text,summary
"Długi dokument...",  "Krótkie podsumowanie..."
```

## 🏺 Khnum - 3D & Game AI

### Co można trenować:

1. **3D Modeling** - Tripo SR
2. **Code Generation** - StarCoder 7B
3. **Game AI & Recommendations** - RecBole

### Przykładowe dane:

```
# 3D Modeling
- Modele 3D (OBJ, FBX, GLB)
- Reference images (front, side, top views)
- Minimum 50 modeli dla dobrego wyniku

# Code Generation
- ZIP z kodem lub Git repo URL
- Opcjonalne code-comment pairs:
# Comment: Function to calculate factorial
def factorial(n):
    return 1 if n <= 1 else n * factorial(n-1)

# Game AI & Recommendations
user_id,item_id,rating,timestamp
user_001,game_123,5,2024-01-15
user_001,game_456,4,2024-01-16
```

## 🚀 Jak używać?

### Krok 1: Otwórz Dashboard

```bash
cd .frontend/web
yarn dev  # lub: docker-compose -f docker-compose.dev.yml up
```

Otwórz: http://localhost:3001

### Krok 2: Wybierz Boga

Na każdym god card (Thoth, Ra, Isis, Bastet, Maat, Khnum) kliknij:

```
🧠 Train LoRA
```

### Krok 3: Wybierz Typ Treningu

Na przykład dla **Thoth**:

- Text Generation
- OCR & Document Analysis
- Translation

### Krok 4: Upload Danych

- Przeciągnij pliki do drag-and-drop area
- Lub kliknij i wybierz z file browsera

### Krok 5: Konfiguracja

```
Epochs: 3-10
Learning Rate: 0.0001-0.0002
Batch Size: 4-16
LoRA Rank: 4-64
```

### Krok 6: Start Training

Kliknij **"Start Training"** i obserwuj:

- Progress bar (0-100%)
- Loss / Accuracy
- Time Remaining

### Krok 7: Deploy

Po zakończeniu → "Deploy to GPU" → nowy container z trained LoRA

## 📊 Konfiguracja Treningu - Tabela

| Parametr          | Opis                                 | Typowa wartość |
| ----------------- | ------------------------------------ | -------------- |
| **Epochs**        | Liczba pełnych przejść przez dataset | 3-10           |
| **Learning Rate** | Wielkość kroku optymalizacji         | 0.0001-0.0002  |
| **Batch Size**    | Ile próbek na raz                    | 4-16           |
| **LoRA Rank**     | Ranga macierzy LoRA                  | 4-64           |

## 🎨 Struktura Kodu

```
app/
├── Dashboard.tsx           # Główny dashboard z god cards
├── GodTraining.tsx        # Router do dedykowanych interfejsów
└── training/
    ├── ThothTraining.tsx   # NLP training
    ├── RaTraining.tsx      # Image/Video training
    ├── IsisTraining.tsx    # Medical/Audio training
    ├── BastetTraining.tsx  # Computer Vision training
    ├── MaatTraining.tsx    # Legal/Analytics training
    ├── KhnumTraining.tsx   # 3D/Game AI training
    ├── index.ts            # Exports
    └── README.md           # Dokumentacja
```

## 🔥 Następne Kroki (Backend Integration)

Obecnie interfejsy są **UI-only**. Aby połączyć z backendem:

### API Endpoints do stworzenia:

```typescript
POST /api/lora/train
Body: {
  god: "thoth",
  type: "text_generation",
  dataset: FormData,
  config: { epochs, lr, batch_size, rank }
}

GET /api/lora/status/:jobId
Response: {
  progress: 45,
  loss: 2.456,
  accuracy: 67.8,
  time_remaining: "12 min"
}

POST /api/lora/deploy
Body: {
  jobId: "abc123",
  containerName: "thoth-custom-1"
}

GET /api/lora/models
Response: [
  { id: "1", name: "thoth-custom-1", status: "ready" },
  { id: "2", name: "ra-style-transfer", status: "training" }
]
```

## 💡 Tips dla Najlepszych Wyników

### ✅ DO:

- Używaj high-quality, consistent data
- 50-100 przykładów minimum
- Różnorodność (angles, contexts, variations)
- Waliduj dane przed uploadem
- Zanonimizuj wrażliwe dane

### ❌ NIE:

- Nie uploaduj low-quality, blurry images
- Nie mieszaj różnych formatów/stylów
- Nie używaj copyrighted data bez zgody
- Nie skipuj walidacji datasetu
- Nie trenuj na <20 przykładach

## 🎯 Przykładowe Use Cases

### 1. Custom Chatbot (Thoth)

```
Zbierz 100 konwersacji w twoim stylu → Train Mistral 7B LoRA → Deploy → Używaj jako custom assistant
```

### 2. Brand Style Generator (Ra)

```
30 zdjęć produktów w twoim stylu → Train SD LoRA → Generate nieskończenie więcej w tym samym stylu
```

### 3. Company Voice Clone (Isis)

```
20 min nagrań głosu CEO → Train XTTS → Generate company announcements w jego głosie
```

### 4. Warehouse Object Detection (Bastet)

```
200 zdjęć produktów + annotations → Train MMDetection → Automatyczne inventory counting
```

### 5. Legal Document Analyzer (Maat)

```
500 umów + Q&A → Train Mistral 7B → Automatyczna analiza nowych umów
```

### 6. Game NPC AI (Khnum)

```
User interaction data → Train RecBole → Intelligent NPC recommendations
```

## 🚨 Troubleshooting

### Problem: "Failed to upload dataset"

- Sprawdź format plików (akceptowane: .jpg, .png, .pdf, .csv, .json, .txt)
- Sprawdź rozmiar (max 500MB per upload)

### Problem: "Training failed"

- Zmniejsz batch_size (np. z 16 → 4)
- Zwiększ epochs (np. z 3 → 10)
- Sprawdź jakość danych

### Problem: "Out of memory"

- Zmniejsz batch_size
- Użyj mniejszego LoRA rank (np. 8 zamiast 64)
- Rozważ CPU training (wolniejsze, ale nie blokuje GPU)

---

**Status**: ✅ UI Complete | 🚧 Backend Integration Pending **Port**: 3001 (Vite dev server) **Ollama**: localhost:11434
