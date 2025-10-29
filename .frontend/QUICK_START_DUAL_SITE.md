# Quick Start - Dual Site Setup

## 🚀 Start Both Sites

From repository root:

```bash
cd /home/mrDinkelman/rice-mono
yarn dev
```

This starts:

- ✅ **Admin Panel** on **http://localhost:3001**
- ✅ **Marketing Site** on **http://localhost:3002**

---

## 🎯 Individual Sites

### Admin Panel (Port 3001)

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web
yarn dev
```

**Features:**

- Dashboard (6 gods)
- Model Management
- GiPT-1 Training (NEW!)
- LoRA Training
- Component Library

---

### Marketing Site (Port 3002)

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web-marketing
yarn dev
```

**Features:**

- Landing Page
- Pricing
- About GiPT-1
- Interactive Demo
- Contact Form

---

## 🐳 Docker

### Start with Docker Compose

From root:

```bash
docker-compose up ui-kit marketing-site
```

- Admin: http://localhost:3001
- Marketing: http://localhost:3002

### Individual containers

```bash
# Admin only
cd .frontend/web
./docker-dev.sh

# Marketing only
cd .frontend/web-marketing
./docker-dev.sh
```

---

## 📦 Workspaces

Yarn workspaces are configured:

```json
{
  "workspaces": [
    ".frontend/web", // Admin (3001)
    ".frontend/web-marketing", // Marketing (3002)
    ".project/web" // Next.js (if needed)
  ]
}
```

### Install all dependencies

```bash
cd /home/mrDinkelman/rice-mono
yarn install
```

This installs for all workspaces at once!

---

## 🔗 Shared Components

Both sites import from `@rice-mono/ui-kit`:

```tsx
// Admin (3001)
import { Button1, useOllama } from "../lib";

// Marketing (3002)
import { Button1, useOllama } from "@rice-mono/ui-kit";
```

The library is linked via:

- **Vite alias** (development)
- **Yarn workspace** (root install)
- **npm package** (future public use)

---

## 🛠️ Development Commands

From root directory:

```bash
# Start both sites
yarn dev

# Start admin only
yarn dev:admin

# Start marketing only
yarn dev:marketing

# Start everything (admin + marketing + next.js)
yarn dev:all

# Build all
yarn build

# Lint all
yarn lint

# Type check all
yarn typecheck
```

---

## 📊 Port Map

| Service         | Port  | Purpose                      |
| --------------- | ----- | ---------------------------- |
| **Admin Panel** | 3001  | GiPT-1 training & management |
| **Marketing**   | 3002  | Public website               |
| **Ollama**      | 11434 | LLM backend                  |
| **Ra (SD)**     | 8002  | Image generation backend     |

---

## ✅ Verification

### 1. Check Admin Panel

```bash
curl http://localhost:3001
# Should return HTML
```

Open http://localhost:3001 - see Dashboard with 6 gods

---

### 2. Check Marketing Site

```bash
curl http://localhost:3002
# Should return HTML
```

Open http://localhost:3002 - see landing page

---

### 3. Check Shared Library

```bash
cd .frontend/web
yarn build:lib
ls -la dist/
# Should have compiled lib/
```

---

## 🐛 Troubleshooting

### Port already in use

```bash
# Find and kill process on 3002
lsof -i :3002
kill -9 <PID>
```

### Workspace link broken

```bash
# From root
yarn install --force
```

### Can't import from ui-kit in marketing

Check vite.config.ts alias:

```ts
resolve: {
  alias: {
    "@rice-mono/ui-kit": resolve(__dirname, "../web/lib"),
  }
}
```

---

## 🎉 Success!

You should now have:

✅ **Port 3001** - Admin panel with GiPT-1 training  
✅ **Port 3002** - Marketing site with pricing  
✅ **Shared lib/** - Reusable components  
✅ **Docker** - Both sites containerized  
✅ **Workspaces** - Yarn monorepo setup

---

**Next:** Start training GiPT-1 and publish ui-kit to npm! 🚀
