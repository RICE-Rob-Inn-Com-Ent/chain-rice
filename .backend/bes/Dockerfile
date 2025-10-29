# Bes - Egyptian God of Music and Voice
# Tortoise TTS + XTTS + MusicGen
# Port: 8007

FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Install Python 3.10
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3.10-venv \
    git \
    wget \
    curl \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.10 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install PyTorch with CUDA support
RUN pip install --no-cache-dir torch==2.1.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu118

# Install other requirements
RUN pip install --no-cache-dir -r requirements.txt

# Create output directory
RUN mkdir -p /tmp/bes_output

# Copy application
COPY main.py .

# Expose port
EXPOSE 8007

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0
ENV NUMBA_CACHE_DIR=/tmp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8007/health || exit 1

# Run FastAPI server
CMD ["python", "main.py"]

