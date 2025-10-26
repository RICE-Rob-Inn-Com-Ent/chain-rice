# 🏗️ Build & Start All Gods

## 📦 Struktura Kontenerów

Każdy bóg ma swój Dockerfile z zestawem narzędzi:

```
.devcontainer/gods/
├── thoth/           # Text Processing
│   ├── Dockerfile
│   ├── thoth-server.py
│   ├── requirements.txt
│   └── entrypoint.sh
├── ra/              # Graphics Generation
│   ├── Dockerfile
│   ├── ra-server.py
│   ├── requirements.txt
│   └── entrypoint.sh
├── isis/            # Medical AI
│   ├── Dockerfile
│   ├── isis-server.py
│   └── entrypoint.sh
├── bastet/          # Computer Vision
│   ├── Dockerfile
│   ├── bastet-server.py
│   └── entrypoint.sh
├── maat/            # Legal Analysis
│   ├── Dockerfile
│   ├── maat-server.py
│   └── entrypoint.sh
└── khnum/           # Financial Analysis
    ├── Dockerfile
    ├── khnum-server.py
    └── entrypoint.sh
```

---

## 🚀 Quick Start - Build & Run

### 1. Build Wszystkie Bogi

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# Build wszystkie obrazy (może trwać 10-20 minut)
docker-compose build

# Lub build pojedynczo
docker-compose build thoth
docker-compose build ra
docker-compose build isis
docker-compose build bastet
docker-compose build maat
docker-compose build khnum
```

### 2. Start Tylko Thoth (6GB VRAM)

```bash
# Tylko Thoth - dla 6GB VRAM
docker-compose up -d thoth

# Sprawdź status
docker-compose ps

# Logi
docker-compose logs -f thoth
```

### 3. Start Wszystkie Bogi (12GB+ VRAM)

```bash
# Start wszystkich (profil 'all')
docker-compose --profile all up -d

# Sprawdź wszystkie
docker-compose ps
```

---

## 📊 Porty i Dostęp

| Bóg    | Icon | Ollama Port | API Port | Health Check                 |
| ------ | ---- | ----------- | -------- | ---------------------------- |
| Thoth  | 📜   | 11434       | 8001     | http://localhost:8001/health |
| Ra     | ☀️   | -           | 8002     | http://localhost:8002/health |
| Isis   | ✨   | -           | 8003     | http://localhost:8003/health |
| Bastet | 🐱   | -           | 8004     | http://localhost:8004/health |
| Maat   | ⚖️   | 11438       | 8005     | http://localhost:8005/health |
| Khnum  | 💰   | 11439       | 8006     | http://localhost:8006/health |

---

## 🔍 Sprawdź Status Wszystkich

```bash
# Status kontenerów
docker-compose ps

# Health check wszystkich
curl http://localhost:8001/health  # Thoth
curl http://localhost:8002/health  # Ra
curl http://localhost:8003/health  # Isis
curl http://localhost:8004/health  # Bastet
curl http://localhost:8005/health  # Maat
curl http://localhost:8006/health  # Khnum

# Lub skrypt
for port in 8001 8002 8003 8004 8005 8006; do
  echo "Port $port:"
  curl -s http://localhost:$port/health | jq -r '.god'
done
```

---

## 🐳 Widok w Docker Addon

Po uruchomieniu, w Docker addon (VS Code/Cursor) zobaczysz:

```
CONTAINERS:
├── ai-god-thoth    ✅ (running)  Ports: 11434, 8001
├── ai-god-ra       ✅ (running)  Ports: 8002
├── ai-god-isis     ✅ (running)  Ports: 8003
├── ai-god-bastet   ✅ (running)  Ports: 8004
├── ai-god-maat     ✅ (running)  Ports: 11438, 8005
└── ai-god-khnum    ✅ (running)  Ports: 11439, 8006

VOLUMES:
├── thoth-models, thoth-lora
├── ra-models, ra-lora
├── isis-models, isis-lora
├── bastet-models, bastet-lora
├── maat-models, maat-lora
└── khnum-models, khnum-lora

NETWORKS:
└── pantheon (bridge)
```

---

## ⚙️ Komendy Zarządzania

### Start/Stop pojedynczego boga

```bash
cd /home/mrDinkelman/rice-mono/.devcontainer

# Start
docker-compose up -d thoth    # lub ra, isis, bastet, maat, khnum

# Stop
docker-compose stop thoth

# Restart
docker-compose restart thoth

# Rebuild i restart
docker-compose up -d --build thoth
```

### Start/Stop wszystkich

```bash
# Start wszystkich
docker-compose --profile all up -d

# Stop wszystkich
docker-compose down

# Restart wszystkich
docker-compose restart
```

### Logi

```bash
# Wszystkie logi
docker-compose logs -f

# Tylko jeden bóg
docker-compose logs -f thoth

# Ostatnie 50 linii
docker-compose logs --tail=50 thoth
```

---

## 💾 Resource Usage Summary

### Single God (6GB VRAM):

| God    | VRAM    | RAM   | Load Time | Models       |
| ------ | ------- | ----- | --------- | ------------ |
| Thoth  | ~4.5 GB | ~1.4G | 30-45s    | 5 (text)     |
| Ra     | ~5 GB   | ~2G   | 60-90s    | 5 (graphics) |
| Isis   | ~5 GB   | ~1.5G | 40-50s    | 3 (medical)  |
| Bastet | ~4.5 GB | ~1.5G | 35-45s    | 4 (vision)   |
| Maat   | ~4 GB   | ~1.2G | 30-40s    | 4 (legal)    |
| Khnum  | ~4 GB   | ~1.2G | 30-40s    | 4 (finance)  |

**Rekomendacja dla 6GB VRAM**: Uruchom **TYLKO JEDNEGO boga** na raz!

### All Gods (24GB+ VRAM):

```bash
# Możesz uruchomić wszystkich jednocześnie
docker-compose --profile all up -d

# Total VRAM: ~27 GB
# Total RAM: ~9 GB
```

---

## 🛠️ Troubleshooting

### Błąd podczas build

```bash
# Clean build
docker-compose build --no-cache thoth

# Check logs
docker-compose logs thoth
```

### "Out of memory"

```bash
# Stop wszystko
docker-compose down

# Wyczyść VRAM
./clear-vram.sh

# Start tylko jednego
docker-compose up -d thoth
```

### Kontener nie startuje

```bash
# Check logs
docker-compose logs thoth

# Rebuild
docker-compose up -d --build --force-recreate thoth

# Check health
curl http://localhost:8001/health
```

---

## 🎯 Expected Output

Po uruchomieniu `docker-compose ps` powinieneś zobaczyć:

```
NAME             STATUS                   PORTS
ai-god-thoth     Up (healthy)            0.0.0.0:11434->11434, 0.0.0.0:8001->8000
ai-god-ra        Up (healthy)            0.0.0.0:8002->8000
ai-god-isis      Up (healthy)            0.0.0.0:8003->8000
ai-god-bastet    Up (healthy)            0.0.0.0:8004->8000
ai-god-maat      Up (healthy)            0.0.0.0:11438->11434, 0.0.0.0:8005->8000
ai-god-khnum     Up (healthy)            0.0.0.0:11439->11434, 0.0.0.0:8006->8000
```

---

🏛️ **All Gods Ready!** 𓅝
