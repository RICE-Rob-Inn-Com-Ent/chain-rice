# Rice Backend - Docker Architecture Guide

## 🏗️ Struktura

Każdy moduł ma swój **Dockerfile + docker-compose.yml OBOK SIEBIE** dla łatwego zarządzania.

```
.backend/
├── docker-compose.yml           # 🌐 Root orchestration (ALL services)
│
├── data/                        # 📊 Data Layer
│   ├── Dockerfile               # → data:latest
│   ├── docker-compose.yml       # MongoDB + PostgreSQL + data service
│   ├── ddd/                     # Domain-Driven Design
│   └── cqrs/                    # Command Query Responsibility Segregation
│
├── bot/                         # 🤖 AI Bot Layer
│   ├── docker-compose.yml       # Orchestration: core + in + ollama
│   ├── core/                    # Core logic
│   │   ├── Dockerfile           # → core:latest
│   │   ├── docker-compose.yml   # Standalone core
│   │   └── requirements.txt
│   ├── in/                      # AI Integrations
│   │   ├── Dockerfile           # → in:latest
│   │   ├── docker-compose.yml   # Standalone integrations
│   │   ├── requirements.txt
│   │   ├── server.py            # FastAPI server
│   │   ├── open_ai.py           # OpenAI GPT-4
│   │   ├── claude.py            # Anthropic Claude
│   │   ├── gemini.py            # Google Gemini
│   │   └── benchmarks.py        # Model comparisons
│   ├── ollama/                  # Local LLM
│   │   ├── Dockerfile           # → ollama:latest
│   │   ├── docker-compose.yml   # Standalone ollama
│   │   └── setup.sh
│   ├── langgraph/               # Research agents
│   └── synthetic/               # Data generation
│
└── graphql/                     # 🔌 API Gateway
    ├── Dockerfile               # → graphql:latest
    ├── docker-compose.yml       # Standalone GraphQL
    └── subgraphs/
```

## 📦 Obrazy Docker

| Service          | Image                | Container        | Port  | Opis                                |
| ---------------- | -------------------- | ---------------- | ----- | ----------------------------------- |
| **Databases**    |
| MongoDB          | `mongo:7`            | rice-mongodb     | 27017 | NoSQL database                      |
| PostgreSQL       | `postgres:16-alpine` | rice-postgres    | 5432  | SQL database                        |
| **Services**     |
| Data Service     | `data:latest`        | rice-data        | 8080  | Go microservice (DDD+CQRS)          |
| Bot Core         | `core:latest`        | bot-core         | 8100  | Core bot logic                      |
| Bot Integrations | `in:latest`          | bot-integrations | 8200  | OpenAI, Claude, Gemini + benchmarks |
| Bot Ollama       | `ollama:latest`      | bot-ollama       | 11434 | Local LLM inference                 |
| GraphQL Gateway  | `graphql:latest`     | rice-graphql     | 4000  | Federated API                       |

## 🚀 Quick Start

### 1. Build All Services

```bash
cd /home/mrDinkelman/rice-mono/.backend
docker-compose build
```

### 2. Start All Services

```bash
cd /home/mrDinkelman/rice-mono/.backend
docker-compose up -d
```

### 3. Check Status

```bash
docker ps
docker-compose ps
```

### 4. View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f bot-integrations
```

## 🔧 Individual Services

### Data Service (DDD + CQRS)

```bash
cd .backend/data/
docker-compose up -d        # Start MongoDB + PostgreSQL + data service
docker-compose build data   # Rebuild data service
docker-compose logs -f data
```

### Bot Core

```bash
cd .backend/bot/core/
docker-compose up -d
docker-compose logs -f
```

### Bot Integrations (OpenAI, Claude, Gemini)

```bash
cd .backend/bot/in/

# Setup API keys first
cp .env.example .env
# Edit .env with your keys

docker-compose up -d
docker-compose logs -f
```

### Bot Ollama (Local LLM)

```bash
cd .backend/bot/ollama/
docker-compose up -d
docker-compose logs -f

# Pull a model
docker exec bot-ollama ollama pull mistral:7b
```

### GraphQL Gateway

```bash
cd .backend/graphql/
docker-compose up -d
docker-compose logs -f
```

### Full Bot Stack

```bash
cd .backend/bot/
docker-compose up -d   # Starts: core + integrations + ollama
```

## 🌐 API Endpoints

| Service          | Endpoint                    | Description                        |
| ---------------- | --------------------------- | ---------------------------------- |
| Data Service     | http://localhost:8080       | DDD/CQRS REST API                  |
| Bot Core         | http://localhost:8100       | Core bot logic                     |
| Bot Integrations | http://localhost:8200       | AI models (OpenAI, Claude, Gemini) |
| Bot Ollama       | http://localhost:11434      | Local LLM API                      |
| GraphQL          | http://localhost:4000       | Federated GraphQL                  |
| MongoDB          | mongodb://localhost:27017   | NoSQL database                     |
| PostgreSQL       | postgresql://localhost:5432 | SQL database                       |

## 🧪 Testing

### Health Checks

```bash
# Data service
curl http://localhost:8080/health

# Bot integrations
curl http://localhost:8200/health

# Ollama
curl http://localhost:11434/api/tags

# GraphQL
curl http://localhost:4000/health
```

### AI Chat Test

```bash
# OpenAI
curl -X POST http://localhost:8200/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai",
    "message": "Hello!"
  }'

# Claude
curl -X POST http://localhost:8200/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude",
    "message": "Hello!"
  }'

# Gemini
curl -X POST http://localhost:8200/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini",
    "message": "Hello!"
  }'
```

### Benchmark All Models

```bash
curl -X POST http://localhost:8200/benchmark \
  -H "Content-Type: application/json" \
  -d '{
    "models": ["openai", "claude", "gemini"],
    "prompt": "What is the capital of France?"
  }'
```

## 🔑 Environment Variables

### Bot Integrations (.backend/bot/in/.env)

```env
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=AIza...
```

### Data Service

```env
MONGO_URL=mongodb://rice-mongodb:27017/rice
POSTGRES_URL=postgres://rice:rice123@rice-postgres:5432/rice  # pragma: allowlist secret
```

## 🛠️ Development Workflow

### 1. Make Changes

Edit files in respective directories:

- Data: `.backend/data/`
- Bot: `.backend/bot/core/`, `.backend/bot/in/`
- GraphQL: `.backend/graphql/`

### 2. Rebuild Changed Service

```bash
# Example: After editing bot integrations
cd .backend/bot/in/
docker-compose build
docker-compose up -d
```

### 3. View Logs

```bash
docker-compose logs -f integrations
```

### 4. Restart Service

```bash
docker-compose restart integrations
```

## 🧹 Cleanup

```bash
# Stop all
cd .backend/
docker-compose down

# Remove volumes (⚠️ deletes data!)
docker-compose down -v

# Remove images
docker rmi data:latest core:latest in:latest ollama:latest graphql:latest
```

## 🐛 Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs <service>

# Inspect container
docker inspect <container-name>

# Restart
docker-compose restart <service>
```

### Port conflicts

Edit port mappings in respective `docker-compose.yml` files:

```yaml
ports:
  - "NEW_PORT:CONTAINER_PORT"
```

### Database connection errors

1. Check databases are healthy: `docker-compose ps`
2. Verify environment variables in `docker-compose.yml`
3. Check network connectivity: `docker network inspect rice-backend`

### Ollama GPU not found

```bash
# Verify NVIDIA Docker runtime
docker run --rm --gpus all nvidia/cuda:12.1-base nvidia-smi

# If fails, install nvidia-container-toolkit
```

## 📊 Monitoring

```bash
# Resource usage
docker stats

# Service status
docker-compose ps

# Healthchecks
docker inspect --format='{{.State.Health.Status}}' bot-core
```

## 🚢 Production Deployment

```bash
# Build for production
cd .backend/
docker-compose -f docker-compose.yml build

# Deploy
docker-compose up -d

# Scale specific service
docker-compose up -d --scale bot-core=3
```

---

**Architecture:** Microservices
**Container Runtime:** Docker 24+
**Networks:** Isolated per layer (rice-backend, bot-network, rice-data)
**Orchestration:** docker-compose v2
**Status:** ✅ Production Ready
