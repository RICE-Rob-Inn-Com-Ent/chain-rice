# 🚀 Quick Commands - Panteon AI

## 🧹 1. Wyczyść VRAM (ZAWSZE PIERWSZY KROK!)

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer
./clear-vram.sh
```

lub ręcznie:

```bash
# Stop wszystkie bogi
docker-compose down

# Kill GPU processes
nvidia-smi --query-compute-apps=pid --format=csv,noheader | xargs -r kill -9

# Sprawdź VRAM
nvidia-smi
```

---

## 🏛️ 2. Uruchom Thoth (6GB VRAM)

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# Start Thoth
docker-compose up -d thoth

# Sprawdź logi (poczekaj na "Model loaded")
docker-compose logs -f thoth

# Ctrl+C aby wyjść z logów
```

**Oczekiwany output**:

```
✅ Pulling mistral:7b-instruct-q4_K_M... (tylko pierwszy raz, 2-5 min)
✅ Loading model to VRAM... (30-45 sekund)
✅ Model ready!
```

---

## 📊 3. Monitoruj VRAM

```bash
# Watch live
watch -n 1 nvidia-smi

# Tylko użycie pamięci
nvidia-smi --query-gpu=memory.used,memory.free,memory.total --format=csv --loop=1

# Procesy na GPU
nvidia-smi pmon -c 10
```

---

## 🔄 4. Zmień Boga (6GB VRAM - TYLKO JEDEN!)

```bash
# Stop Thoth
docker-compose stop thoth

# Poczekaj 5 sekund
sleep 5

# Sprawdź czy VRAM jest wolny
nvidia-smi

# Uruchom innego boga
docker-compose up -d isis    # lub ra, bastet, maat, khnum
```

---

## 🛑 5. Stop Wszystko

```bash
# Stop wszystkie bogi
docker-compose down

# Sprawdź czy wszystko zatrzymane
docker-compose ps

# Sprawdź VRAM
nvidia-smi
```

---

## 🔍 6. Diagnostyka

### Sprawdź status kontenerów

```bash
docker-compose ps
```

### Logi Thoth

```bash
docker-compose logs -f thoth
```

### Logi ostatnie 50 linii

```bash
docker-compose logs --tail=50 thoth
```

### Wejdź do kontenera

```bash
docker exec -it ai-god-thoth bash
```

### Sprawdź załadowane modele

```bash
docker exec ai-god-thoth ollama list
```

### Sprawdź czy model działa

```bash
docker exec ai-god-thoth ollama run mistral:7b-instruct-q4_K_M "Hello, I am Thoth"
```

---

## ⚡ 7. Quick Fixes

### Problem: Model nie ładuje się

```bash
# 1. Stop wszystko
docker-compose down

# 2. Wyczyść VRAM
./clear-vram.sh

# 3. Usuń stare volumen (UWAGA: usunie pobrane modele!)
docker volume rm devcontainer_thoth-models

# 4. Start ponownie
docker-compose up -d thoth

# 5. Pull model ręcznie
docker exec ai-god-thoth ollama pull mistral:7b-instruct-q4_K_M
```

### Problem: "Out of memory"

```bash
# 1. Zatrzymaj WSZYSTKO
docker-compose down
docker stop $(docker ps -aq)

# 2. Kill wszystkie procesy GPU
nvidia-smi --query-compute-apps=pid --format=csv,noheader | xargs -r kill -9

# 3. Sprawdź co jeszcze używa GPU
fuser -v /dev/nvidia*

# 4. Restart Docker (jeśli trzeba)
sudo systemctl restart docker

# 5. Sprawdź VRAM
nvidia-smi

# 6. Start tylko Thoth
docker-compose up -d thoth
```

### Problem: Wolne ładowanie

```bash
# Sprawdź czy używasz SSD
df -h /mnt/ssd

# Sprawdź I/O dysku
iostat -x 1

# Sprawdź czy model jest już pobrany
docker exec ai-god-thoth ollama list

# Jeśli nie - pull przed startem
docker exec ai-god-thoth ollama pull mistral:7b-instruct-q4_K_M
```

---

## 📈 8. Performance Testing

### Test inference speed

```bash
docker exec ai-god-thoth ollama run mistral:7b-instruct-q4_K_M "Write a haiku about AI" --verbose
```

### Benchmark VRAM usage

```bash
# Przed startem
nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits

# Po starcie
nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits

# Różnica = VRAM użyty przez model
```

---

## 🎯 9. Recommended Workflow (6GB VRAM)

```bash
# === Dzień pracy z Thoth ===

# 1. Rano - wyczyść i start
cd /home/mrDinkelman/rice-mono/.devcontainer
./clear-vram.sh
docker-compose up -d thoth

# 2. Praca przez web interface
# http://localhost:3000

# 3. Monitoruj VRAM co jakiś czas
watch -n 60 nvidia-smi

# 4. Wieczorem - stop
docker-compose stop thoth

# === Zmiana na innego boga ===

# 1. Stop Thoth
docker-compose stop thoth

# 2. Wait & verify
sleep 5 && nvidia-smi

# 3. Start innego
docker-compose up -d isis  # lub inny bóg

# 4. Check logs
docker-compose logs -f isis
```

---

## 💡 10. Pro Tips

### Alias dla szybkiego dostępu

Dodaj do `~/.bashrc`:

```bash
alias gods='cd /home/mrDinkelman/rice-mono/.devcontainer'
alias gods-clean='cd /home/mrDinkelman/rice-mono/.devcontainer && ./clear-vram.sh'
alias gods-start='cd /home/mrDinkelman/rice-mono/.devcontainer && docker-compose up -d thoth'
alias gods-stop='cd /home/mrDinkelman/rice-mono/.devcontainer && docker-compose down'
alias gods-logs='cd /home/mrDinkelman/rice-mono/.devcontainer && docker-compose logs -f'
alias gpu='watch -n 1 nvidia-smi'
```

Potem:

```bash
source ~/.bashrc

# Użycie:
gods              # cd do katalogu
gods-clean        # wyczyść VRAM
gods-start        # uruchom Thoth
gods-logs thoth   # zobacz logi
gpu               # monitoruj GPU
```

### Pre-download modeli

```bash
# Pobierz modele z góry (żeby nie czekać później)
docker exec ai-god-thoth ollama pull mistral:7b-instruct-q4_K_M

# Sprawdź rozmiar
docker exec ai-god-thoth ollama list
```

### Automatyczne czyszczenie przy starcie

Dodaj do `docker-compose.yml`:

```yaml
thoth:
  # ... inne opcje ...
  command: >
    sh -c "ollama serve &
           sleep 10 &&
           ollama pull mistral:7b-instruct-q4_K_M &&
           wait"
```

---

## 🆘 Emergency Commands

```bash
# Nuclear option - restart wszystko
docker-compose down
docker system prune -af --volumes
sudo systemctl restart docker
./clear-vram.sh
docker-compose up -d thoth

# Check if CUDA is working
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi

# Restart GPU (OSTROŻNIE!)
sudo rmmod nvidia_uvm
sudo modprobe nvidia_uvm
```

---

𓅝 **May Thoth guide you through VRAM management!** 𓁹
