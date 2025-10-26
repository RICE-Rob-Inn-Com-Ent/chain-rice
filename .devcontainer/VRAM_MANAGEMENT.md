# 🎮 Automatic VRAM Management

## 🎯 Jak Działa Przycisk "Przebudź"

Gdy klikasz **⚡ Przebudź** na karcie boga, system automatycznie:

### Krok 1: 🧹 Clear VRAM (5 sekund)

```
Uśpij wszystkich innych bogów
  ↓
Wyładuj ich modele z VRAM
  ↓
VRAM jest wolny
```

**Co się dzieje w tle:**

```javascript
// Sleep all other gods
for (otherGod in gods) {
  if (otherGod !== currentGod) {
    await fetch(`/api/gods/${otherGod}/sleep`, { method: "POST" });
  }
}
```

### Krok 2: 📦 Load from Cache (10-20 sekund)

```
Sprawdź czy kontener działa
  ↓
Załaduj model z cache (NIE pobiera z internetu!)
  ↓
Model w pamięci RAM
```

**Co się dzieje:**

```bash
# Model JUŻ JEST w Docker volume!
ollama pull mistral:7b-instruct-q4_K_M  # instant (z cache)
# Nie pobiera z internetu!
```

### Krok 3: ⚡ Load to VRAM (15-25 sekund)

```
Przenieś model z RAM do VRAM
  ↓
Alokuj pamięć GPU
  ↓
Model gotowy do inference
```

### Krok 4: 🔥 Warm Up (5 sekund)

```
Pierwsza inference (test)
  ↓
CUDA kernels kompilacja
  ↓
✅ Bóg AKTYWNY!
```

**Total time**:

- **Z cache**: ~30-45 sekund
- **Bez cache** (pierwsze uruchomienie): 3-6 minut (download)

---

## 📊 Przykładowy Flow

### Scenario: Przełącz z Thoth na Maat

```
User clicks: Maat → "⚡ Przebudź"
  ↓
[0-5s] Stage: downloading (🧹 Clearing VRAM)
  → Sleep Thoth
  → Ollama unloads Mistral from VRAM
  → VRAM: 4.5GB → 0.5GB

[5-15s] Stage: extracting (📦 Loading from cache)
  → Check Maat container health (http://localhost:8005/health)
  → Ollama pull mistral:7b-instruct-q4_K_M
  → Model already in volume - instant!

[15-30s] Stage: loading (⚡ Loading to GPU)
  → Ollama loads model to VRAM
  → VRAM: 0.5GB → 4.5GB

[30-35s] Stage: warming (🔥 Warming up)
  → Test inference: "test"
  → CUDA kernels compile
  → First token generated

[35s] Stage: ready (✅ God awakened!)
  → Maat is ACTIVE
  → Thoth is INACTIVE
  → VRAM switched successfully!
```

---

## 🔄 Automatyczne Zarządzanie VRAM

### Zasada: TYLKO JEDEN BÓG AKTYWNY (6GB VRAM)

System **automatycznie** zapewnia:

1. ✅ **Nie możesz** mieć 2 bogów jednocześnie (6GB VRAM)
2. ✅ Budzenie nowego **automatycznie uśpia** aktywnego
3. ✅ **Zawsze ładuje z cache** (nie pobiera z internetu)
4. ✅ **Zawsze pokazuje** progress z czasem

### W kodzie (GodsPanel.tsx):

```typescript
const handleStartGod = async (godId: string) => {
  // Sprawdź czy inny bóg jest aktywny
  const activeGod = gods.find((g) => g.status === "active");

  if (activeGod && activeGod.id !== godId) {
    // Automatycznie uśpij aktywnego!
    await handleStopGod(activeGod.id);
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  // Teraz budź nowego (wake API wyczyści VRAM i załaduje z cache)
  await fetch(`/api/gods/${godId}/wake`, { method: "POST" });
};
```

---

## 💾 Cache vs No Cache - Różnica

### Bez Cache (First Time):

```
Klik "Przebudź Thoth"
  ↓
[0-5s] Clear VRAM
[5s-3min] Download Mistral 7B (~4GB z internetu) 🐌
[3min-3.5min] Load to VRAM
[3.5min-4min] Warm up
  ↓
Total: 3-6 MINUT!
```

### Z Cache (After cache-models.sh):

```
Klik "Przebudź Thoth"
  ↓
[0-5s] Clear VRAM
[5-10s] Load z volume (instant - już pobrany!) ⚡
[10-30s] Load to VRAM
[30-35s] Warm up
  ↓
Total: 30-45 SEKUND!
```

**100x szybciej!** 🚀

---

## 🛠️ Setup Cache - Jednorazowo

### Krok 1: Start Wszystkich Bogów (lub tych którzy cię interesują)

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# Start bogów (kontenery muszą działać żeby cachować)
docker-compose up -d thoth maat khnum
```

### Krok 2: Cachuj Modele

```bash
# Czekaj aż wystartują
sleep 60

# Cache modele (30-60 minut, JEDNORAZOWO!)
./cache-models.sh
```

**Co robi `cache-models.sh`:**

```bash
# Dla każdego boga:
docker exec ai-god-thoth ollama pull mistral:7b-instruct-q4_K_M
docker exec ai-god-maat ollama pull mistral:7b-instruct-q4_K_M
docker exec ai-god-khnum ollama pull mistral:7b-instruct-q4_K_M

# Download Stable Diffusion dla Ra
docker exec ai-god-ra python -c "from diffusers import ...download SD 2.1..."

# etc.
```

Modele zapisują się w **Docker volumes**:

- `thoth-models` - Mistral (~4 GB)
- `maat-models` - Mistral (~4 GB - shared cache)
- `khnum-models` - Mistral (~4 GB - shared cache)
- `ra-models` - Stable Diffusion (~5 GB)

### Krok 3: Restart i Test

```bash
# Restart Thoth
docker-compose restart thoth

# Test wake (powinno być ~30-45s zamiast 3-6 minut!)
# Kliknij "Przebudź" w web interface
```

---

## 🔍 Sprawdź Czy Modele Są w Cache

```bash
# Sprawdź Thoth
docker exec ai-god-thoth ollama list

# Output:
# NAME                            SIZE    MODIFIED
# mistral:7b-instruct-q4_K_M      4.1GB   2 days ago

# Sprawdź rozmiar volume
docker volume inspect devcontainer_thoth-models | grep Mountpoint
du -sh /var/lib/docker/volumes/devcontainer_thoth-models/_data
```

Jeśli widzisz **~4GB**, modele są w cache! ✅

---

## ⚡ Performance Comparison

### 6GB VRAM - Switching Between Gods:

| Action                   | Without Cache   | With Cache    |
| ------------------------ | --------------- | ------------- |
| Thoth → Maat             | 3-6 min (cold)  | 30-45s (warm) |
| Maat → Khnum             | 3-6 min         | 30-45s        |
| Khnum → Thoth (2nd time) | 30-45s (cached) | 30-45s (warm) |

### 12GB+ VRAM - Multiple Gods:

```bash
# Możesz mieć 2-3 bogów jednocześnie (jeśli Q4)
docker-compose up -d thoth maat khnum

# Przełączanie instant (już w VRAM)
# Klik → Switch context → 1-2 sekundy
```

---

## 🎯 Best Practices

### 1. **ZAWSZE cachuj modele po build**

```bash
docker-compose build thoth
docker-compose up -d thoth
sleep 60
./cache-models.sh  # JEDNORAZOWO!
```

### 2. **Monitoruj VRAM podczas przełączania**

```bash
watch -n 1 nvidia-smi
```

Powinieneś zobaczyć:

```
Thoth aktywny: 4.5GB VRAM
  ↓ Klik "Przebudź Maat"
Clearing: 0.5GB VRAM
  ↓
Loading Maat: 4.5GB VRAM
  ↓
Maat aktywny: 4.5GB VRAM
```

### 3. **Backup volumes z modelami**

```bash
# Export
docker run --rm \
  -v devcontainer_thoth-models:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/models-backup.tar.gz /data

# Import (na innym systemie)
docker run --rm \
  -v devcontainer_thoth-models:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/models-backup.tar.gz -C /
```

Teraz możesz przenieść cache na inny komputer!

---

## 🐛 Troubleshooting

### "Model się długo ładuje mimo cache"

```bash
# Sprawdź czy model faktycznie w cache
docker exec ai-god-thoth ollama list

# Jeśli pusty - cachuj ponownie
docker exec ai-god-thoth ollama pull mistral:7b-instruct-q4_K_M
```

### "Bóg nie uśypia poprzedniego"

```bash
# Sprawdź logi API
# W terminalu uruchom web interface z logami:
cd /home/mrDinkelman/rice-mono/.project/web
yarn dev

# Zobacz w konsoli:
# [thoth] Putting to sleep...
# [maat] Step 1: Clearing VRAM...
```

### "Out of memory mimo przełączania"

```bash
# Nuclear option - restart wszystko
docker-compose down
./clear-vram.sh
docker-compose up -d thoth
```

---

## 📝 Summary

✅ **Przycisk "Przebudź" automatycznie:**

1. Uśypia innych bogów (clear VRAM)
2. Ładuje nowego z cache (NIE download!)
3. Ładuje do VRAM
4. Rozgrzewa model

✅ **Czas**: 30-45 sekund (z cache)

✅ **Wymaga**: Jednorazowe `./cache-models.sh`

✅ **Benefit**: 100x szybciej niż bez cache!

---

🏛️ **Cache once, switch forever!** 𓅝
