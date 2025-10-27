#!/bin/bash
set -e

echo "🏛️ Starting Thoth - God of Knowledge..."
echo "========================================"
echo ""

# Start Ollama in background
echo "📜 Starting Ollama server..."
OLLAMA_HOST=0.0.0.0:11434 ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama..."
for i in {1..30}; do
  if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "✅ Ollama is ready!"
    break
  fi
  sleep 1
done

# Pull Mistral model (if not exists)
echo "📥 Pulling Mistral 7B Q4_K_M (if needed)..."
OLLAMA_HOST=0.0.0.0:11434 ollama pull ${OLLAMA_MODEL:-mistral:7b-instruct-q4_K_M} || echo "⚠️  Model pull failed or already exists"

echo ""
echo "✅ Thoth is ready!"
echo "   - Ollama API: http://localhost:11434"
echo "   - Thoth API: http://localhost:8000"
echo "   - Model: ${OLLAMA_MODEL}"
echo ""

# Start Python API server
echo "🚀 Starting Thoth API server..."
python /app/server.py
