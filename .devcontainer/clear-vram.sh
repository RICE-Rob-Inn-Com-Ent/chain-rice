#!/bin/bash

# 🧹 Clear VRAM and restart gods properly
# For systems with limited VRAM (6GB)

echo "🏛️ Egyptian Gods - VRAM Cleanup Script"
echo "========================================"
echo ""

# Function to check GPU status
check_gpu() {
  echo "📊 Current GPU Status:"
  if command -v nvidia-smi &>/dev/null; then
    nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits
  else
    echo "⚠️  nvidia-smi not found. Install nvidia-utils."
  fi
  echo ""
}

# Function to kill processes using GPU
kill_gpu_processes() {
  echo "🔪 Killing GPU processes..."
  if command -v nvidia-smi &>/dev/null; then
    nvidia-smi --query-compute-apps=pid --format=csv,noheader | xargs -r kill -9 2>/dev/null
    echo "✅ GPU processes killed"
  fi
  echo ""
}

# Function to stop all god containers
stop_gods() {
  echo "🌙 Stopping all gods..."
  docker-compose stop thoth ra isis bastet maat khnum 2>/dev/null
  echo "✅ All gods stopped"
  echo ""
}

# Function to clear docker GPU cache
clear_docker_cache() {
  echo "🧹 Clearing Docker GPU cache..."
  docker system prune -f
  echo "✅ Docker cache cleared"
  echo ""
}

# Main execution
echo "Step 1: Checking initial GPU status"
check_gpu

echo "Step 2: Stopping all god containers"
stop_gods

echo "Step 3: Killing remaining GPU processes"
kill_gpu_processes

echo "Step 4: Clearing Docker cache"
clear_docker_cache

echo "Step 5: Checking final GPU status"
check_gpu

echo "✨ VRAM cleanup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Wait 5-10 seconds for GPU to fully release memory"
echo "   2. Start Thoth: docker-compose up -d thoth"
echo "   3. Check status: docker-compose logs -f thoth"
echo ""
echo "⚠️  With 6GB VRAM, run ONLY ONE god at a time!"
echo "⏱️  Quantized Mistral Q4_K_M will use ~4GB and load in ~30-45 seconds"
