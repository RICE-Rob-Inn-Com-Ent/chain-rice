# 🐳 Complete Docker Setup Guide

## 📋 Wszystkie Serwisy

### Frontend (2 serwisy)

- **UI Kit** (Vite) - Port 5173 - `ui.rice.local`
- **Next.js Web** - Port 3001 - `app.rice.local`

### Backend Core (6 serwisów)

- **MongoDB** - Port 27017
- **PostgreSQL** - Port 5432
- **Data Service** - Port 8080
- **GraphQL Gateway** - Port 4000 - `api.rice.local`
- **Bot Core** - Port 8100
- **Bot Integrations** - Port 8200

### Gods - AI Services (6 bogów)

- **⚱️ Thoth** (Text) - Ports 8001, 11434 - `thoth.rice.local`
- **☀️ Ra** (Graphics) - Port 8002 - `ra.rice.local`
- **✨ Isis** (Medical) - Port 8003 - `isis.rice.local`
- **🐱 Bastet** (Vision) - Port 8004 - `bastet.rice.local`
- **⚖️ Maat** (Legal) - Ports 8005, 11438 - `maat.rice.local`
- **💰 Khnum** (Finance) - Ports 8006, 11439 - `khnum.rice.local`

### Monitoring Stack (7 serwisów)

- **Traefik** (Proxy) - Ports 80, 443, 8080
- **Prometheus** (Metrics) - Port 9090
- **Loki** (Logs) - Port 3100
- **Grafana** (Dashboards) - Port 3000 - `grafana.rice.local`
- **Elasticsearch** (Search) - Ports 9200, 9300
- **Logstash** (Pipeline) - Ports 5000, 9600
- **Jaeger** (Tracing) - Port 16686 - `jaeger.rice.local`

## 🚀 Uruchamianie

### 1. Backend Core (podstawowe serwisy)

```bash
docker-compose up -d mongodb postgres data graphql bot-core bot-integrations
```

### 2. Frontend (UI + App)

```bash
docker-compose up -d ui-kit nextjs-web
```

### 3. Gods (wszystkie AI serwisy)

```bash
docker-compose --profile gods up -d
```

Lub pojedynczo:

```bash
docker-compose up -d thoth      # Tylko Thoth
docker-compose up -d ra         # Tylko Ra
docker-compose up -d isis       # Tylko Isis
docker-compose up -d bastet     # Tylko Bastet
docker-compose up -d maat       # Tylko Maat
docker-compose up -d khnum      # Tylko Khnum
```

### 4. Monitoring Stack

```bash
docker-compose --profile monitoring up -d
```

### 5. WSZYSTKO NARAZ

```bash
docker-compose --profile all up -d
```

## 🎯 Profiles

Docker Compose używa profili do grupowania serwisów:

- **Bez profilu**: Backend Core + Frontend (podstawowe serwisy)
- **`--profile gods`**: Tylko Gods (AI services)
- **`--profile monitoring`**: Tylko Monitoring Stack
- **`--profile all`**: WSZYSTKO (21 serwisów!)

## 📊 Status i Zarządzanie

```bash
# Status wszystkich serwisów
docker-compose ps

# Status z konkretnym profilem
docker-compose --profile all ps

# Logi
docker-compose logs -f [service-name]

# Zatrzymaj wszystko
docker-compose down

# Zatrzymaj z konkretnym profilem
docker-compose --profile all down

# Usuń wszystko łącznie z wolumenami
docker-compose --profile all down -v

# Rebuild konkretnego serwisu
docker-compose up -d --build <service-name>
```

## 🌐 Domeny Lokalne (Traefik)

Aby korzystać z domen lokalnych, dodaj do `/etc/hosts`:

```bash
# Rice Mono Services
127.0.0.1 ui.rice.local
127.0.0.1 app.rice.local
127.0.0.1 api.rice.local
127.0.0.1 grafana.rice.local
127.0.0.1 jaeger.rice.local
127.0.0.1 thoth.rice.local
127.0.0.1 ra.rice.local
127.0.0.1 isis.rice.local
127.0.0.1 bastet.rice.local
127.0.0.1 maat.rice.local
127.0.0.1 khnum.rice.local
```

Potem uruchom Traefik:

```bash
docker-compose --profile monitoring up -d traefik
```

## 🔧 Konfiguracje

Wszystkie konfiguracje są w `.devcontainer/config/`:

```
.devcontainer/config/
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── datasources.yml
├── prometheus/
│   └── prometheus.yml
├── loki/
│   └── loki-config.yml
├── traefik/
│   └── traefik.yml
└── logstash/
    ├── logstash.yml
    └── pipeline/
        └── logstash.conf
```

## 💾 Wolumeny

### Bazy danych

- `mongo-data` - MongoDB data
- `postgres-data` - PostgreSQL data

### Gods Models

- `thoth-models`, `maat-models`, `khnum-models` - Ollama models
- `ra-models`, `isis-models`, `bastet-models` - ML models
- `*-lora` - LoRA adapters dla każdego boga

### Monitoring

- `prometheus-data` - Metrics
- `loki-data` - Logs
- `grafana-data` - Dashboards
- `elasticsearch-data` - Search indices

### Cache

- `bazel-cache` - Build cache
- `model-cache` - Shared model cache

## 🎨 Przykłady Użycia

### Scenariusz 1: Tylko development frontend

```bash
docker-compose up -d mongodb postgres data graphql
docker-compose up -d ui-kit nextjs-web
```

### Scenariusz 2: Backend + 1 God (np. Thoth)

```bash
docker-compose up -d mongodb postgres data graphql bot-core bot-integrations
docker-compose up -d thoth
```

### Scenariusz 3: Full stack z monitoringiem

```bash
# Backend + Frontend
docker-compose up -d

# Monitoring
docker-compose --profile monitoring up -d

# Gods
docker-compose --profile gods up -d
```

### Scenariusz 4: Production (wszystko)

```bash
docker-compose --profile all up -d
```

## 🏥 Health Checks

Wszystkie serwisy mają health checks:

```bash
# Sprawdź zdrowie wszystkich
docker-compose ps

# Testuj endpointy
curl http://localhost:8100/health  # Bot Core
curl http://localhost:4000/health  # GraphQL
curl http://localhost:8001/health  # Thoth
curl http://localhost:3000         # Grafana
```

## 🐛 Troubleshooting

### Gods nie budują się (network timeout)

```bash
# Buduj pojedynczo z większym timeout
docker-compose build --no-cache thoth
```

### Brak miejsca na dysku

```bash
# Wyczyść nieużywane zasoby
docker system prune -af --volumes
```

### Port zajęty

```bash
# Sprawdź co używa portu
sudo lsof -i :8080

# Zatrzymaj konfliktujący serwis
docker-compose stop <service-name>
```

### Restart pojedynczego serwisu

```bash
docker-compose restart <service-name>
docker-compose logs -f <service-name>
```

## 📈 Zasoby

### Minimalne wymagania

- **RAM**: 8GB
- **Disk**: 50GB wolnego
- **CPU**: 4 cores

### Zalecane dla wszystkich serwisów

- **RAM**: 32GB
- **Disk**: 200GB+ (modele AI zajmują dużo)
- **CPU**: 8+ cores
- **GPU**: NVIDIA (dla Gods services)

## 🎯 Quick Start

```bash
# 1. Podstawowe serwisy
docker-compose up -d

# 2. Sprawdź status
docker-compose ps

# 3. Zobacz logi
docker-compose logs -f

# 4. Dodaj Gods (jak sieć będzie stabilna)
docker-compose --profile gods up -d

# 5. Dodaj Monitoring
docker-compose --profile monitoring up -d

# 6. Zatrzymaj wszystko
docker-compose --profile all down
```

---

**Wszystko w jednym pliku**: `docker-compose.yml` 🎉 **Configuracje**: `.devcontainer/config/` 📁 **Profiles**: `gods`,
`monitoring`, `all` 🏷️
