#!/bin/bash
# Ollama Setup Script

set -e

echo "🚀 Ollama Setup Script"
echo "======================"

# Check if Ollama is installed
if ! command -v ollama &>/dev/null; then
  echo "📦 Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "✅ Ollama is already installed"
fi

# Start Ollama service
echo ""
echo "🔄 Starting Ollama service..."
ollama serve &
OLLAMA_PID=$!
sleep 3

# Pull recommended models
echo ""
echo "📥 Pulling recommended models..."
echo ""

models=(
  "llama3.3:latest"
  "mistral:latest"
  "phi4:latest"
  "deepseek-coder:6.7b"
  "gemma2:2b"
)

for model in "${models[@]}"; do
  echo "Pulling $model..."
  ollama pull "$model" || echo "⚠️  Failed to pull $model"
done

echo ""
echo "✅ Setup complete!"
echo ""
echo "Available models:"
ollama list

echo ""
echo "🎯 Quick start commands:"
echo "  ollama run llama3.3          # Chat with Llama 3.3"
echo "  ollama run mistral           # Chat with Mistral"
echo "  ollama run deepseek-coder    # Code generation"
echo ""
echo "  python examples/chat.py      # Interactive chat"
echo "  python examples/rag_example.py  # RAG demo"
echo "  python examples/code_generator.py  # Code generation"

echo ""
echo "📚 Model sizes:"
ollama list | awk '{print $1, $2}'

echo ""
echo "🌐 Ollama API: http://localhost:11434"
echo "🖥️  Web UI: docker-compose up -d (then visit http://localhost:3000)"
