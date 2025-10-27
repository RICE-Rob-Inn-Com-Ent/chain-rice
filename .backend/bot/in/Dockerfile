# Bot Integrations Service
# FastAPI service for external AI provider integrations

FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements
COPY requirements.txt /app/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . /app

# Environment variables
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 8200

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8200/health || exit 1

# Start application
CMD ["python", "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8200"]

