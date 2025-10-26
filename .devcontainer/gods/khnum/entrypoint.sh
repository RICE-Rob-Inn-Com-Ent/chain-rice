#!/bin/bash
set -e
echo "🏛️ Starting Khnum - God of Wealth..."
OLLAMA_HOST=0.0.0.0:11434 ollama serve &
sleep 5
OLLAMA_HOST=0.0.0.0:11434 ollama pull ${OLLAMA_MODEL} || echo "Model already exists"
echo "💰 Financial Analysis Stack ready"
python /app/server.py
