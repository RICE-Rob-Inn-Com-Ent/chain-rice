FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including inotify-tools for autopatch
RUN apt-get update && apt-get install -y \
    curl \
    git \
    inotify-tools \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements if exists
COPY .project/meowtopia/bot/requirements.txt* ./
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Install default AI/ML packages
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    httpx \
    pydantic \
    langchain \
    langchain-ollama \
    langgraph

# Copy source code
COPY .project/meowtopia/bot . .

# Copy and setup autopatch and entrypoint scripts
COPY .project/meowtopia/bot/autopatch.sh /autopatch.sh
COPY .project/meowtopia/bot/entrypoint.sh /entrypoint.sh
RUN chmod +x /autopatch.sh /entrypoint.sh

# Set PYTHONPATH to include current directory
ENV PYTHONPATH=/app

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]

