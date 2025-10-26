# 🎉 RICE Portfolio & AI Gods - Complete Guide

## ✅ Co Zostało Zrobione

### 1. **Kompletny Panteon - 6 Bogów z Dockerfiles**

Każdy bóg to osobny kontener z zestawem narzędzi AI:

| Bóg    | Stack                                  | API Port | Dockerfile   |
| ------ | -------------------------------------- | -------- | ------------ |
| Thoth  | Mistral 7B + OCR + Translation + Donut | 8001     | gods/thoth/  |
| Ra     | Stable Diffusion + RealESRGAN + RVM    | 8002     | gods/ra/     |
| Isis   | Monai + Medical Imaging + LLaVa        | 8003     | gods/isis/   |
| Bastet | InsightFace + MMPose + MMDetection     | 8004     | gods/bastet/ |
| Maat   | Mistral + XLM-RoBERTa + Legal Analysis | 8005     | gods/maat/   |
| Khnum  | Mistral + PlotGPT + RecBole + Finance  | 8006     | gods/khnum/  |

### 2. **Portfolio - 6 Prawdziwych Projektów**

- 🏺 CeramiX (India e-commerce)
- 🫐 Superborówki (Japan IoT)
- ⚱️ Panteon AI (6 modeli)
- 🔧 Backend Microservices (Go)
- 📋 Proto Schema (600+ proto)
- ☁️ DevOps Infrastructure (K8s)

### 3. **Pakiety AI Models - 4 Poziomy**

- Simple (7B) - 499 PLN/mies
- Basic (13B) - 899 PLN/mies
- Pro (70B) - 2499 PLN/mies
- Commercial APIs - pay-as-go

### 4. **Tech Stack Grid - 30+ Technologii**

Cloud, AI, Infrastructure, Frontend, Backend, Database

### 5. **Thoth Sales Agent**

- Smart link provider
- Trigger words detection
- Quick buttons w ChatWidget
- LoRA fine-tuning support

---

## 🔮 GDZIE ROBIĆ LoRA DLA ASYSTENTA WSPARCIA

### **ODPOWIEDŹ: 2 MIEJSCA**

#### **Miejsce 1: LoRa Training Temple** (Główna strona) ⭐

**Lokalizacja**: http://localhost:3000 → scroll w dół

**Wygląd**: Fioletowa sekcja z napisem "🔮 LoRa Training Temple"

**Co robić**:

```
1. Przygotuj dataset: thoth-sales-training.jsonl
   Przykład:
   {"prompt": "Ile kosztują usługi?", "response": "𓅝 Od 4,900 PLN..."}
   {"prompt": "Pakiety AI?", "response": "𓅝 Mamy 4 pakiety..."}
   ... (50-500 przykładów)

2. Kliknij "➕ Stwórz Nowy Adapter"

3. Wypełnij formularz:
   - Nazwa: sales-agent-v1
   - Bazowy Bóg: Thoth - Text/Documents
   - Opis: Sales agent dla RICE
   - Rank: 8
   - Alpha: 16
   - Learning Rate: 0.0001
   - Epochs: 3
   - Dataset: [Upload thoth-sales-training.jsonl]

4. Kliknij "🚀 Stwórz i Zacznij Trenowanie"

5. Obserwuj progress bar (5-15 minut)

6. Po zakończeniu: "✅ Zastosuj"

7. Gotowe! ChatWidget używa nowego Thotha
```

#### **Miejsce 2: ChatWidget - Quick Upload** ⚡

**Lokalizacja**: Prawy dolny róg na każdej stronie

**Co robić**:

```
1. Kliknij chat (prawy dolny róg)

2. Kliknij "🔮 LoRA"

3. Upload gotowy plik (.safetensors, .bin, .pt)

4. Kliknij "🚀 Apply"

5. Gotowe! Adapter załadowany natychmiast
```

**Gdzie dostać gotowy plik LoRA?**

- Wytrenować przez LoRa Training Temple
- Pobrać z HuggingFace
- Wytrenować zewnętrznie (PEFT, Axolotl)

---

## 🐳 JAK ZOBACZYĆ WSZYSTKIE KONTENERY

### Metoda 1: Docker Addon (VS Code/Cursor)

1. Otwórz panel Docker w VS Code/Cursor
2. Sekcja "CONTAINERS"
3. Po uruchomieniu zobaczysz:

```
CONTAINERS
├── 📜 ai-god-thoth (running) - 11434, 8001
├── ☀️ ai-god-ra (running) - 8002
├── ✨ ai-god-isis (running) - 8003
├── 🐱 ai-god-bastet (running) - 8004
├── ⚖️ ai-god-maat (running) - 11438, 8005
└── 💰 ai-god-khnum (running) - 11439, 8006
```

### Metoda 2: Terminal

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# Wyświetl wszystkie kontenery
docker-compose ps

# Lub Docker native
docker ps --filter "name=ai-god"
```

### Metoda 3: Web Dashboard (Portainer - opcjonalne)

```bash
# Zainstaluj Portainer
docker run -d -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  portainer/portainer-ce

# Otwórz: http://localhost:9000
# Zobaczysz GUI wszystkich kontenerów
```

---

## 🚀 QUICK START - Uruchom Bogów

### Dla 6GB VRAM (TYLKO THOTH):

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# 1. Wyczyść VRAM
./clear-vram.sh

# 2. Build Thoth (pierwszy raz)
docker-compose build thoth

# 3. Start Thoth
docker-compose up -d thoth

# 4. Sprawdź status
docker-compose ps

# 5. Check health
curl http://localhost:8001/health

# 6. Zobacz w Docker addon!
```

### Dla 12GB+ VRAM (Kilku Bogów):

```bash
# Build wszystkich
./build-all-gods.sh

# Start 2-3 bogów (np. Thoth + Maat + Khnum)
docker-compose up -d thoth maat khnum

# Check
docker-compose ps
```

### Dla 24GB+ VRAM (Wszyscy Bogowie):

```bash
# Build
./build-all-gods.sh

# Start wszystkich
docker-compose --profile all up -d

# Check
docker-compose ps

# Powinieneś zobaczyć 6 kontenerów!
```

---

## 📊 Expected Docker Addon View

```
CONTAINERS (6)
├── ai-god-thoth    📜  Up (healthy)  11434:11434, 8001:8000
├── ai-god-ra       ☀️  Up (healthy)  8002:8000
├── ai-god-isis     ✨  Up (healthy)  8003:8000
├── ai-god-bastet   🐱  Up (healthy)  8004:8000
├── ai-god-maat     ⚖️  Up (healthy)  11438:11434, 8005:8000
└── ai-god-khnum    💰  Up (healthy)  11439:11434, 8006:8000

VOLUMES (12)
├── thoth-models, thoth-lora
├── ra-models, ra-lora
├── isis-models, isis-lora
├── bastet-models, bastet-lora
├── maat-models, maat-lora
└── khnum-models, khnum-lora

IMAGES (6)
├── devcontainer-thoth
├── devcontainer-ra
├── devcontainer-isis
├── devcontainer-bastet
├── devcontainer-maat
└── devcontainer-khnum
```

---

## 🎯 FINAŁ - Wszystko Gotowe!

### ✅ **Gotowe do Użycia:**

1. **Web Interface**: http://localhost:3000

   - Portfolio z 6 projektami
   - Pricing z pakietami AI
   - Tech stack z 30+ logo
   - ChatWidget z Thoth

2. **Demo Apps** (nowe okno, wymagają logowania):

   - /demo/thoth - Document analysis
   - /demo/ra - Image generation
   - /demo/isis - Medical imaging
   - /demo/bastet - Computer vision
   - /demo/maat - Legal analysis
   - /demo/khnum - Financial analytics

3. **LoRA Training**:

   - Strona główna → "LoRa Training Temple"
   - ChatWidget → "🔮 LoRA" button

4. **Docker Containers** (build i zobacz w addon):
   ```bash
   cd /home/mrDinkelman/rice-mono/.devcontainer
   ./build-all-gods.sh
   docker-compose up -d thoth  # lub więcej bogów
   ```

---

## 📍 **GDZIE ROBIĆ LoRA - FINAL ANSWER**

### **DLA ASYSTENTA WSPARCIA (ChatWidget):**

**Opcja 1 - Training od zera**:

- http://localhost:3000
- Scroll → "🔮 LoRa Training Temple"
- Upload dataset → Train

**Opcja 2 - Upload gotowego**:

- ChatWidget (prawy dolny róg)
- "🔮 LoRA" button
- Upload .safetensors

**Gdzie są pliki**:

- Training panel: Saves to `/lora-adapters/thoth/`
- ChatWidget upload: Uploads to Docker volume `thoth-lora`

---

🏛️ **Cały system kompletny! Build i zobacz w Docker addon!** 𓅝
