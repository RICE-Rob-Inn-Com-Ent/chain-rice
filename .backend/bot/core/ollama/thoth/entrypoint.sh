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

# Start model loading in background (non-blocking)
(
  echo "📥 Loading Mistral 7B Q4_K_M to GPU..."
  echo "   This will take ~30 seconds on first run"

  # Pull model if needed
  OLLAMA_HOST=0.0.0.0:11434 ollama pull ${OLLAMA_MODEL:-mistral:7b-instruct-q4_K_M} 2>&1 | while read line; do
    echo "   $line"
  done

  # Warm up model (load to GPU)
  echo "🔥 Warming up model on GPU..."
  curl -s -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"${OLLAMA_MODEL:-mistral:7b-instruct-q4_K_M}\", \"prompt\": \"Hello\", \"stream\": false}" \
    > /dev/null 2>&1

  echo "✅ Model loaded to GPU and ready!"
) &

echo ""
echo "🚀 Thoth API server starting..."
echo "   - Ollama API: http://localhost:11434"
echo "   - Thoth API: http://localhost:8000"
echo "   - Model: ${OLLAMA_MODEL}"
echo "   - Status: Loading model to GPU in background..."
echo ""

# Start Python API server (this will be available immediately)
python /app/server.py
