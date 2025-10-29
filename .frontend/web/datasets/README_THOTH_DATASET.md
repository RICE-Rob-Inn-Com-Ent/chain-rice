# Thoth Training Dataset - Documentation

## 📚 Przegląd

Dataset treningowy dla **Thoth - Boga Mądrości i Tekstu**, zawierający **1000 przykładów** do treningu LoRA dla stack
modeli NLP.

---

## 🎯 Stack modeli Thoth

- **Mistral 7B Instruct Q4** - Text generation, reasoning
- **PaddleOCR** - Optical Character Recognition
- **Opus-MT** - Translation PL↔EN
- **Donut** - Document analysis & understanding

---

## 📊 Struktura datasetu

```json
{
  "dataset_info": {
    "name": "Thoth NLP Training Dataset",
    "version": "1.0.0",
    "total_examples": 1000,
    "format": "conversation"
  },
  "training_examples": [
    {
      "id": 1,
      "task": "text_generation",
      "conversation": [
        { "role": "user", "content": "..." },
        { "role": "assistant", "content": "..." }
      ]
    }
  ]
}
```

---

## 🔍 Typy zadań (Tasks)

| Task                       | Count | Description                                         |
| -------------------------- | ----- | --------------------------------------------------- |
| **text_generation**        | 127   | Generowanie tekstu, opisy, artykuły, instrukcje     |
| **translation_pl_to_en**   | 125   | Tłumaczenie polski → angielski                      |
| **translation_en_to_pl**   | 124   | Tłumaczenie angielski → polski                      |
| **ocr_simulation**         | 124   | Rozpoznawanie tekstu z obrazów (faktury, wizytówki) |
| **document_analysis**      | 125   | Analiza dokumentów (umowy, CV, raporty)             |
| **summarization**          | 125   | Streszczanie długich tekstów                        |
| **qa**                     | 125   | Pytania i odpowiedzi (Q&A)                          |
| **information_extraction** | 125   | Ekstrakcja danych z tekstu                          |

**Total**: 1000 przykładów

---

## 🚀 Jak użyć datasetu?

### 1. Załaduj dataset w interfejsie LoRA Training

W dashboardzie (http://localhost:3001):

1. Kliknij na karcie **Thoth** przycisk **"Train LoRA"**
2. Przejdź do sekcji **Training Dataset**
3. Kliknij **"Upload Dataset"** lub wybierz plik:
   ```
   /home/mrDinkelman/rice-mono/.frontend/web/datasets/thoth-training-1000.json
   ```
4. Dataset zostanie automatycznie zwalidowany

---

### 2. Użyj z Ollama CLI (przyszłość)

```bash
# Przygotuj format Ollama
ollama create thoth-custom -f Modelfile

# W Modelfile:
# FROM mistral:7b-instruct-q4_K_M
# ADAPTER ./thoth-lora.bin
# SYSTEM "You are Thoth, the Egyptian god of wisdom and text."
```

---

### 3. Format treningu LoRA (HuggingFace)

Dataset jest kompatybilny z formatem **conversational** używanym przez:

- **Axolotl** (preferred)
- **HuggingFace TRL**
- **PEFT (Parameter-Efficient Fine-Tuning)**

Przykładowy config dla Axolotl:

```yaml
base_model: mistralai/Mistral-7B-Instruct-v0.1
model_type: MistralForCausalLM

datasets:
  - path: thoth-training-1000.json
    type: conversation
    field_messages: conversation
    message_field_role: role
    message_field_content: content

lora_r: 16
lora_alpha: 32
lora_dropout: 0.05
lora_target_modules:
  - q_proj
  - v_proj
  - k_proj
  - o_proj

# Training params
num_epochs: 3
micro_batch_size: 4
gradient_accumulation_steps: 4
learning_rate: 0.0002
warmup_steps: 100
```

---

## 📝 Przykłady z datasetu

### Text Generation

```json
{
  "user": "Napisz krótki opis starożytnego Egiptu.",
  "assistant": "Starożytny Egipt to jedna z najstarszych..."
}
```

### Translation PL→EN

```json
{
  "user": "Przetłumacz na angielski: Dzień dobry, jak się masz?",
  "assistant": "Good morning, how are you?"
}
```

### OCR Simulation

```json
{
  "user": "Rozpoznaj tekst z obrazu faktury: [IMAGE]...",
  "assistant": "Rozpoznany tekst: FAKTURA VAT NR 2023/10/001..."
}
```

### Document Analysis

```json
{
  "user": "Przeanalizuj CV: 'Jan Nowak, 30 lat...'",
  "assistant": "Analiza CV: Kandydat: Jan Nowak, 30 lat..."
}
```

---

## 🧬 Proces treningu LoRA

### Krok 1: Przygotowanie środowiska

```bash
# CPU Training (demo)
docker run --rm -it \
  -v $(pwd)/datasets:/datasets \
  -v $(pwd)/models:/models \
  python:3.10

pip install transformers peft accelerate datasets
```

### Krok 2: Trening

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import LoraConfig, get_peft_model
from datasets import load_dataset

# Load model
model = AutoModelForCausalLM.from_pretrained("mistralai/Mistral-7B-Instruct-v0.1")
tokenizer = AutoTokenizer.from_pretrained("mistralai/Mistral-7B-Instruct-v0.1")

# LoRA config
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    lora_dropout=0.05,
    target_modules=["q_proj", "v_proj"],
    task_type="CAUSAL_LM"
)

# Apply LoRA
model = get_peft_model(model, lora_config)

# Load dataset
dataset = load_dataset('json', data_files='thoth-training-1000.json')

# Train (simplified)
from transformers import Trainer, TrainingArguments

training_args = TrainingArguments(
    output_dir="./thoth-lora",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    learning_rate=2e-4,
    save_steps=100
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset['train']
)

trainer.train()
```

### Krok 3: Eksport i deployment

```bash
# Zapisz adapter LoRA
python -c "model.save_pretrained('./thoth-lora-adapter')"

# Testuj lokalnie
ollama create thoth-custom -f Modelfile
ollama run thoth-custom "Przetłumacz: Hello world"
```

---

## 🎓 Specjalizacja Thotha

Po wytrenowaniu na tym datasecie, Thoth będzie specjalizował się w:

✅ **Przetwarzanie dokumentów biznesowych** (faktury, umowy, CV)  
✅ **Tłumaczenie PL↔EN** z kontekstem branżowym  
✅ **Rozpoznawanie i ekstrakcja danych** z skanów  
✅ **Analiza i podsumowanie** długich tekstów  
✅ **Generowanie profesjonalnej treści** (maile, raporty, posty)  
✅ **Odpowiadanie na pytania** w języku naturalnym

---

## 💡 Best Practices

### 1. **Walidacja datasetu**

Przed treningiem sprawdź:

```bash
python3 << 'EOF'
import json
with open('thoth-training-1000.json') as f:
    data = json.load(f)
    print(f"✅ Total examples: {len(data['training_examples'])}")
    assert all('conversation' in ex for ex in data['training_examples'])
    print("✅ Format valid")
EOF
```

### 2. **Balansowanie tasków**

Dataset jest już zbalansowany (~125 przykładów per task), ale możesz dodać więcej:

```python
# Filtruj tylko translation tasks
translation_only = [ex for ex in data['training_examples']
                    if 'translation' in ex['task']]
```

### 3. **Augmentacja danych**

Możesz zwiększyć dataset poprzez:

- Parafrazowanie promptów
- Dodanie szumu (typos) do symulacji OCR
- Back-translation (PL→EN→PL)

---

## 🔧 Troubleshooting

### Problem: "Out of memory during training"

**Rozwiązanie:**

```yaml
# Zmniejsz batch size
micro_batch_size: 2
gradient_accumulation_steps: 8

# Użyj gradient checkpointing
gradient_checkpointing: true

# 8-bit quantization
load_in_8bit: true
```

### Problem: "Model nie uczy się tłumaczeń"

**Rozwiązanie:**

- Zwiększ liczbę przykładów translation (do 500+)
- Dodaj więcej kontekstu w promptach
- Zwiększ LoRA rank: `lora_r: 32`

### Problem: "Training loss nie spada"

**Rozwiązanie:**

```yaml
# Zwiększ learning rate
learning_rate: 0.0003

# Więcej epochs
num_epochs: 5

# Dodaj warmup
warmup_steps: 200
```

---

## 📈 Metryki sukcesu

Po 3 epochs treningu, oczekiwane wyniki:

| Metric                   | Target |
| ------------------------ | ------ |
| Training Loss            | < 0.5  |
| BLEU Score (translation) | > 30   |
| Accuracy (QA)            | > 85%  |
| F1 Score (extraction)    | > 0.80 |

---

## 🚀 Kolejne kroki

1. ✅ Dataset gotowy (1000 przykładów)
2. ⏳ Uruchom trening w interfejsie LoRA
3. ⏳ Monitoruj training loss
4. ⏳ Waliduj na test set
5. ⏳ Deploy jako `thoth-custom:1` w Ollama
6. ⏳ Dodaj do dashboardu jako nowy "god"

---

## 📚 Referencje

- **Mistral 7B**: https://mistral.ai/news/announcing-mistral-7b/
- **LoRA Paper**: https://arxiv.org/abs/2106.09685
- **PEFT Library**: https://github.com/huggingface/peft
- **Axolotl**: https://github.com/OpenAccess-AI-Collective/axolotl

---

## 📞 Support

Problemy z datasetем? Otwórz issue lub sprawdź:

- `LORA_TRAINING_GUIDE.md` - główny guide dla LoRA
- `app/training/ThothTraining.tsx` - interfejs treningu
- Rice Mono docs: `.document/docs/`

---

**Dataset wygenerowany:** 2025-10-29  
**Format:** Conversation (HuggingFace compatible)  
**Licencja:** MIT (do użytku w projekcie rice-mono)

🎉 **Gotowy do treningu Thotha!** 📚✨
