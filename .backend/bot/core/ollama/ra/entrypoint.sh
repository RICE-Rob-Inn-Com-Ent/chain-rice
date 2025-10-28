#!/bin/bash
set -e

echo "🏛️ Starting Ra - God of Light..."
echo "================================"
echo ""
echo "☀️ Ra Graphics API starting..."
echo "   - Stable Diffusion 2.1"
echo "   - RealESRGAN upscaler"
echo "   - RVM background removal"
echo ""

python /app/server.py
