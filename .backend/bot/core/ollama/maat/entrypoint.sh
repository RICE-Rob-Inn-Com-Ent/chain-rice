#!/bin/bash
set -e
echo "🏛️ Starting Maat - Goddess of Justice..."
OLLAMA_HOST=0.0.0.0:11434 ollama serve &
sleep 5
OLLAMA_HOST=0.0.0.0:11434 ollama pull ${OLLAMA_MODEL} || echo "Model already exists"
echo "⚖️ Legal Analysis Stack ready"
python /app/server.py
