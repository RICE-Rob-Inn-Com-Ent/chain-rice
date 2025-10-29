# Dual Site Architecture - Rice AI

## 🏗️ Overview

Rice AI frontend is split into **two separate applications** sharing a common component library:

```
┌─────────────────────────────────────────────────────────────────┐
│                     RICE AI ECOSYSTEM                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Port 3001                          Port 3002                   │
│  ┌────────────────┐                ┌────────────────┐          │
│  │ ADMIN PANEL    │                │ MARKETING SITE │          │
│  │ (GiPT-1)       │                │ (Public)       │          │
│  │                │                │                │          │
│  │ • Training     │                │ • Landing page │          │
│  │ • Management   │                │ • Pricing      │          │
│  │ • LoRA         │                │ • Demo         │          │
│  │ • Models       │                │ • Contact      │          │
│  └────────┬───────┘                └────────┬───────┘          │
│           │                                  │                  │
│           └──────────┬───────────────────────┘                  │
│                      │                                          │
│                      ▼                                          │
│           ┌─────────────────────┐                              │
│           │  @rice-mono/ui-kit  │                              │
│           │  (Shared Library)   │                              │
│           │                     │                              │
│           │  • Components       │                              │
│           │  • Themes           │                              │
│           │  • Services         │                              │
│           │  • Hooks            │                              │
│           └─────────────────────┘                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📍 Port 3001 - GiPT-1 Admin Panel

**Purpose:** Internal tool for training, managing, and deploying AI models.

**Location:** `.frontend/web/`

**Key Features:**
- Dashboard with 6 AI gods status
- Model management (Ollama + Ra)
- GiPT-1 unified training interface
- Individual god LoRA training
- Component library showcase

**Target Users:** AI engineers, data scientists, DevOps

**Navigation:**
```
- Dashboard        (6 gods overview)
- Models           (Ollama + Ra management)
- GiPT-1 Training  (Multimodal fusion training)
- LoRA Training    (Individual god training)
- Components       (UI library showcase)
```

**Tech Stack:**
- Vite
- React 18
- TypeScript
- Tailwind CSS
- @rice-mono/ui-kit (local import)

---

## 📍 Port 3002 - Rice Marketing Website

**Purpose:** Public-facing site for customer acquisition and product showcase.

**Location:** `.frontend/web-marketing/`

**Key Features:**
- Modern landing page
- Pricing plans & packages
- Interactive demo
- About page
- Contact form

**Target Users:** Potential customers, partners, developers

**Navigation:**
```
- Home      (Landing page with hero)
- Pricing   (Subscription plans)
- About     (Company & technology)
- Demo      (Try GiPT-1 live)
- Contact   (Get in touch)
```

**Tech Stack:**
- Vite
- React 18
- React Router v6
- TypeScript
- Tailwind CSS
- @rice-mono/ui-kit (npm workspace)

---

## 📦 @rice-mono/ui-kit (Shared Library)

**Purpose:** Reusable component library for both sites + npm package.

**Location:** `.frontend/web/lib/`

**Exported Modules:**

### Components
- **Base**: Button1-10, Header1-5, Input, Textarea, Card
- **Layouts**: Header, Footer, Navigation, SideBar
- **Organisms**: ChatWidget, ContactForm, PricingCalculator
- **Widgets**: GodsPanel, LoRaTrainingPanel

### Services
- **Ollama**: API client for LLM models
- **Ra**: API client for Stable Diffusion
- **StableDiffusion**: External SD WebUI integration

### Hooks
- **useOllama**: Real-time Ollama status & models

### Contexts
- **ThemeContext**: Theme provider & switcher

### Utils
- **errorHandler**: Retry logic, error boundaries

### Themes
- 5 built-in themes (default, dark-purple, cyber-blue, forest-green, sunset-orange)

**Published to:** npm (public, MIT license)

---

## 🔄 Data Flow

### Shared Component Usage

```
Admin (3001)                    Marketing (3002)
    ↓                                ↓
    ├─ import Button1               ├─ import Button1
    ├─ import useOllama             ├─ import useOllama
    ├─ import ThemeProvider         ├─ import ThemeProvider
    └─ from '@rice-mono/ui-kit'     └─ from '@rice-mono/ui-kit'
             ↓                               ↓
        ┌────────────────────────────────────┐
        │   .frontend/web/lib/               │
        │   (Single source of truth)         │
        └────────────────────────────────────┘
```

### API Communication

```
Marketing (3002)
    ↓
Demo interaction → (mock for public)
    ↓
Link to Admin Panel (3001)
    ↓
Full GiPT-1 access → Ollama + Ra APIs
```

---

## 🚀 Development Workflow

### Option 1: Run both sites

From root:
```bash
yarn dev  # Starts 3001 + 3002 concurrently
```

### Option 2: Run separately

```bash
# Terminal 1 - Admin
cd .frontend/web
yarn dev  # Port 3001

# Terminal 2 - Marketing
cd .frontend/web-marketing
yarn dev  # Port 3002
```

### Option 3: Docker

```bash
# From root
docker-compose up ui-kit marketing-site

# Admin: http://localhost:3001
# Marketing: http://localhost:3002
```

---

## 📝 File Changes Summary

### Modified Files:

1. **`.frontend/web/app/Layout.tsx`**
   - Removed "Prices" link
   - Added "GiPT-1 Training" link

2. **`.frontend/web/app/App.tsx`**
   - Removed Prices import
   - Added GiPT1Training import
   - Updated Page type

3. **`.frontend/web/package.json`**
   - Added npm publish config
   - Added build:lib script
   - Updated repository URL

4. **`package.json` (root)**
   - Added web-marketing to workspaces
   - Updated dev scripts for dual-site

5. **`docker-compose.yml` (root)**
   - Added marketing-site service on port 3002

### Created Files:

**Admin Panel (3001):**
- `.frontend/web/app/GiPT1Training.tsx`
- `.frontend/web/tsconfig.lib.json`
- `.frontend/web/README_NPM.md`

**Marketing Site (3002):**
- `.frontend/web-marketing/` (entire project)
- `package.json`, `vite.config.ts`, `tsconfig.json`
- `index.tsx`, `index.html`, `index.css`
- `src/App.tsx`, `src/Layout.tsx`
- `src/pages/Home.tsx`
- `src/pages/Prices.tsx`
- `src/pages/About.tsx`
- `src/pages/Demo.tsx`
- `src/pages/Contact.tsx`
- `Dockerfile.dev`, `docker-compose.dev.yml`, `.dockerignore`
- `README.md`, `.gitignore`

**Documentation:**
- `.frontend/DUAL_SITE_ARCHITECTURE.md` (this file)

---

## 🎯 Key Decisions

### Why 2 separate sites?

| Aspect | Admin (3001) | Marketing (3002) |
|--------|--------------|------------------|
| **Audience** | Internal/technical | Public/customers |
| **Purpose** | Training & management | Sales & showcase |
| **Complexity** | High (full AI stack) | Low (presentation) |
| **Auth** | Required | Public |
| **Updates** | Frequent | Stable |

### Why shared library?

- **DRY principle**: Single source of truth
- **Consistency**: Same UI/UX across products
- **Maintainability**: Fix once, apply everywhere
- **npm publishable**: Open source contribution
- **Reusability**: Can be used in other projects

---

## 🔐 Security Notes

### Marketing Site (3002)

- **Public**: No authentication required
- **Read-only**: Demo uses mocks, not real API
- **Link to admin**: For authenticated users

### Admin Panel (3001)

- **Private**: Should add auth (future)
- **Full access**: Real API calls to Ollama/Ra
- **Docker network**: Can access backend services

---

## 📊 Performance

### Bundle Sizes (estimated)

| App | Size | Description |
|-----|------|-------------|
| **Admin (3001)** | ~800 KB | Full features, all components |
| **Marketing (3002)** | ~300 KB | Only needed components |
| **@rice-mono/ui-kit** | ~200 KB | Tree-shakeable library |

### Load Times

- Admin: ~2s (initial load with all models)
- Marketing: ~0.5s (optimized for public)

---

## 🧪 Testing

```bash
# Test both sites
yarn test

# Test specific workspace
yarn workspace @rice-mono/ui-kit test
yarn workspace @rice-mono/marketing test
```

---

## 🚢 Deployment

### Admin Panel (3001)

```bash
cd .frontend/web
yarn build
# Deploy dist/ to internal server
```

### Marketing Site (3002)

```bash
cd .frontend/web-marketing
yarn build
# Deploy dist/ to public CDN (Vercel, Netlify, etc.)
```

### Library (@rice-mono/ui-kit)

```bash
cd .frontend/web
yarn build:lib
npm publish  # Publishes to npmjs.org
```

---

## 📈 Future Roadmap

- [ ] Add authentication to admin panel
- [ ] Real GiPT-1 training backend
- [ ] Deploy marketing to Vercel
- [ ] Publish ui-kit to npm
- [ ] Add analytics to marketing
- [ ] SEO optimization
- [ ] Blog section
- [ ] Customer testimonials

---

## ✅ Status

```
✅ Admin Panel (3001)    - Ready
✅ Marketing Site (3002) - Ready
✅ Shared Library        - Ready for npm
✅ Docker Setup          - Ready
✅ Workspaces            - Configured
```

---

**Architecture designed for scalability and maintainability** 🚀

