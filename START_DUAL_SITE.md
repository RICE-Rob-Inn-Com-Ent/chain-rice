# 🚀 Start Dual Site - Quick Commands

## ⚡ Fastest Start

```bash
cd /home/mrDinkelman/rice-mono
yarn dev
```

This starts **both** sites:

- **Admin Panel**: http://localhost:3001
- **Marketing Site**: http://localhost:3002

---

## 📍 Individual Sites

### Admin Only (3001)

```bash
yarn dev:admin
# or
cd .frontend/web && yarn dev
```

### Marketing Only (3002)

```bash
yarn dev:marketing
# or
cd .frontend/web-marketing && yarn dev
```

---

## 🐳 Docker

### Both sites

```bash
docker-compose up ui-kit marketing-site
```

### Individual

```bash
# Admin
cd .frontend/web && ./docker-dev.sh

# Marketing
cd .frontend/web-marketing && ./docker-dev.sh
```

---

## 📦 Build

```bash
# Build all
yarn build

# Build admin only
cd .frontend/web && yarn build

# Build marketing only
cd .frontend/web-marketing && yarn build

# Build ui-kit for npm
cd .frontend/web && yarn build:lib
```

---

## 🔧 Other Commands

```bash
# Install dependencies
yarn install

# Type check
yarn typecheck

# Lint
yarn lint

# Clean
yarn clean
```

---

## 📖 Documentation

- Architecture: `.frontend/DUAL_SITE_ARCHITECTURE.md`
- Quick Start: `.frontend/QUICK_START_DUAL_SITE.md`
- Implementation: `.frontend/IMPLEMENTATION_COMPLETE.md`
- Marketing README: `.frontend/web-marketing/README.md`
- npm Package: `.frontend/web/README_NPM.md`

---

## ✅ Verify Installation

```bash
# Check if both sites compile
yarn typecheck

# Check if no linter errors
yarn lint

# Try to start
yarn dev
```

Then open:

- http://localhost:3001 - Should see Dashboard
- http://localhost:3002 - Should see Landing Page

---

## 🎯 What to Do Next

1. **Admin (3001)**: Click "GiPT-1 Training" to see new training interface
2. **Marketing (3002)**: Explore all 5 pages (Home, Pricing, About, Demo, Contact)
3. **Test shared components**: Both sites use same buttons/headers from lib/
4. **Customize**: Edit pages in `src/pages/`
5. **Deploy**: Build and deploy marketing to Vercel

---

🎉 **Ready to build GiPT-1!**
