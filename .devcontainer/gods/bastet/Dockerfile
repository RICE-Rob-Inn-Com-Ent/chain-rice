# Bastet - Goddess of Vision (Computer Vision Stack)
FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl git build-essential libgomp1 libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install --no-cache-dir fastapi uvicorn insightface onnxruntime mmcv mmdet mmpose torch pillow opencv-python

RUN mkdir -p /models /lora-adapters

COPY bastet-server.py /app/server.py
ENV GOD_NAME=Bastet
ENV GOD_ID=bastet

EXPOSE 8000

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
