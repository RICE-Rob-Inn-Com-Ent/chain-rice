# 🔮 LoRA Training dla Asystenta Wsparcia (ChatWidget)

## 🎯 Cel

Dostroić Thotha (Mistral 7B Q4) żeby był **lepszym sales agentem** dla RICE:

- Znał szczegóły wszystkich projektów
- Lepiej wykrywał intencje klientów
- Odpowiadał bardziej sprzedażowo
- Poprawnie kierował do odpowiednich sekcji

---

## 📝 Krok 1: Przygotuj Dataset Treningowy

### Format: JSONL (JSON Lines)

Stwórz plik `thoth-sales-training.jsonl`:

```jsonl
{"prompt": "Ile kosztują wasze usługi?", "response": "𓅝 Oferujemy pakiety od 4,900 PLN (Start) do rozwiązań Enterprise. Dodatkowo mamy specjalistyczne pakiety AI models od 499 PLN/mies.\n\n───────\n📋 Przydatne linki:\n[link:/pricing|Zobacz cennik]\n[link:/pricing#ai-packages|Pakiety AI]\n[link:/contact|Porozmawiaj o projekcie]"}
{"prompt": "Jakie macie projekty dla zagranicy?", "response": "𓅝 Realizujemy projekty międzynarodowe: CeramiX (platforma e-commerce dla Indii) i Superborówki (Flutter IoT dla Japonii).\n\n───────\n📋 Przydatne linki:\n[link:/portfolio/ceramix|CeramiX - India]\n[link:/portfolio/superborowki|Superborówki - Japan]\n[link:/portfolio|Wszystkie projekty]"}
{"prompt": "Czy robicie aplikacje mobilne?", "response": "𓅝 Tak! Tworzymy aplikacje w Flutter (iOS/Android) oraz native (Swift/Kotlin). Przykład: Superborówki - IoT app dla Japonii.\n\n───────\n📋 Przydatne linki:\n[link:/portfolio/superborowki|Superborówki]\n[link:/services|Nasze usługi]\n[link:/contact|Omów projekt]"}
{"prompt": "Macie doświadczenie z AI?", "response": "𓅝 Specjalizujemy się w AI! Stworzyliśmy Panteon - system 6 modeli AI. Oferujemy hosting modeli (7B-70B) oraz integracje z OpenAI/Claude.\n\n───────\n📋 Przydatne linki:\n[link:/portfolio/pantheon-ai|Panteon AI]\n[link:/pricing#ai-packages|Pakiety AI]\n[link:/services|AI Services]"}
{"prompt": "Gdzie mogę was znaleźć?", "response": "𓅝 Skontaktuj się przez formularz kontaktowy lub sprawdź dane zespołu.\n\n───────\n📋 Przydatne linki:\n[link:/contact|Formularz kontaktu]\n[link:/team|Zespół]\n[link:/about|O nas]"}
{"prompt": "Jakie technologie używacie?", "response": "𓅝 Używamy nowoczesnego stacku: Next.js, React, Go, Python, Docker, Kubernetes. Cloud: AWS, Azure. AI: OpenAI, Claude, Ollama.\n\n───────\n📋 Przydatne linki:\n[link:/about#tech-stack|Pełny tech stack]\n[link:/services|Usługi]\n[link:/portfolio|Projekty]"}
{"prompt": "Czy robicie backend?", "response": "𓅝 Tak! Specjalizujemy się w mikrousługach Go z CQRS, DDD, GraphQL i gRPC. Mamy 600+ Protocol Buffer schemas.\n\n───────\n📋 Przydatne linki:\n[link:/portfolio/backend-microservices|Backend]\n[link:/portfolio/schema-system|Proto Schemas]\n[link:/services|Usługi backend]"}
{"prompt": "Potrzebuję DevOps", "response": "𓅝 Oferujemy pełne rozwiązania DevOps: Kubernetes, Terraform, Ansible, CI/CD pipelines.\n\n───────\n📋 Przydatne linki:\n[link:/portfolio/devops-infra|DevOps Infrastructure]\n[link:/services|Cloud Services]\n[link:/contact|Omów projekt]"}
{"prompt": "Jaki pakiet AI wybrać?", "response": "𓅝 Zależy od potrzeb:\n• Simple (7B) - podstawowe zadania, 499 PLN\n• Basic (13B) - zaawansowane, 899 PLN\n• Pro (70B) - enterprise, 2499 PLN\n• Commercial APIs - pay-as-go\n\n───────\n📋 Przydatne linki:\n[link:/pricing#ai-packages|Pakiety AI]\n[link:/contact|Doradztwo]"}
{"prompt": "Co to jest CeramiX?", "response": "𓅝 CeramiX to platforma e-commerce z AI image generation dla indyjskiego rynku ceramiki artystycznej. Next.js + Stable Diffusion.\n\n───────\n📋 Przydatne linki:\n[link:/portfolio/ceramix|CeramiX]\n[link:/portfolio|Inne projekty]\n[link:/contact|Podobny projekt?]"}
```

**Ilość danych**: Minimum 50-100 przykładów, idealnie 200-500

---

## 🛠️ Krok 2: Gdzie Trenować LoRA

### Opcja A: Przez Web Interface (ZALECANE)

1. **Otwórz**: http://localhost:3000
2. **Scroll** do sekcji "🔮 LoRa Training Temple"
3. **Kliknij**: "➕ Stwórz Nowy Adapter"
4. **Wypełnij**:

   - Nazwa: `thoth-sales-agent-v1`
   - Bazowy Bóg: `📜 Thoth - Text/Documents`
   - Opis: `Sales agent dla RICE - lepsze odpowiedzi sprzedażowe i routing`
   - Rank: `8` (balans jakość/rozmiar)
   - Alpha: `16` (2 × rank)
   - Learning Rate: `0.0001`
   - Epochs: `3`
   - **Dataset**: Upload `thoth-sales-training.jsonl`

5. **Zaawansowane** (opcjonalne):

   - Batch Size: `4` (jeśli masz RAM)
   - Warmup Steps: `100`
   - Weight Decay: `0.01`

6. **Kliknij**: "🚀 Stwórz i Zacznij Trenowanie"

7. **Obserwuj** progress bar:

   - Epoch 1/3... Loss: 0.523
   - Epoch 2/3... Loss: 0.312
   - Epoch 3/3... Loss: 0.187
   - ✅ Training complete!

8. **Apply**: Kliknij "✅ Zastosuj" po zakończeniu

---

### Opcja B: Przez ChatWidget (Quick Upload)

Jeśli masz już wytrenowany adapter (.safetensors):

1. **Otwórz** ChatWidget (prawy dolny róg)
2. **Kliknij**: "🔮 LoRA"
3. **Upload** plik: `thoth-sales-agent-v1.safetensors`
4. **Kliknij**: "🚀 Apply"
5. ✅ Thoth od razu używa nowego adaptera!

---

### Opcja C: Ręcznie (Advanced)

Jeśli chcesz użyć zewnętrznych narzędzi (Axolotl, PEFT):

```bash
# 1. Przygotuj środowisko
cd /tmp
python -m venv lora-env
source lora-env/bin/activate
pip install torch transformers peft datasets accelerate

# 2. Stwórz skrypt treningowy
cat > train_thoth_lora.py << 'EOF'
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from datasets import load_dataset
import torch

# Load base model (Mistral 7B)
model_name = "mistralai/Mistral-7B-Instruct-v0.2"
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    load_in_4bit=True,
    device_map="auto",
)
tokenizer = AutoTokenizer.from_pretrained(model_name)

# Prepare for training
model = prepare_model_for_kbit_training(model)

# LoRA config
lora_config = LoraConfig(
    r=8,  # rank
    lora_alpha=16,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
)

model = get_peft_model(model, lora_config)

# Load dataset
dataset = load_dataset("json", data_files="thoth-sales-training.jsonl")

# Training arguments
from transformers import TrainingArguments, Trainer

training_args = TrainingArguments(
    output_dir="./thoth-sales-lora",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    learning_rate=1e-4,
    fp16=True,
    logging_steps=10,
    save_strategy="epoch",
)

# Train
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset["train"],
)

trainer.train()

# Save adapter
model.save_pretrained("./thoth-sales-lora-final")
print("✅ LoRA adapter saved to ./thoth-sales-lora-final")
EOF

# 3. Trenuj
python train_thoth_lora.py

# 4. Upload do Thoth
# Plik będzie w: ./thoth-sales-lora-final/adapter_model.safetensors
# Upload przez ChatWidget lub skopiuj do volumenu Docker
```

---

## 📊 Krok 3: Zastosuj Wytrenowany Adapter

### Metoda 1: Przez API

```bash
curl -X POST http://localhost:8001/lora/load \
  -H "Content-Type: application/json" \
  -d '{
    "adapter_name": "thoth-sales-agent-v1",
    "adapter_path": "/lora-adapters/thoth-sales-agent-v1.safetensors"
  }'
```

### Metoda 2: Przez Docker Volume

```bash
# Skopiuj adapter do volumenu
docker cp ./thoth-sales-lora-final/adapter_model.safetensors \
  ai-god-thoth:/lora-adapters/sales-agent.safetensors

# Restart Thoth
cd /home/mrDinkelman/rice-mono/.devcontainer
docker-compose restart thoth
```

### Metoda 3: Przez ChatWidget (NAJŁATWIEJSZE)

1. Otwórz ChatWidget
2. Kliknij "🔮 LoRA"
3. Upload plik
4. Gotowe!

---

## 🧪 Krok 4: Testuj Wytrenowany Model

### Test 1: Sprawdź czy lepiej odpowiada

```
Przed LoRA:
User: "Ile kosztują wasze usługi?"
Thoth: "𓅝 Nasze ceny można sprawdzać na stronie naszego cennika..."
(Ogólna odpowiedź)

Po LoRA:
User: "Ile kosztują wasze usługi?"
Thoth: "𓅝 Oferujemy pakiety od 4,900 PLN (Start) oraz AI models od 499 PLN/mies.

───────
📋 Przydatne linki:
[link:/pricing|Cennik web]
[link:/pricing#ai-packages|Pakiety AI]
[link:/contact|Wycena indywidualna]"
(Konkretnie + lepsze linki!)
```

### Test 2: Sprawdź trigger words

```
User: "Macie coś dla Indii?"
Thoth: "𓅝 Tak! CeramiX - platforma e-commerce z AI dla indyjskiego rynku ceramiki.

───────
📋 Przydatne linki:
[link:/portfolio/ceramix|CeramiX]
[link:/portfolio|Inne projekty]"
```

### Test 3: ChatWidget Performance

Otwórz ChatWidget i zadaj 5-10 pytań:

- "Pakiety AI?"
- "CeramiX?"
- "Backend w Go?"
- "Kubernetes?"
- "Gdzie kontakt?"

Sprawdź czy:

- ✅ Odpowiedzi są zwięzłe (2-3 zdania)
- ✅ Zawsze dostajeszlinki
- ✅ Linki są adekwatne do pytania
- ✅ Nie gada za dużo

---

## 📍 GDZIE ROBIĆ LoRA - PODSUMOWANIE

### 🎯 Dla Sales Chatbot (ChatWidget):

#### **Najłatwiejsze** - Przez Web Interface:

**Lokalizacja**: http://localhost:3000 → scroll w dół do "🔮 LoRa Training Temple"

**Kroki**:

1. Przygotuj `thoth-sales-training.jsonl` (50-500 przykładów Q&A)
2. Kliknij "➕ Stwórz Nowy Adapter"
3. Wypełnij formularz:
   - Nazwa: `sales-agent-v1`
   - Bóg: Thoth
   - Opis: `Sales agent dla RICE`
   - Rank: `8`, Alpha: `16`, LR: `0.0001`, Epochs: `3`
   - **Upload dataset**: `thoth-sales-training.jsonl`
4. Kliknij "🚀 Stwórz i Zacznij Trenowanie"
5. Czekaj 5-15 minut (zależy od rozmiaru datasetu)
6. Po zakończeniu kliknij "✅ Zastosuj"
7. **Gotowe!** ChatWidget używa nowego Thotha

#### **Szybkie** - Upload Gotowego Adaptera:

Jeśli masz już `.safetensors`:

**Przez ChatWidget**:

1. Kliknij chat (prawy dolny róg)
2. Kliknij "🔮 LoRA"
3. Upload plik
4. Kliknij "🚀 Apply"

**Przez API**:

```bash
curl -X POST http://localhost:3000/api/lora/upload \
  -F "file=@sales-agent-v1.safetensors" \
  -F "godId=thoth"
```

---

## 💡 Tips dla Lepszego Datasetu

### Do Datasetu Dodaj:

1. **Częste pytania klientów**:

   - "Ile kosztuje?"
   - "Jak długo trwa projekt?"
   - "Jakie macie doświadczenie?"
   - "Czy robicie na zamówienie?"

2. **Trigger words dla projektów**:

   - "indie", "india" → CeramiX
   - "japonia", "japan" → Superborówki
   - "ai", "modele" → Panteon/Pakiety AI
   - "backend", "go" → Backend microservices

3. **Różne warianty pytań**:

   ```
   "Ile kosztują usługi?"
   "Jaki jest koszt?"
   "Cennik?"
   "Ile płacę?"
   ```

   Wszystkie powinny dawać podobną odpowiedź

4. **Edge cases**:
   - "Nie rozumiem" → Link do kontaktu
   - "Mam problem" → Link do wsparcia
   - "Dziękuję" → Uprzejma odpowiedź + linki

### Przykładowy Dataset (50 entries):

```jsonl
{"prompt": "Witaj", "response": "𓅝 Witaj! Jestem Thoth, asystentem RICE. Jak mogę pomóc?\n\n───────\n📋 Przydatne linki:\n[link:/services|Usługi]\n[link:/pricing|Cennik]\n[link:/portfolio|Portfolio]\n[link:/contact|Kontakt]"}
{"prompt": "Dzień dobry", "response": "𓅝 Dzień dobry! W czym mogę pomóc?\n\n───────\n📋 Przydatne linki:\n[link:/services|Nasze usługi]\n[link:/pricing|Cennik]\n[link:/contact|Skontaktuj się]"}
{"prompt": "Ile kosztuje strona?", "response": "𓅝 Strony od 4,900 PLN (Start) do rozwiązań Enterprise. Zależy od złożoności.\n\n───────\n📋 Przydatne linki:\n[link:/pricing|Zobacz cennik]\n[link:/contact|Wycena indywidualna]"}
{"prompt": "Ile kosztuje aplikacja mobilna?", "response": "𓅝 Aplikacje mobilne wyceniamy indywidualnie. Przykład: Flutter app Superborówki dla Japonii.\n\n───────\n📋 Przydatne linki:\n[link:/portfolio/superborowki|Superborówki]\n[link:/pricing|Pakiety]\n[link:/contact|Wycena]"}
{"prompt": "Potrzebuję AI chatbot", "response": "𓅝 Tworzymy chatboty! Oferujemy hosting modeli 7B-70B oraz integracje z OpenAI/Claude.\n\n───────\n📋 Przydatne linki:\n[link:/pricing#ai-packages|Pakiety AI]\n[link:/portfolio/pantheon-ai|Panteon AI]\n[link:/contact|Omów projekt]"}
```

Stwórz 50-100 takich przykładów pokrywających wszystkie możliwe pytania!

---

## 🎓 Parametry Trenowania - Co Oznaczają

### Rank (r): `8`

- Rozmiar adaptera
- Niższe (4-8): Mniejszy plik, szybszy, mniej parametrów
- Wyższe (16-32): Większy plik, więcej parametrów, lepsza jakość
- **Rekomendacja**: `8` dla chatbota

### Alpha (α): `16`

- Scaling factor
- Typowo: `2 × rank`
- **Rekomendacja**: `16` (jeśli rank=8)

### Learning Rate: `0.0001`

- Jak szybko model się uczy
- Za wysoki: Niestabilny trening
- Za niski: Wolne uczenie, może nie nauczyć się
- **Rekomendacja**: `0.0001` (1e-4)

### Epochs: `3`

- Ile razy model przejdzie przez cały dataset
- 1-2: Za mało, nie nauczy się
- 3-5: Optymalnie
- 7+: Overfitting
- **Rekomendacja**: `3`

### Batch Size: `4`

- Ile przykładów na raz
- Wyższe: Szybszy trening, więcej RAM
- Niższe: Wolniejszy, mniej RAM
- **Rekomendacja**: `4` (dla 16GB RAM), `1` (dla 8GB RAM)

---

## 🔍 Monitoring Treningu

Podczas trenowania możesz sprawdzać:

```bash
# Logi trenowania
docker exec ai-god-thoth tail -f /lora-adapters/sales-agent-v1/training.log

# Sprawdź loss
docker exec ai-god-thoth cat /lora-adapters/sales-agent-v1/metrics.json

# CPU/RAM usage
docker stats ai-god-thoth
```

Dobry trening:

- Loss spada: 0.8 → 0.5 → 0.2
- Nie oscyluje wildly
- Kończy się < 0.3

---

## 📦 Export i Backup

Po wytrenowaniu, wyeksportuj adapter:

```bash
# Skopiuj z kontenera
docker cp ai-god-thoth:/lora-adapters/sales-agent-v1.safetensors \
  ./backups/thoth-sales-$(date +%Y%m%d).safetensors

# Lub przez web UI
# Kliknij "💾 Export" w LoRa Training Panel
```

Zapisz na:

- GitHub (private repo)
- Google Drive
- External HDD

Możesz później upload ponownie przez ChatWidget!

---

## 🚀 Quick Start Script

```bash
#!/bin/bash
# Quick LoRA training dla Thoth sales agent

echo "🔮 LoRA Training dla Thoth Sales Agent"
echo "======================================"

# 1. Sprawdź czy Thoth działa
echo "1. Sprawdzam Thoth..."
curl -s http://localhost:11434/api/tags > /dev/null && echo "✅ Thoth OK" || echo "❌ Start Thoth first!"

# 2. Sprawdź dataset
echo "2. Sprawdzam dataset..."
if [ ! -f "thoth-sales-training.jsonl" ]; then
    echo "❌ Brak pliku thoth-sales-training.jsonl!"
    echo "Stwórz plik z przykładami Q&A"
    exit 1
fi
LINES=$(wc -l < thoth-sales-training.jsonl)
echo "✅ Dataset: $LINES przykładów"

# 3. Upload do web interface
echo "3. Otwórz w przeglądarce:"
echo "   http://localhost:3000"
echo ""
echo "4. Scroll do 'LoRa Training Temple'"
echo ""
echo "5. Upload dataset: thoth-sales-training.jsonl"
echo ""
echo "6. Trenuj!"
echo ""
echo "⏱️  Szacowany czas: $((LINES / 10)) - $((LINES / 5)) minut"
```

---

## 🎯 Expected Results

Po wytrenowaniu sales agent powinien:

✅ **Lepiej rozumieć** intencje (sprzedaż vs info vs wsparcie) ✅ **Zwięźlej odpowiadać** (maks 2-3 zdania) ✅ **Lepsze
linki** (trafniejsze w kontekście) ✅ **Trigger words** (automatycznie wykrywa "ceramix" → link) ✅ **Sprzedażowo**
(zachęca do kontaktu/cennika)

Przed: Ogólne odpowiedzi, czasem za długie Po: Konkret, linki, sales-oriented, zwięźle

---

## 📍 **PODSUMOWANIE: Gdzie Robić LoRA**

### DLA ASYSTENTA WSPARCIA (ChatWidget):

1. **Najłatwiej**:

   - http://localhost:3000
   - Scroll → "🔮 LoRa Training Temple"
   - Upload dataset → Train → Apply

2. **Najszybciej** (jeśli masz adapter):

   - ChatWidget → "🔮 LoRA" → Upload → Apply

3. **Dla zaawansowanych**:
   - Python script z PEFT
   - Export → Upload przez widget

**Lokalizacja plików LoRA**:

- Web upload → `/tmp/lora-adapters/thoth/`
- Docker volume → `thoth-lora:/lora-adapters/`
- Training panel → API handles everything

---

🔮 **Gotowe! Możesz teraz trenować własnego sales agenta!** 𓅝
