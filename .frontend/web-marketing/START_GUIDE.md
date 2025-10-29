# Marketing Site - Start Guide

## ⚡ Fastest Start

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web-marketing
yarn dev
```

Open: **http://localhost:3002**

---

## 📋 What You'll See

### Home Page (`/`)

- Hero section: "One Model, Six Superpowers"
- 6 gods showcase
- Tech stack
- CTA buttons

### Pricing (`/pricing`)

- 3 plans: Starter ($49), Pro ($199), Enterprise (custom)
- Development services
- FAQ
- Contact CTA

### About (`/about`)

- Mission
- Technology explanation
- Team (Code-Rice)
- Values

### Demo (`/demo`)

- 4 modes: Text, Image, Vision, Code
- Interactive interface
- Mock generation
- Link to admin

### Contact (`/contact`)

- Contact form
- Direct contact info
- Quick links
- Office hours

---

## 🎨 Using Shared Components

Import from ui-kit:

```tsx
import { Button1, Header3, ThemeProvider } from "@rice-mono/ui-kit";

// In your page
<ThemeProvider>
  <Header3 />
  <Button1>Action</Button1>
</ThemeProvider>;
```

**Note:** Components are imported via Vite alias from `../web/lib/`

---

## 🔧 Configuration

### Change port

Edit `vite.config.ts`:

```ts
server: {
  port: 3002,  // Change this
}
```

### Add new page

1. Create `src/pages/NewPage.tsx`
2. Add route in `src/App.tsx`:
   ```tsx
   <Route path="/new" element={<NewPage />} />
   ```
3. Add nav link in `src/Layout.tsx`

---

## 🐳 Docker

```bash
./docker-dev.sh
```

Or:

```bash
docker-compose -f docker-compose.dev.yml up --build
```

Logs:

```bash
docker logs -f rice-marketing
```

Stop:

```bash
docker-compose -f docker-compose.dev.yml down
```

---

## ✅ Checklist

- [ ] Port 3002 is free
- [ ] ui-kit lib/ exists at `../web/lib/`
- [ ] Dependencies installed (`yarn install`)
- [ ] Vite running (`yarn dev`)
- [ ] Can access http://localhost:3002
- [ ] All 5 pages load (Home, Pricing, About, Demo, Contact)

---

## 🎉 You're ready!

Marketing site is live on port 3002. Customers can now:

- Learn about GiPT-1
- See pricing
- Try the demo
- Contact your team

Admin panel (port 3001) handles the actual training and management.

---

**Built with @rice-mono/ui-kit** • Port 3002 • Public site
