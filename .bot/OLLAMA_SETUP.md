# 🦙 Ollama Installation & Model Setup

## 1. Install Ollama

```bash
# Download and install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Verify installation
ollama --version
```

## 2. Start Ollama Service

```bash
# Start Ollama server (runs in background)
ollama serve &

# Or use systemd (recommended for auto-start)
sudo systemctl enable ollama
sudo systemctl start ollama
```

## 3. Pull Recommended Models for RTX 3060 Mobile (6GB VRAM)

### Text Generation

```bash
# Mistral 7B (4-bit) - Best all-around model [~3.5GB]
ollama pull mistral:7b-instruct-q4_0

# Phi-3 Mini - Fast, lightweight model [~2GB]
ollama pull phi3:mini-q4_0

# Alternative: Gemma 7B
ollama pull gemma:7b-instruct-q4_0
```

### Code Generation

```bash
# CodeLlama 7B (4-bit) - Code-specific model [~3.5GB]
ollama pull codellama:7b-instruct-q4_0

# Alternative: DeepSeek Coder
ollama pull deepseek-coder:6.7b-instruct-q4_0
```

### Multimodal (Vision + Text)

```bash
# LLaVa 7B (4-bit) - Image understanding [~4GB]
ollama pull llava:7b-q4_0

# Alternative: LLaVa 1.6
ollama pull llava:7b-v1.6-mistral-q4_0
```

### Specialized Models

```bash
# Mistral for Polish language
ollama pull mistral:7b-instruct-q4_0

# Llama 3 (if you have space)
ollama pull llama3:8b-instruct-q4_0
```

## 4. Test Models

### Basic Chat

```bash
ollama run mistral:7b-instruct-q4_0
# Type your question and press Enter
# Type /bye to exit
```

### Code Generation

```bash
ollama run codellama:7b-instruct-q4_0 "Write a Python function to calculate fibonacci numbers"
```

### Vision (LLaVa)

```bash
# Analyze an image
ollama run llava:7b-q4_0 "What's in this image?" /path/to/image.jpg
```

## 5. Python Integration

### Basic Example

```python
import ollama

# Simple chat
response = ollama.chat(
    model='mistral:7b-instruct-q4_0',
    messages=[
        {'role': 'user', 'content': 'Explain machine learning in simple terms'}
    ]
)
print(response['message']['content'])
```

### Streaming Response

```python
import ollama

stream = ollama.chat(
    model='mistral:7b-instruct-q4_0',
    messages=[{'role': 'user', 'content': 'Write a poem about AI'}],
    stream=True
)

for chunk in stream:
    print(chunk['message']['content'], end='', flush=True)
```

### Code Generation

```python
import ollama

response = ollama.chat(
    model='codellama:7b-instruct-q4_0',
    messages=[{
        'role': 'user',
        'content': 'Write a Python class for a binary search tree'
    }]
)
print(response['message']['content'])
```

### Vision (LLaVa)

```python
import ollama

response = ollama.chat(
    model='llava:7b-q4_0',
    messages=[{
        'role': 'user',
        'content': 'Describe what you see in this image',
        'images': ['path/to/image.jpg']
    }]
)
print(response['message']['content'])
```

### LangChain Integration

```python
from langchain_community.llms import Ollama
from langchain_core.prompts import ChatPromptTemplate

llm = Ollama(model="mistral:7b-instruct-q4_0")

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful AI assistant."),
    ("user", "{input}")
])

chain = prompt | llm
response = chain.invoke({"input": "What is quantum computing?"})
print(response)
```

## 6. Model Management

### List installed models

```bash
ollama list
```

### Remove a model

```bash
ollama rm mistral:7b-instruct-q4_0
```

### Update a model

```bash
ollama pull mistral:7b-instruct-q4_0
```

### Copy/rename a model

```bash
ollama cp mistral:7b-instruct-q4_0 my-custom-mistral
```

## 7. Performance Optimization

### Set GPU Layers

```bash
# Use specific number of GPU layers (for hybrid CPU/GPU)
OLLAMA_GPU_LAYERS=35 ollama run mistral:7b-instruct-q4_0
```

### Set Context Size

```bash
# Increase context window (uses more VRAM)
OLLAMA_NUM_CTX=4096 ollama run mistral:7b-instruct-q4_0
```

### Set Thread Count

```bash
# Optimize CPU threads
OLLAMA_NUM_THREAD=6 ollama run mistral:7b-instruct-q4_0
```

### Python Configuration

```python
import ollama

response = ollama.chat(
    model='mistral:7b-instruct-q4_0',
    messages=[{'role': 'user', 'content': 'Hello'}],
    options={
        'num_ctx': 4096,        # Context window
        'temperature': 0.7,     # Creativity (0-1)
        'top_k': 40,           # Top-k sampling
        'top_p': 0.9,          # Top-p sampling
        'num_gpu': 35,         # GPU layers
    }
)
```

## 8. Recommended Model Combinations for 6GB VRAM

### Setup 1: General Purpose (5GB total)

- `mistral:7b-instruct-q4_0` (3.5GB) - Main chat
- `phi3:mini-q4_0` (2GB) - Fast responses

### Setup 2: Development Focus (6GB total)

- `codellama:7b-instruct-q4_0` (3.5GB) - Code gen
- `mistral:7b-instruct-q4_0` (3.5GB) - Documentation (Use one at a time)

### Setup 3: Multimodal (5.5GB total)

- `llava:7b-q4_0` (4GB) - Vision + text
- `phi3:mini-q4_0` (2GB) - Quick text tasks

## 9. Troubleshooting

### Model won't load (OOM)

```bash
# Try smaller quantization
ollama pull mistral:7b-instruct-q3_K_M  # Even smaller

# Or run on CPU
OLLAMA_GPU=0 ollama run mistral:7b-instruct-q4_0
```

### Slow inference

```bash
# Check GPU usage
nvidia-smi

# Increase GPU layers if VRAM available
OLLAMA_GPU_LAYERS=40 ollama run mistral:7b-instruct-q4_0
```

### Port already in use

```bash
# Kill existing Ollama process
killall ollama

# Start on different port
OLLAMA_HOST=0.0.0.0:11435 ollama serve
```

## 10. Advanced: Custom Models

### Create Modelfile

```bash
cat > Modelfile <<EOF
FROM mistral:7b-instruct-q4_0

# Set custom parameters
PARAMETER temperature 0.8
PARAMETER top_p 0.9

# Set system message
SYSTEM """
You are a helpful coding assistant specialized in Python.
Always provide clean, well-commented code.
"""
EOF

# Build custom model
ollama create python-assistant -f Modelfile
```

### Use custom model

```python
import ollama

response = ollama.chat(
    model='python-assistant',
    messages=[{'role': 'user', 'content': 'Write a sorting algorithm'}]
)
```

## 11. Model Comparison for Your Hardware

| Model            | Size (4-bit) | VRAM     | Speed     | Use Case         |
| ---------------- | ------------ | -------- | --------- | ---------------- |
| **phi3:mini**    | ~2GB         | LOW      | ⚡ FAST   | Quick tasks      |
| **mistral:7b**   | ~3.5GB       | MED      | ⚡ FAST   | General chat     |
| **codellama:7b** | ~3.5GB       | MED      | ⚡ FAST   | Code generation  |
| **llava:7b**     | ~4GB         | MED-HIGH | 🐌 SLOW   | Vision + text    |
| **gemma:7b**     | ~3.5GB       | MED      | ⚡ FAST   | Google's model   |
| **llama3:8b**    | ~4.5GB       | HIGH     | 🐌 MEDIUM | Latest from Meta |

## 12. Production Deployment

### Systemd Service (Auto-start)

```bash
# Create service file
sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Service
After=network.target

[Service]
Type=simple
User=$USER
Environment="OLLAMA_HOST=0.0.0.0:11434"
ExecStart=/usr/local/bin/ollama serve
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama
```

### Docker Deployment

```bash
# Run Ollama in Docker
docker run -d \\
  --gpus all \\
  -v ollama:/root/.ollama \\
  -p 11434:11434 \\
  --name ollama \\
  ollama/ollama

# Pull model in container
docker exec ollama ollama pull mistral:7b-instruct-q4_0
```

---

**Ready to Start?**

```bash
# Quick setup (copy-paste)
curl -fsSL https://ollama.ai/install.sh | sh
ollama serve &
ollama pull mistral:7b-instruct-q4_0
ollama run mistral:7b-instruct-q4_0 "Hello! Tell me about yourself."
```

🎉 You're all set!
