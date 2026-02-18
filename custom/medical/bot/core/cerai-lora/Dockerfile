FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    git \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set Python as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy requirements and install Python dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy application code
COPY . /app/

# Create directories for models, adapters, and data
RUN mkdir -p /app/models /app/adapters /app/data /app/scripts

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0
ENV TRANSFORMERS_CACHE=/app/models/.cache
ENV HF_HOME=/app/models/.cache

# Expose API port
EXPOSE 8007

# Default command (can be overridden in docker-compose)
# Run API server by default, training can be done via docker exec
CMD ["python3", "scripts/lora_api.py"]

