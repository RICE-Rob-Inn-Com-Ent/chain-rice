# Ra - God of Light (Graphics & Image Generation Stack)
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libgomp1 \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python packages for graphics
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    diffusers \
    transformers \
    torch \
    torchvision \
    accelerate \
    compel \
    safetensors \
    realesrgan \
    trimesh \
    rembg \
    pillow \
    numpy

RUN mkdir -p /models /lora-adapters

COPY ra-server.py /app/server.py
COPY requirements.txt /app/requirements.txt

ENV GOD_NAME=Ra
ENV GOD_ID=ra
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
