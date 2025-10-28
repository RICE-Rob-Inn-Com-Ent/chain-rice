# Egyptian AI Dashboard - User Guide

## Overview

The Egyptian AI Dashboard is a comprehensive management interface for your AI model stack. It runs on Vite (port 3001)
and provides:

- Real-time model monitoring via Ollama
- GPU memory management
- LoRA training for custom models
- Component library with theme switching

## Getting Started

### Prerequisites

1. **Ollama** must be running on `localhost:11434`

```bash
# Install Ollama (if not already installed)
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama
ollama serve
```

2. **Node.js** 18+ and Yarn installed

### Installation

```bash
cd .frontend/web
yarn install
yarn dev
```

The dashboard will open at `http://localhost:3001`

## Features

### 1. Dashboard Page (🏠)

The main dashboard displays 6 Egyptian AI gods, each representing a stack of AI models:

- **Thoth** (📚) - NLP Stack: Mistral 7B, PaddleOCR, Opus-MT
- **Ra** (☀️) - Image Generation: Stable Diffusion 2.1, RealESRGAN
- **Isis** (✨) - Medical & Audio: MONAI, XTTS, MusicGen
- **Bastet** (🐱) - Computer Vision: InsightFace, LLaVa 7B
- **Maat** (⚖️) - Legal & Analytics: Mistral 7B, XLM-RoBERTa
- **Khnum** (🏺) - 3D & Game AI: CodeLlama 7B, Tripo SR

Each god card shows:

- Current status (ACTIVE / IDLE / LOADING / DOWNLOADING / ERROR)
- Download progress (if applicable)
- Features and tech stack
- Wake/Demo buttons

**GPU Management:**

- Only ONE god can be ACTIVE at a time (6-8GB VRAM limit)
- Waking a god automatically sleeps the active one
- VRAM clearing delay: 3-5 seconds

### 2. Models Page (🤖)

Detailed view of all Ollama models:

- Model name, size, format, quantization
- Running status (active on GPU or idle)
- Download progress bars
- Actions: Load to GPU, Delete model
- Quick actions: Pull new model, Refresh list

### 3. LoRA Training Page (🧬)

Create custom model stacks (GiPT-1):

**Step 1: Select Base Models**

- Choose which gods to combine
- Example: Mistral 7B + LLaVa 7B = GiPT-1

**Step 2: Configure Training**

- Container name (default: `gipt-1`)
- Training mode: CPU (slow, doesn't block GPU) or GPU (fast, requires free VRAM)
- Parameters: Epochs, Learning Rate, LoRA Rank

**Step 3: Upload Dataset**

- JSON or CSV format
- Minimum 1000 examples recommended

**Step 4: Demo Conversations**

- Build sample conversations
- Define how your model should respond
- Export as JSON training data

**Step 5: Train & Deploy**

- Monitor training progress
- View loss/accuracy metrics
- Deploy to GPU when complete

### 4. Prices Page (💰)

View service offerings:

- AI Model Subscriptions (Cloud/Self-Hosted)
- Development Services (Full-Stack, AI/ML, DevOps)
- Integration & Support
- Package deals (Startup MVP, Enterprise, Custom)

### 5. Component Library (🎨)

Browse and copy UI components:

**Theme Switcher:**

- Default Dark
- Dark Purple
- Cyber Blue
- Forest Green
- Sunset Orange

**Components:**

- 5 Header variants (Centered, Left-aligned, Transparent, Sticky, Mega menu)
- 10 Button variants (Solid, Outline, Ghost, Gradient, Icons, Loading, Success, Error, Pill)

**Features:**

- Live preview with current theme
- Copy-to-clipboard code snippets
- Usage instructions

## Architecture

```
.frontend/web/
├── app/                 # Main application pages
│   ├── App.tsx         # Root component with routing
│   ├── Layout.tsx      # Sidebar layout
│   ├── Dashboard.tsx   # God models overview
│   ├── Models.tsx      # Ollama model management
│   ├── LoRaTraining.tsx # Training interface
│   ├── Prices.tsx      # Pricing information
│   └── ComponentLibrary.tsx # UI showcase
├── lib/                # Reusable components
│   ├── base/          # Headers, buttons, UI primitives
│   ├── contexts/      # Theme context
│   ├── hooks/         # useOllama hook
│   ├── services/      # Ollama API integration
│   ├── utils/         # Error handling
│   └── components/    # ErrorBoundary
├── themes/            # Theme configurations
│   ├── types.ts
│   ├── default.ts
│   ├── dark-purple.ts
│   ├── cyber-blue.ts
│   ├── forest-green.ts
│   └── sunset-orange.ts
└── index.tsx          # Entry point
```

## Ollama API Integration

The dashboard communicates with Ollama via:

**Endpoints:**

- `GET /api/tags` - List installed models
- `POST /api/pull` - Download model (with streaming progress)
- `POST /api/generate` - Load model to GPU
- `GET /api/ps` - List running models
- `POST /api/show` - Get model details

**Proxy Configuration:**

- Vite proxy: `/api/ollama` → `http://localhost:11434`
- Configuredtheme in `vite.config.ts`

## Troubleshooting

### Ollama Not Connected

**Symptoms:** Red "Disconnected" status, no models shown

**Solutions:**

1. Check if Ollama is running: `ps aux | grep ollama`
2. Start Ollama: `ollama serve`
3. Verify port 11434 is open: `curl http://localhost:11434/api/tags`

### Models Not Loading

**Symptoms:** Model stays in "LOADING" state

**Solutions:**

1. Check VRAM usage: `nvidia-smi`
2. Ensure only one god is active
3. Manually unload models: `ollama ps` then wait for timeout
4. Restart Ollama service

### Download Stuck

**Symptoms:** Download progress at 0%

**Solutions:**

1. Check internet connection
2. Check Ollama logs: `journalctl -u ollama -f`
3. Retry download: Refresh page and try again

### CORS Errors

**Symptoms:** Console shows CORS policy errors

**Solutions:**

1. Ensure Vite dev server is running on port 3001
2. Check proxy configuration in `vite.config.ts`
3. Restart dev server: `yarn dev`

## Tips & Best Practices

1. **Model Management:**
   - Keep only necessary models installed to save disk space
   - Use quantized models (Q4, Q5) for better performance
   - Pre-download models before presentations/demos

2. **LoRA Training:**
   - Start with CPU mode to avoid blocking GPU
   - Use small datasets (1000-5000 examples) for testing
   - Monitor training metrics to avoid overfitting

3. **Theme Customization:**
   - Create new themes in `themes/` directory
   - Use CSS variables for consistent theming
   - Test components in all themes before deployment

4. **Performance:**
   - Only one god active at a time
   - Close unused browser tabs to free memory
   - Monitor system resources during training

## Support

For issues or feature requests:

- Email: support@code-rice.com
- Documentation: `/app/README.md`
- Component Docs: Visit Component Library page
