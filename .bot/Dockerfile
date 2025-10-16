# AI Bot Core Dockerfile
# Multi-stage build for optimal image size and performance

# Stage 1: Base image with CUDA support
FROM nvidia/cuda:12.1-devel-ubuntu22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-distutils \
    python3-pip \
    git \
    wget \
    curl \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    libffi-dev \
    libblas-dev \
    liblapack-dev \
    libopenblas-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libgtk-3-dev \
    libatlas-base-dev \
    gfortran \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic links for python
RUN ln -s /usr/bin/python3.11 /usr/bin/python
RUN ln -s /usr/bin/python3.11 /usr/bin/python3

# Upgrade pip
RUN python -m pip install --upgrade pip setuptools wheel

# Stage 2: Python dependencies
FROM base AS dependencies

# Install PyTorch with CUDA support
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install core ML libraries
RUN pip install \
    numpy \
    scipy \
    scikit-learn \
    pandas \
    matplotlib \
    seaborn \
    opencv-python \
    openai-whisper

# Install Hugging Face libraries
RUN pip install \
    transformers \
    diffusers \
    datasets \
    accelerate

# Install FastAPI and web dependencies
RUN pip install \
    fastapi \
    uvicorn[standard] \
    python-multipart \
    python-jose[cryptography] \
    passlib[bcrypt] \
    python-dotenv

# Install additional utilities
RUN pip install \
    Pillow \
    requests \
    aiofiles \
    httpx

# Stage 3: Application
FROM dependencies AS app

# Set working directory
WORKDIR /app

# Copy application files
COPY app.py /app/
COPY requirements.txt /app/requirements.txt

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command
CMD ["python", "app.py", "--host", "0.0.0.0", "--port", "8000"]

# Development stage (optional)
FROM app AS development

# Switch back to root for development tools
USER root

# Install development dependencies
RUN pip install \
    pytest \
    pytest-asyncio \
    black \
    flake8 \
    mypy \
    jupyter \
    ipython

# Install additional debugging tools
RUN apt-get update && apt-get install -y \
    htop \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Switch back to app user
USER appuser

# Override command for development
CMD ["python", "app.py", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Production stage (final)
FROM app AS production

# Add production optimizations
ENV PYTHONOPTIMIZE=1
ENV OMP_NUM_THREADS=1

# Production command with multiple workers
CMD ["python", "app.py", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
