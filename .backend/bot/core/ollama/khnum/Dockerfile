# Khnum - God of Wealth (Financial Analysis Stack)
FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl git build-essential && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN curl -fsSL https://ollama.com/install.sh | sh

RUN pip install --no-cache-dir fastapi uvicorn torch transformers pandas numpy matplotlib plotly requests

RUN mkdir -p /models /lora-adapters

COPY khnum-server.py /app/server.py
ENV GOD_NAME=Khnum
ENV GOD_ID=khnum
ENV OLLAMA_MODEL=mistral:7b-instruct-q4_K_M

EXPOSE 8000 11434

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
