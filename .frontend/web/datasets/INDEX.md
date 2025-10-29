# 📚 Thoth Training Dataset - Complete Package

## ✅ **Dataset gotowy do użycia!**

Kompletny pakiet treningowy dla **Thoth - Boga Mądrości i Tekstu** zawierający 1000 przykładów obejmujących wszystkie
funkcje NLP.

---

## 📦 Zawartość pakietu

### 🎯 **thoth-training-1000.json** (430 KB)

Główny dataset treningowy w formacie conversation.

**Zawiera:**

- ✅ 1000 przykładów treningowych
- ✅ 8 typów zadań (text generation, translation, OCR, analysis, etc.)
- ✅ Zbalansowane klasy (~125 przykładów per task)
- ✅ Format kompatybilny z HuggingFace, Axolotl, PEFT

**Zadania:**

1. **Text Generation** (127) - Generowanie tekstu, opisy, instrukcje
2. **Translation PL→EN** (125) - Tłumaczenie polski → angielski
3. **Translation EN→PL** (124) - Tłumaczenie angielski → polski
4. **OCR Simulation** (124) - Rozpoznawanie tekstu z obrazów
5. **Document Analysis** (125) - Analiza dokumentów (CV, faktury, umowy)
6. **Summarization** (125) - Streszczanie długich tekstów
7. **Q&A** (125) - Pytania i odpowiedzi
8. **Information Extraction** (125) - Ekstrakcja danych z tekstu

---

### 📖 **README_THOTH_DATASET.md**

Kompleksowa dokumentacja datasetu.

**Zawiera:**

- 📋 Strukturę datasetu
- 🎯 Opisy typów zadań
- 🚀 Instrukcje użycia (Ollama, HuggingFace, Axolotl)
- 📝 Przykłady konfiguracji LoRA
- 🔧 Troubleshooting
- 📈 Metryki sukcesu

---

### ⚡ **QUICK_START.md**

Szybki przewodnik dla niecierpliwych.

**3 kroki:**

1. Walidacja datasetu
2. Uruchomienie interfejsu
3. Start treningu

**Zawiera:**

- ✅ Checklist przed treningiem
- ⚙️ Optymalizacje dla 6GB VRAM
- 🐛 Common issues i solutions
- 💡 Wskazówki CPU vs GPU

---

### 🔍 **validate_dataset.py**

Narzędzie do walidacji i analizy datasetu.

**Funkcje:**

- ✅ Walidacja struktury JSON
- 📊 Szczegółowe statystyki
- ⚖️ Analiza balansu klas
- 💡 Rekomendacje

**Użycie:**

```bash
python3 validate_dataset.py thoth-training-1000.json
```

---

## 🚀 Quick Start

### 1. Waliduj dataset

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web/datasets
python3 validate_dataset.py thoth-training-1000.json
```

### 2. Uruchom dashboard

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web
yarn dev
```

### 3. Załaduj w interfejsie

1. Otwórz: http://localhost:3001
2. Kliknij na **Thoth** → **"Train LoRA"**
3. Upload `thoth-training-1000.json`
4. Ustaw parametry → **Start Training**

---

## 📊 Statystyki datasetu

```
Total Examples:    1000
Total Tokens:      25,534
Format:            Conversation (user-assistant pairs)
Balance:           ✅ Excellent (2.4% variance)
Validation:        ✅ Passed (0 errors, 0 warnings)
Size:              430 KB
```

### Rozkład zadań:

```
text_generation         127 (12.7%)
translation_pl_to_en    125 (12.5%)
document_analysis       125 (12.5%)
summarization           125 (12.5%)
qa                      125 (12.5%)
information_extraction  125 (12.5%)
translation_en_to_pl    124 (12.4%)
ocr_simulation          124 (12.4%)
```

---

## 🎯 Stack modeli Thoth

Dataset jest zoptymalizowany dla treningu:

| Model                      | Funkcja                       | Ollama                       |
| -------------------------- | ----------------------------- | ---------------------------- |
| **Mistral 7B Instruct Q4** | Text generation, reasoning    | `mistral:7b-instruct-q4_K_M` |
| **PaddleOCR**              | Optical Character Recognition | External                     |
| **Opus-MT**                | Translation PL↔EN            | External                     |
| **Donut**                  | Document understanding        | External                     |

---

## 💾 Ścieżki plików

```
📁 /home/mrDinkelman/rice-mono/.frontend/web/datasets/
├── thoth-training-1000.json      # Główny dataset (430 KB)
├── README_THOTH_DATASET.md       # Pełna dokumentacja
├── QUICK_START.md                # Szybki start
├── validate_dataset.py           # Narzędzie walidacji
└── INDEX.md                      # Ten plik
```

---

## 🔗 Powiązane pliki

### Frontend:

- `/home/mrDinkelman/rice-mono/.frontend/web/app/training/ThothTraining.tsx`
  - Interface do treningu LoRA dla Thotha
  - Upload datasetu, konfiguracja, monitoring

### Guides:

- `/home/mrDinkelman/rice-mono/.frontend/web/LORA_TRAINING_GUIDE.md`
  - Kompletny przewodnik po treningach LoRA dla wszystkich bogów

### Backend:

- `/home/mrDinkelman/rice-mono/.backend/bot/core/ollama/thoth/`
  - Kontener Thoth z Mistral 7B

---

## 📈 Oczekiwane wyniki treningu

Po 3 epochs (GPU RTX 3060 6GB, ~25 minut):

| Metric              | Target | Opis                  |
| ------------------- | ------ | --------------------- |
| **Training Loss**   | < 0.5  | Im niższy, tym lepiej |
| **BLEU Score**      | > 30   | Jakość tłumaczeń      |
| **Accuracy (QA)**   | > 85%  | Poprawność odpowiedzi |
| **F1 (Extraction)** | > 0.80 | Ekstrakcja informacji |

---

## 🛠️ Użycie z różnymi narzędziami

### Ollama (Najprostsze)

```bash
ollama create thoth-custom -f Modelfile
ollama run thoth-custom "Przetłumacz: Hello world"
```

### Axolotl (Zalecane dla produkcji)

```bash
axolotl train config/thoth-lora.yml
```

### HuggingFace TRL

```python
from trl import SFTTrainer
trainer = SFTTrainer(model, dataset, args)
trainer.train()
```

---

## 🎓 Przykłady użycia wytrenowanego modelu

### Tłumaczenie

```bash
> Przetłumacz na angielski: Dzień dobry!
Good morning!
```

### Analiza dokumentu

```bash
> Przeanalizuj CV: Jan Kowalski, 30 lat, informatyk...
Analiza CV:
- Kandydat: Jan Kowalski, 30 lat
- Wykształcenie: Informatyka
- Doświadczenie: ...
```

### OCR

```bash
> Odczytaj tekst z faktury: [obraz faktury]
Rozpoznano:
- Numer: FV/2023/001
- Data: 15.10.2023
- Kwota: 1234.56 PLN
```

---

## 🐛 Problemy?

### Dataset nie ładuje się

- Sprawdź czy plik JSON jest poprawny: `python3 validate_dataset.py`
- Upewnij się że plik nie jest uszkodzony

### Training out of memory

- Zmniejsz batch size do 2
- Włącz gradient checkpointing
- Użyj 8-bit quantization

### Loss nie spada

- Zwiększ learning rate
- Dodaj więcej epochs
- Sprawdź czy dataset się załadował

---

## 📞 Support

- **Dokumentacja**: README_THOTH_DATASET.md
- **Quick Start**: QUICK_START.md
- **LoRA Guide**: LORA_TRAINING_GUIDE.md
- **Interface**: app/training/ThothTraining.tsx

---

## ✅ Status

```
Dataset:       ✅ Generated (1000 examples)
Validation:    ✅ Passed (0 errors)
Balance:       ✅ Excellent (2.4% variance)
Format:        ✅ HuggingFace compatible
Documentation: ✅ Complete
Ready:         ✅ YES - Start training!
```

---

## 🎉 Następne kroki

1. ✅ Dataset gotowy → **thoth-training-1000.json**
2. ⏭️ Otwórz dashboard → **http://localhost:3001**
3. ⏭️ Kliknij Thoth → **"Train LoRA"**
4. ⏭️ Upload dataset → **Start Training**
5. ⏭️ Poczekaj ~20-30 min (GPU) lub 2-3h (CPU)
6. ⏭️ Deploy jako **thoth-custom:1**
7. ⏭️ Test i użycie!

---

**Created:** 2025-10-29  
**Version:** 1.0.0  
**Format:** Conversation  
**Examples:** 1000  
**Size:** 430 KB

🚀 **Ready to train Thoth!** 📚✨
