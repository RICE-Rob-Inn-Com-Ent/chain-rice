# 🚀 Quick Start - Trening Thotha

## ⚡ Szybki start w 3 krokach

### 1️⃣ Sprawdź dataset

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web/datasets
python3 validate_dataset.py thoth-training-1000.json
```

**Oczekiwany output:**

```
✅ Walidacja zakończona sukcesem
📊 Total Examples: 1000
⚖️  Dobrze zbalansowany (różnica: 2.4%)
```

---

### 2️⃣ Uruchom interfejs treningu

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web
yarn dev
```

Otwórz: **http://localhost:3001**

1. Kliknij na karcie **Thoth** przycisk **"Train LoRA"**
2. Interface ThothTraining się otworzy

---

### 3️⃣ Załaduj dataset i trenuj

W interfejsie:

1. **Sekcja "Training Dataset"**
   - Kliknij "Browse" lub przeciągnij `thoth-training-1000.json`
   - Pojawi się: ✅ _"1000 examples loaded"_

2. **Sekcja "Training Configuration"**
   - LoRA Rank: `16` (default)
   - Learning Rate: `0.0002` (default)
   - Epochs: `3` (zalecane)
   - Batch Size: `4`

3. **Kliknij "Start Training"**
   - Rozpocznie się trening (CPU lub GPU)
   - Progress bar pokaże postęp
   - Loss metrics będą aktualizowane

---

## 📊 Co będzie się działo podczas treningu?

```
Epoch 1/3: ████████░░░░░░░░░░░░ 40%
Loss: 1.234 → 0.856
ETA: 15 minutes

Task Progress:
  text_generation:      127/127 ✅
  translation_pl_to_en: 125/125 ✅
  translation_en_to_pl: 124/124 ✅
  ocr_simulation:        95/124 ⏳
  ...
```

---

## 🎯 Po zakończeniu treningu

### Otrzymasz:

1. **LoRA Adapter**: `thoth-lora-adapter/`
2. **Training Log**: `training_log.json`
3. **Metrics**: Loss curve, accuracy, BLEU scores

### Następne kroki:

```bash
# Testuj wytrenowany model
ollama create thoth-custom -f Modelfile

# Gdzie Modelfile:
# FROM mistral:7b-instruct-q4_K_M
# ADAPTER ./thoth-lora-adapter/adapter_model.bin

# Przetestuj
ollama run thoth-custom "Przetłumacz: Hello, how are you?"
# Output: "Witaj, jak się masz?"
```

---

## 💡 Wskazówki

### CPU vs GPU Training

| Device                  | Time (3 epochs) | Quality   |
| ----------------------- | --------------- | --------- |
| **CPU (16 cores)**      | ~2-3 hours      | Good      |
| **GPU (RTX 3060 6GB)**  | ~20-30 min      | Excellent |
| **GPU (RTX 4090 24GB)** | ~10 min         | Excellent |

### Optymalizacja dla 6GB VRAM

```python
# W training config dodaj:
"gradient_checkpointing": true,
"load_in_8bit": true,
"micro_batch_size": 2,
"gradient_accumulation_steps": 8
```

### Monitorowanie

```bash
# W osobnym terminalu:
watch -n 1 nvidia-smi  # Sprawdź VRAM usage
tail -f training_log.json  # Śledź progress
```

---

## 🐛 Common Issues

### Issue: "Out of memory"

**Solution:**

- Zmniejsz `batch_size` do `2`
- Włącz `gradient_checkpointing`
- Użyj `load_in_8bit: true`

### Issue: "Loss nie spada"

**Solution:**

- Zwiększ learning rate do `0.0003`
- Dodaj więcej epochs (5-7)
- Sprawdź czy dataset się poprawnie załadował

### Issue: "Model nie rozumie poleceń PL"

**Solution:**

- Dataset jest PL-heavy, ale jeśli problem:
- Dodaj więcej przykładów PL (użyj augmentation)
- Zwiększ LoRA rank do `32`

---

## 📚 Pełna dokumentacja

- **Dataset Details**: `README_THOTH_DATASET.md`
- **LoRA Training Guide**: `/home/mrDinkelman/rice-mono/.frontend/web/LORA_TRAINING_GUIDE.md`
- **Thoth Interface**: `/home/mrDinkelman/rice-mono/.frontend/web/app/training/ThothTraining.tsx`

---

## ✅ Checklist

Przed treningiem upewnij się:

- [ ] Dataset zwalidowany (`validate_dataset.py`)
- [ ] Ollama działa (`curl http://localhost:11434/api/tags`)
- [ ] Mistral 7B pobrany (`ollama list | grep mistral`)
- [ ] VRAM wolne (jeśli GPU): `nvidia-smi`
- [ ] Frontend działa (`http://localhost:3001`)

---

## 🎉 Gotowe!

Twój Thoth będzie wytrenowany na 1000 przykładach obejmujących:

- ✅ Generowanie tekstu
- ✅ Tłumaczenia PL↔EN
- ✅ OCR i analiza dokumentów
- ✅ Podsumowania i Q&A
- ✅ Ekstrakcja informacji

**Dataset: 1000 examples | Format: Conversation | Status: ✅ Validated**

🚀 **Start training now!**
