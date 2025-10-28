# Bastet - Goddess of Vision (Computer Vision Stack)
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python packages
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn[standard] \
    python-multipart

# Create models directory
RUN mkdir -p /models /output

# Copy application code
COPY bastet-server.py /app/server.py

# Environment variables
ENV GOD_NAME=Bastet
ENV GOD_ID=bastet
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 8000

# Start script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]

