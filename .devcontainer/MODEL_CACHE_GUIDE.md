# 💾 Model Caching Guide

## ❓ Czy Trzeba Cachować Modele?

### **TAK! Zdecydowanie warto!** ✅

**Dlaczego?**

1. **Pierwsze uruchomienie**: Modele muszą się **pobrać z internetu**

   - Mistral 7B Q4: **~4 GB** (5-10 minut download)
   - Stable Diffusion 2.1: **~5 GB** (10-15 minut)
   - InsightFace: **~500 MB** (2-3 minuty)
   - RealESRGAN: **~60 MB** (30 sekund)

2. **Bez cachowania**: Za każdym razem gdy restartujesz kontener - pobiera od nowa!

3. **Z cachowaniem**: Modele zapisane w Docker volumes - instant start!

---

## 📦 Co Jest Cachowane

### Thoth (Text):

```
Volume: thoth-models
Zawiera:
├── mistral:7b-instruct-q4_K_M    (~4 GB)
└── LoRA adapters                  (~10-50 MB każdy)
```

### Ra (Graphics):

```
Volume: ra-models
Zawiera:
├── stable-diffusion-2-1           (~5 GB)
├── RealESRGAN_x4plus              (~60 MB)
├── RVM background removal         (~150 MB)
└── LoRA adapters                  (~50-200 MB każdy)
```

### Isis (Medical):

```
Volume: isis-models
Zawiera:
├── Monai pretrained models        (~500 MB)
├── LLaVa-13B (optional)           (~7 GB)
└── Medical imaging models         (~200 MB)
```

### Bastet (Vision):

```
Volume: bastet-models
Zawiera:
├── InsightFace models             (~500 MB)
├── MMPose checkpoints             (~300 MB)
├── MMDetection models             (~200 MB)
└── Face recognition DBs           (~100 MB)
```

### Maat & Khnum (Text):

```
Volume: maat-models, khnum-models
Zawiera:
├── mistral:7b-instruct-q4_K_M    (~4 GB każdy)
├── XLM-RoBERTa                    (~500 MB)
└── LoRA adapters                  (~10-50 MB)
```

**TOTAL**: ~30-40 GB (wszystkie bogi + modele)

---

## 🚀 Jak Cachować Modele

### Metoda 1: Automatyczny Skrypt (ZALECANE) ⭐

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# 1. Start wszystkich bogów (lub tych którzy cię interesują)
docker-compose up -d thoth    # tylko Thoth
# lub
docker-compose --profile all up -d   # wszyscy

# 2. Czekaj 30-60 sekund aż kontenery się uruchomią
sleep 60

# 3. Cachuj modele
./cache-models.sh

# Proces zajmie 20-40 minut (zależy od internetu)
```

### Metoda 2: Ręcznie dla Każdego Boga

#### Thoth (Mistral):

```bash
docker exec ai-god-thoth ollama pull mistral:7b-instruct-q4_K_M
```

#### Ra (Stable Diffusion):

```bash
docker exec ai-god-ra python -c "
from diffusers import StableDiffusionPipeline
import torch
pipeline = StableDiffusionPipeline.from_pretrained(
    'stabilityai/stable-diffusion-2-1',
    torch_dtype=torch.float16,
)
print('✅ SD 2.1 cached')
"
```

#### Maat & Khnum (Mistral):

```bash
docker exec ai-god-maat ollama pull mistral:7b-instruct-q4_K_M
docker exec ai-god-khnum ollama pull mistral:7b-instruct-q4_K_M
```

### Metoda 3: Pre-download przed Build (Advanced)

Możesz dodać do Dockerfile:

```dockerfile
# W gods/thoth/Dockerfile dodaj:
RUN ollama serve & \
    sleep 10 && \
    ollama pull mistral:7b-instruct-q4_K_M && \
    pkill ollama
```

Ale **NIE ZALECANE** - lepiej cachować po build (Metoda 1).

---

## 📊 Sprawdź Cache

### Ile miejsca zajmują modele?

```bash
# Volumes
docker volume ls | grep models

# Rozmiar każdego volume
docker system df -v | grep models

# Szczegóły
docker volume inspect thoth-models | grep Mountpoint
du -sh /var/lib/docker/volumes/devcontainer_thoth-models
```

### Które modele są załadowane?

```bash
# Thoth
docker exec ai-god-thoth ollama list

# Maat
docker exec ai-god-maat ollama list

# Khnum
docker exec ai-god-khnum ollama list
```

### Sprawdź w VRAM (jeśli uruchomione):

```bash
nvidia-smi
```

---

## 🧹 Czyszczenie Cache (gdy brakuje miejsca)

### Usuń modele pojedynczo:

```bash
# Usuń z Thoth
docker exec ai-god-thoth ollama rm mistral:7b-instruct-q4_K_M

# Usuń volume (UWAGA: traci wszystkie modele!)
docker volume rm devcontainer_thoth-models
```

### Wyczyść wszystko:

```bash
# Stop wszystko
docker-compose down

# Usuń wszystkie volumes
docker volume rm $(docker volume ls -q | grep devcontainer)

# Rebuild i re-cache
docker-compose build
docker-compose up -d thoth
./cache-models.sh
```

---

## ⏱️ Czas Pobierania (pierwsze uruchomienie)

### Bez cachowania:

```
Start Thoth → pobiera Mistral (~4GB) → 5-10 minut
Start Ra → pobiera SD 2.1 (~5GB) → 10-15 minut
Start Bastet → pobiera InsightFace (~500MB) → 2-3 minuty
```

**TOTAL first run**: 30-40 minut pobierania!

### Z cachowaniem:

```
Start Thoth → modele już są → 30 sekund
Start Ra → modele już są → 45 sekund
Start Bastet → modele już są → 30 sekund
```

**TOTAL cached**: 2-3 minuty!

---

## 💡 Best Practices

### 1. Cache Po Build

```bash
# 1. Build
docker-compose build thoth

# 2. Start
docker-compose up -d thoth

# 3. Wait
sleep 60

# 4. Cache
./cache-models.sh

# 5. Teraz możesz restart bez pobierania!
docker-compose restart thoth  # instant!
```

### 2. Backup Volumes

```bash
# Backup models do tar
docker run --rm \
  -v devcontainer_thoth-models:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/thoth-models-backup.tar.gz /data

# Restore
docker run --rm \
  -v devcontainer_thoth-models:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/thoth-models-backup.tar.gz -C /
```

### 3. Monitoring Disk Space

```bash
# Check total Docker disk usage
docker system df

# Check specific volumes
docker volume ls | grep models | while read -r line; do
    name=$(echo $line | awk '{print $2}')
    size=$(docker system df -v | grep $name | awk '{print $3}')
    echo "$name: $size"
done
```

---

## 🎯 Recommended Workflow

### Dla 6GB VRAM:

```bash
# 1. Build Thoth
docker-compose build thoth

# 2. Start
docker-compose up -d thoth

# 3. Wait & cache
sleep 60 && ./cache-models.sh

# 4. Teraz Thoth ma wszystkie modele!
# Restart będzie instant (30s zamiast 10 minut)
```

### Dla 12GB+ VRAM:

```bash
# 1. Build kilku bogów
docker-compose build thoth maat khnum

# 2. Start
docker-compose up -d thoth maat khnum

# 3. Cache
sleep 90 && ./cache-models.sh

# 4. Wszystkie modele cached!
```

### Dla 24GB+ VRAM:

```bash
# 1. Build wszystkich
./build-all-gods.sh

# 2. Start wszystkich
docker-compose --profile all up -d

# 3. Wait dla startu
sleep 120

# 4. Cache wszystkie modele
./cache-models.sh

# To pobierze ~30-40GB modeli
# Może trwać 1-2 godziny (zależy od internetu)
# Ale potem instant start!
```

---

## 📝 TL;DR

**Q: Czy muszę cachować?** A: Nie musisz, ale **BARDZO zalecane!**

**Q: Co się stanie bez cachowania?** A: Modele pobierają się przy każdym pierwszym użyciu (wolno!)

**Q: Jak cachować?** A: `./cache-models.sh` po uruchomieniu kontenerów

**Q: Ile to zajmuje miejsca?** A: ~30-40 GB dla wszystkich bogów

**Q: Ile czasu?** A: Pierwsze cachowanie: 30-60 minut. Potem instant!

---

🏛️ **Cache modele raz, używaj wiecznie!** 𓅝
