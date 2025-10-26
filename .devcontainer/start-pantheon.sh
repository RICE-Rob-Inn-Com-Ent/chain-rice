#!/bin/bash
# Start Egyptian Gods AI Pantheon

set -e

echo "🏛️  Starting Egyptian Gods AI Pantheon..."
echo "========================================"

# Check if SSD path is configured
if [ -z "$SSD_PATH" ]; then
  echo "⚠️  SSD_PATH not set, using default /mnt/ssd"
  export SSD_PATH="/mnt/ssd"
fi

# Create necessary directories
echo "📁 Creating cache directories..."
mkdir -p "$SSD_PATH/ollama/thoth"
mkdir -p "$SSD_PATH/ollama/ra"
mkdir -p "$SSD_PATH/ollama/anubis"
mkdir -p "$SSD_PATH/ollama/isis"
mkdir -p "$SSD_PATH/ollama/horus"
mkdir -p "$SSD_PATH/cache/bazel"
mkdir -p "$SSD_PATH/cache/models"

# Set permissions
echo "🔐 Setting permissions..."
chmod -R 755 "$SSD_PATH"

# Check for GPU and VRAM
if command -v nvidia-smi &>/dev/null; then
  echo "🎮 NVIDIA GPU detected:"
  GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader)
  echo "$GPU_INFO"

  # Extract VRAM in MB
  VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
  VRAM_GB=$((VRAM_MB / 1024))

  echo ""
  echo "📊 Total VRAM: ${VRAM_GB}GB"

  # Warning for low VRAM
  if [ "$VRAM_GB" -le 6 ]; then
    echo ""
    echo "⚠️  ⚠️  ⚠️  LOW VRAM DETECTED ⚠️  ⚠️  ⚠️"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "You have only ${VRAM_GB}GB VRAM. IMPORTANT:"
    echo ""
    echo "1. 📖 READ: .devcontainer/VRAM_6GB_GUIDE.md"
    echo "2. ✅ Use QUANTIZED models only (Q4_K_M)"
    echo "3. ⚠️  Run ONLY ONE god at a time!"
    echo "4. 🧹 Clear VRAM before starting: ./clear-vram.sh"
    echo "5. ⏱️  Load time: 30-45 seconds (warm), 3-6 min (cold)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Ask user if they want to continue
    read -p "Continue with Thoth (Mistral Q4 - 4.5GB VRAM)? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "❌ Startup cancelled. Run ./clear-vram.sh first!"
      exit 1
    fi
  fi
else
  echo "⚠️  No NVIDIA GPU detected. Running in CPU mode (SLOW)."
fi

# Start only Thoth by default (lazy loading for others)
echo ""
echo "📜 Starting Thoth (Mistral) - God of Knowledge..."
docker-compose up -d thoth cache-manager

echo ""
echo "✅ Pantheon is ready!"
echo ""
echo "🌐 Services:"
echo "  - Thoth (Mistral):     http://localhost:11434"
echo "  - Cache Manager:       http://localhost:9090"
echo "  - Web Interface:       http://localhost:3000"
echo ""
echo "🔮 To wake other gods:"
if [ "$VRAM_GB" -le 6 ]; then
  echo "  ⚠️  Stop Thoth first: docker-compose stop thoth"
  echo "  docker-compose up -d ra        # Wake Ra (Graphics - 5GB)"
  echo "  docker-compose up -d isis      # Wake Isis (Medical - 5GB)"
  echo "  docker-compose up -d bastet    # Wake Bastet (Vision - 4.5GB)"
  echo "  docker-compose up -d maat      # Wake Maat (Legal - 4GB)"
  echo "  docker-compose up -d khnum     # Wake Khnum (Finance - 4GB)"
  echo ""
  echo "  ⚠️  REMEMBER: Only ONE god at a time with 6GB VRAM!"
else
  echo "  docker-compose up -d ra        # Wake Ra (Graphics)"
  echo "  docker-compose up -d isis      # Wake Isis (Medical)"
  echo "  docker-compose up -d bastet    # Wake Bastet (Vision)"
  echo "  docker-compose up -d maat      # Wake Maat (Legal)"
  echo "  docker-compose up -d khnum     # Wake Khnum (Finance)"
fi
echo ""
echo "📊 Monitor:"
echo "  docker-compose logs -f thoth"
echo "  docker-compose ps"
echo ""
echo "🛑 Stop all:"
echo "  docker-compose down"
echo ""
echo "𓂀 May the gods guide you! 𓁹"
