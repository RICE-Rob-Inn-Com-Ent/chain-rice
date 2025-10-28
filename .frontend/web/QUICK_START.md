# Quick Start Guide

## Start the Dashboard in 3 Steps

### 1. Make sure Ollama is running

```bash
ollama serve
```

Keep this running in a separate terminal.

### 2. Start the Vite dev server

```bash
cd /home/mrDinkelman/rice-mono/.frontend/web
yarn dev
```

### 3. Open your browser

Navigate to: **http://localhost:3001**

That's it! 🎉

## What You'll See

### Dashboard (🏠)

- 6 Egyptian AI god cards
- Real-time Ollama connection status
- Model status indicators
- Download progress bars

### Navigation Sidebar

- 🏠 **Dashboard** - Main view with god cards
- 🤖 **Models** - Detailed Ollama model list
- 🧬 **LoRA Training** - Create custom model stacks
- 💰 **Prices** - Service pricing information
- 🎨 **Components** - UI component library

## Test Ollama Integration

### Check if Ollama is connected

1. Look for the green "Ollama: Connected" indicator at the top
2. If red "Disconnected", make sure Ollama is running

### Pull a model to test download progress

```bash
# In a separate terminal
ollama pull mistral:7b-instruct
```

You'll see real-time progress bars in the dashboard!

### Check running models

```bash
ollama ps
```

Models currently loaded on GPU will show as "ACTIVE" in the dashboard.

## Try the Features

### Switch Themes

1. Go to **Components** page (🎨)
2. Click any theme in the Theme Selector
3. Watch all components update instantly

### View Model Details

1. Go to **Models** page (🤖)
2. See all installed models with details
3. Check which models are running on GPU

### Build a LoRA Model (UI Only)

1. Go to **LoRA Training** page (🧬)
2. Select base models to combine
3. Configure training parameters
4. Create demo conversations
5. Export as JSON or start training (simulated)

### Browse Components

1. Go to **Components** page (🎨)
2. Preview 5 headers and 10 buttons
3. Click "Copy Code" to use in your project
4. Switch themes to see how components adapt

## Troubleshooting

### "Ollama: Disconnected"

```bash
# Start Ollama
ollama serve
```

### "No Models Installed"

```bash
# Install a model
ollama pull mistral:7b-instruct
```

### Port 3001 already in use

Edit `vite.config.ts` and change the port, or kill the process using port 3001:

```bash
lsof -ti:3001 | xargs kill -9
```

## Next Steps

- Read the full [DASHBOARD_GUIDE.md](./DASHBOARD_GUIDE.md)
- Check [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) for technical details
- Explore [app/README.md](./app/README.md) for architecture

## Key Commands

```bash
# Development
yarn dev              # Start dev server on port 3001
yarn dev:debug        # Start with debug mode

# Build
yarn build            # Production build
yarn preview          # Preview production build

# Code Quality
yarn lint             # Run ESLint
yarn typecheck        # TypeScript check
yarn format           # Format with Prettier
```

## Environment

- **Frontend Port:** 3001
- **Ollama Port:** 11434
- **Proxy:** `/api/ollama` → `http://localhost:11434`

## Features at a Glance

✅ Real-time Ollama integration  
✅ 6 Egyptian AI gods (model stacks)  
✅ GPU management (one active at a time)  
✅ Download progress tracking  
✅ 5 theme variants  
✅ 15 UI component variants  
✅ LoRA training interface  
✅ Sidebar navigation  
✅ Error boundaries  
✅ Responsive design

Enjoy your Egyptian AI Dashboard! 🏺✨
