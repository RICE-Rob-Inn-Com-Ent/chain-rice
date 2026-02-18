# Ollama - Local LLM Runtime

## Overview

Ollama enables running Large Language Models locally without API costs. Perfect for privacy, development, and
cost-effective AI applications.

## Features

- ✅ **Local LLMs** - Run models on your hardware
- ✅ **No API Costs** - Free inference
- ✅ **Privacy** - Data stays local
- ✅ **Multiple Models** - Llama, Mistral, Phi, Gemma, and more
- ✅ **OpenAI Compatible API** - Easy migration
- ✅ **GPU Acceleration** - CUDA, ROCm, Metal support

## Supported Models (Open Source)

### Recommended Models

- **Llama 3.3** (70B, 8B) - Meta's latest, excellent performance
- **Mistral 7B** - Fast and efficient
- **Phi-4** (14B) - Microsoft's latest, great reasoning
- **Gemma 2** (27B, 9B, 2B) - Google's efficient models
- **Qwen 2.5** (72B, 32B, 14B) - Alibaba's top models
- **DeepSeek Coder** - Best for code generation
- **Code Llama** - Meta's code-specialized model

### Lightweight Models

- **Phi-3 Mini** (3.8B) - Runs on CPU
- **TinyLlama** (1.1B) - Ultra-light
- **Gemma 2B** - Good balance

## Quick Start

### 1. Install Ollama

```bash
# Linux
curl -fsSL https://ollama.com/install.sh | sh

# macOS
brew install ollama

# Windows
# Download from https://ollama.com/download
```

### 2. Run a Model

```bash
# Pull and run Llama 3.3
ollama run llama3.3

# Pull Mistral
ollama pull mistral

# List installed models
ollama list

# Remove a model
ollama rm mistral
```

### 3. Use with Python

```python
from ollama import Client

client = Client(host='http://localhost:11434')

response = client.generate(
    model='llama3.3',
    prompt='Explain quantum computing in simple terms'
)

print(response['response'])
```

## Integration Examples

### With LangChain

```python
from langchain_community.llms import Ollama
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate

llm = Ollama(model="llama3.3", base_url="http://localhost:11434")

template = "Question: {question}\n\nAnswer:"
prompt = PromptTemplate(template=template, input_variables=["question"])

chain = LLMChain(llm=llm, prompt=prompt)
response = chain.run("What is machine learning?")
```

### With OpenAI API (Drop-in Replacement)

```python
from openai import OpenAI

client = OpenAI(
    base_url='http://localhost:11434/v1',
    api_key='ollama'  # required but unused
)

response = client.chat.completions.create(
    model="llama3.3",
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)
```

### RAG with Ollama

```python
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.chains import RetrievalQA

# Use Ollama for embeddings
embeddings = OllamaEmbeddings(model="llama3.3")

# Create vector store
vectorstore = Chroma(
    persist_directory="./chroma_db",
    embedding_function=embeddings
)

# RAG chain
qa = RetrievalQA.from_chain_type(
    llm=Ollama(model="llama3.3"),
    retriever=vectorstore.as_retriever()
)
```

## Model Files (Customize Models)

Create a `Modelfile`:

```dockerfile
# Modelfile
FROM llama3.3

# Set parameters
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40

# Set system message
SYSTEM """
You are a helpful AI assistant specialized in software development.
You provide clear, concise answers with code examples.
"""
```

Build custom model:

```bash
ollama create mymodel -f ./Modelfile
ollama run mymodel
```

## REST API

### Generate Completion

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.3",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

### Chat Completion

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.3",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ]
}'
```

### Embeddings

```bash
curl http://localhost:11434/api/embeddings -d '{
  "model": "llama3.3",
  "prompt": "Here is an article about AI"
}'
```

## Docker Setup

```yaml
# docker-compose.yml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama-models:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

volumes:
  ollama-models:
```

## Performance Tips

### GPU Acceleration

```bash
# Check GPU usage
nvidia-smi

# Run with specific GPU
CUDA_VISIBLE_DEVICES=0 ollama run llama3.3
```

### Quantization

- **Q4_K_M** - Best quality/size balance
- **Q5_K_M** - Better quality, larger
- **Q8_0** - Highest quality, largest

```bash
# Pull quantized version
ollama pull llama3.3:70b-q4_K_M
```

### Context Length

```python
# Increase context window
client.generate(
    model='llama3.3',
    prompt='Long text...',
    options={'num_ctx': 8192}  # Default is 2048
)
```

## Monitoring

```bash
# Show running models
ollama ps

# Model info
ollama show llama3.3

# System info
ollama show llama3.3 --modelfile
```

## Technologies

- **Ollama** - Local LLM runtime
- **llama.cpp** - Efficient inference engine
- **Python SDK** - `ollama-python`
- **LangChain Integration** - `langchain-community`

## References

- [Ollama GitHub](https://github.com/ollama/ollama)
- [Ollama Models](https://ollama.com/library)
- [Python SDK](https://github.com/ollama/ollama-python)
