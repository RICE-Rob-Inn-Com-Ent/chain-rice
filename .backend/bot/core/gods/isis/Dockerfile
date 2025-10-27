# Isis - Goddess of Healing (Medical AI Stack)
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    curl git build-essential libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install --no-cache-dir \
    fastapi uvicorn \
    monai \
    torch torchvision \
    transformers \
    pillow numpy

RUN mkdir -p /models /lora-adapters

COPY isis-server.py /app/server.py
ENV GOD_NAME=Isis
ENV GOD_ID=isis

EXPOSE 8000

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
