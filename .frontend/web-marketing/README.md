# Rice Marketing Website

> Marketing and presentation website for GiPT-1 AI platform - Port 3002

## 🎯 Purpose

This is the **public-facing marketing site** for Rice AI and the GiPT-1 platform. It showcases features, pricing, and provides demo access for potential customers.

## 🚀 Quick Start

### Development (Local)

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web-marketing
yarn install
yarn dev
```

Open: **http://localhost:3002**

### Development (Docker)

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web-marketing
./docker-dev.sh
```

Or from root:

```bash
cd /home/mrDinkelman/rice-mono
docker-compose up marketing-site
```

### Development (Workspace)

From repository root:

```bash
cd /home/mrDinkelman/rice-mono
yarn dev:marketing
# or run both sites:
yarn dev  # Runs admin (3001) + marketing (3002)
```

---

## 📁 Structure

```
web-marketing/
├── src/
│   ├── pages/
│   │   ├── Home.tsx          # Landing page
│   │   ├── Prices.tsx        # Pricing plans
│   │   ├── About.tsx         # About GiPT-1
│   │   ├── Demo.tsx          # Interactive demo
│   │   └── Contact.tsx       # Contact form
│   ├── App.tsx               # Router setup
│   └── Layout.tsx            # Marketing layout
├── index.tsx                 # Entry point
├── index.html                # HTML template
├── vite.config.ts            # Vite config (port 3002)
├── tailwind.config.ts        # Tailwind setup
└── package.json
```

---

## 🎨 Design System

This site uses components from **`@rice-mono/ui-kit`** shared library:

```tsx
import { Button1, Header3, ThemeProvider } from '@rice-mono/ui-kit';

<ThemeProvider>
  <Header3 />
  <Button1>Click me</Button1>
</ThemeProvider>
```

### Shared with Port 3001 (Admin)

- All base components (buttons, headers, inputs)
- Theme system (5 built-in themes)
- Services (Ollama, Ra APIs)
- Hooks (useOllama)
- Utils (error handling)

**Single source of truth** - changes to lib/ affect both sites!

---

## 📄 Pages

### Home (`/`)
- Hero section with GiPT-1 showcase
- 6 gods feature grid
- Tech stack highlights
- CTA buttons

### Pricing (`/pricing`)
- 3 subscription tiers (Starter, Pro, Enterprise)
- Development services grid
- FAQ section
- Contact CTA

### About (`/about`)
- Mission statement
- Technology explanation (LoRA fusion, optimization)
- Team info (Code-Rice)
- Values (privacy, performance, open source)

### Demo (`/demo`)
- Interactive demo interface
- 4 modes: Text, Image, Vision, Code
- Live generation (mock for now)
- Link to full admin panel

### Contact (`/contact`)
- Contact form
- Direct contact methods (email, GitHub, Twitter)
- Quick links
- Response time info

---

## 🔗 Integration with Admin (Port 3001)

### Links to Admin Panel

- Header: "Admin Panel →" button
- Demo page: Link to full interface
- Footer: Quick link

### Shared Resources

- **lib/**: Imported from `../web/lib`
- **themes/**: Same theme system
- **API services**: Reused for demo functionality

---

## 🐳 Docker

### Development

```bash
docker-compose -f docker-compose.dev.yml up
```

- Hot reload enabled
- Port 3002 exposed
- Linked to ui-kit lib/

### Production

```bash
docker build -t rice-marketing:prod .
docker run -p 3002:3002 rice-marketing:prod
```

---

## 🌐 Ports

| Service | Port | Purpose |
|---------|------|---------|
| **Admin Panel** | 3001 | GiPT-1 training & management |
| **Marketing** | 3002 | Public website (this project) |
| **Ra API** | 8002 | Stable Diffusion backend |
| **Ollama** | 11434 | LLM models |

---

## 🛠️ Development

### Adding a new page

1. Create `src/pages/NewPage.tsx`
2. Add route in `src/App.tsx`:
   ```tsx
   <Route path="/new" element={<NewPage />} />
   ```
3. Add link in `src/Layout.tsx` navigation

### Using shared components

```tsx
// Import from ui-kit
import { Button1, useOllama } from '@rice-mono/ui-kit';

function MyComponent() {
  const { models } = useOllama();
  return <Button1>Loaded {models.length} models</Button1>;
}
```

### Theming

```tsx
import { useTheme } from '@rice-mono/ui-kit';
import { cyberBlue } from '@rice-mono/ui-kit/themes';

function ThemeSwitcher() {
  const { switchTheme } = useTheme();
  return <button onClick={() => switchTheme(cyberBlue)}>Cyber Blue</button>;
}
```

---

## 🧪 Testing

```bash
yarn test          # Run tests
yarn test:watch    # Watch mode
yarn typecheck     # Type checking
yarn lint          # Linting
```

---

## 📦 Build

### Development build

```bash
yarn build
```

Output: `dist/` directory

### Production optimization

- Minified assets
- Code splitting
- Tree shaking
- Asset optimization

---

## 🔒 Environment Variables

Create `.env.local`:

```env
VITE_API_URL=http://localhost:8000
VITE_OLLAMA_URL=http://localhost:11434
VITE_RA_URL=http://localhost:8002
```

---

## 📚 Documentation

- **UI Kit docs**: `../web/README_NPM.md`
- **Admin Panel**: `../web/README.md`
- **GiPT-1 Training**: `../web/LORA_TRAINING_GUIDE.md`
- **Ra Integration**: `../web/RA_INTEGRATION.md`

---

## 🐛 Troubleshooting

### Port 3002 already in use

```bash
# Find process
lsof -i :3002
# Kill it
kill -9 <PID>
```

### Can't import from ui-kit

Make sure lib/ is linked:

```bash
# From root
yarn install
# Workspaces should auto-link
```

### Hot reload not working

```bash
# Set polling env var
export CHOKIDAR_USEPOLLING=true
yarn dev
```

---

## 🎉 Done!

Marketing site is running on **http://localhost:3002**

- Beautiful landing page
- Pricing plans
- Interactive demo
- Contact form
- Shares components with admin panel (3001)

---

**Built with ❤️ by Code-Rice** • Powered by GiPT-1 • Port 3002

