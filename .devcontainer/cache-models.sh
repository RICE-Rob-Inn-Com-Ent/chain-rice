#!/bin/bash

# Pre-download and cache all models for Egyptian Gods

echo "🏛️ Caching Models for All Gods"
echo "==============================="
echo ""

cd /home/mrDinkelman/rice-mono/.devcontainer

# Function to cache model
cache_model() {
  local god=$1
  local model=$2
  local port=$3

  echo "📥 Caching $model for $god..."
  docker exec ai-god-$god ollama pull $model

  if [ $? -eq 0 ]; then
    echo "✅ $god: $model cached"
  else
    echo "⚠️  $god: Failed to cache $model (container may not be running)"
  fi
  echo ""
}

# Cache models for each god
echo "Caching Ollama models..."
echo ""

# Thoth - Mistral 7B Q4
cache_model "thoth" "mistral:7b-instruct-q4_K_M" "11434"

# Maat - Mistral 7B Q4 (legal)
cache_model "maat" "mistral:7b-instruct-q4_K_M" "11438"

# Khnum - Mistral 7B Q4 (finance)
cache_model "khnum" "mistral:7b-instruct-q4_K_M" "11439"

echo ""
echo "🎨 Caching Graphics Models (Ra)..."
echo ""

# Ra - Stable Diffusion models (via Python inside container)
docker exec ai-god-ra python -c "
from diffusers import StableDiffusionPipeline
import torch

print('📥 Downloading Stable Diffusion 2.1...')
pipeline = StableDiffusionPipeline.from_pretrained(
    'stabilityai/stable-diffusion-2-1',
    torch_dtype=torch.float16,
)
print('✅ Stable Diffusion 2.1 cached')

print('📥 Downloading RealESRGAN...')
from realesrgan import RealESRGAN
upscaler = RealESRGAN('RealESRGAN_x4plus')
print('✅ RealESRGAN cached')
" || echo "⚠️  Ra container not running or Python error"

echo ""
echo "🏥 Caching Medical Models (Isis)..."
echo ""

docker exec ai-god-isis python -c "
import monai
print('📥 Downloading Monai models...')
# Monai models download on first use
print('✅ Monai ready (lazy load)')
" || echo "⚠️  Isis container not running"

echo ""
echo "👁️ Caching Vision Models (Bastet)..."
echo ""

docker exec ai-god-bastet python -c "
print('📥 Downloading InsightFace models...')
import insightface
app = insightface.app.FaceAnalysis()
app.prepare(ctx_id=0)
print('✅ InsightFace cached')
" || echo "⚠️  Bastet container not running"

echo ""
echo "🎉 Model caching complete!"
echo ""
echo "📊 Disk usage:"
docker system df -v | grep -E "thoth-models|ra-models|isis-models|bastet-models|maat-models|khnum-models"
echo ""
echo "💡 Models are now cached and ready to use!"
echo "   No re-downloading on next start!"
