# Thoth - God of Knowledge (Text Processing Stack)
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Copy requirements first
COPY requirements.txt /app/requirements.txt

# Install all Python packages from requirements
RUN pip install --no-cache-dir -r /app/requirements.txt

# Create models directory
RUN mkdir -p /models /lora-adapters

# Copy application code
COPY thoth-server.py /app/server.py

# Environment variables
ENV GOD_NAME=Thoth
ENV GOD_ID=thoth
ENV OLLAMA_MODEL=mistral:7b-instruct-q4_K_M
ENV PYTHONUNBUFFERED=1

# Expose ports
EXPOSE 8000 11434

# Start script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
