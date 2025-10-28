# App Structure

This directory contains the main application pages and routing logic for the Egyptian AI Dashboard.

## Pages

- **Dashboard.tsx** - Main dashboard showing all 6 AI god models with Ollama integration
- **Models.tsx** - Detailed view of all installed Ollama models with management features
- **LoRaTraining.tsx** - LoRA training interface for creating custom model stacks (GiPT-1)
- **Prices.tsx** - Pricing information and service packages
- **ComponentLibrary.tsx** - UI component showcase with code examples and theme switcher

## Layout

- **Layout.tsx** - Main layout component with sidebar navigation
- **App.tsx** - Root application component with routing and theme provider

## Features

### Ollama Integration

- Real-time model status monitoring
- Download progress tracking
- GPU memory management (6-8GB VRAM limit)
- Wake/sleep functionality for models

### LoRA Training

- Stack multiple models together
- CPU/GPU training modes
- Demo conversation builder
- Training progress visualization
- Container deployment

### Theme System

- 5 built-in themes (default, dark-purple, cyber-blue, forest-green, sunset-orange)
- Live theme switching
- CSS variable-based theming
- Persistent theme selection

### Component Library

- 5 header variants
- 10 button variants
- Copy-to-clipboard code examples
- Live theme preview

## Navigation

The app uses a simple state-based routing system:

- Dashboard (🏠)
- Models (🤖)
- LoRA Training (🧬)
- Prices (💰)
- Components (🎨)

## Running the App

```bash
# Development server on port 3001
yarn dev

# Build for production
yarn build

# Preview production build
yarn preview
```

## Ollama Connection

The app connects to Ollama on `localhost:11434` via Vite proxy:

- Endpoint: `/api/ollama` (proxied to `http://localhost:11434`)
- Functions: Model listing, status checking, pull/load operations

## GPU Management

Only ONE god model can be active at a time:

- **ACTIVE** = Loaded on GPU, ready for inference
- **IDLE** = Not loaded, available to wake
- **LOADING** = Currently loading to GPU
- **DOWNLOADING** = Downloading from Ollama registry
- **ERROR** = Not installed or failed to load

Waking a new model automatically sleeps the currently active one to free VRAM.
