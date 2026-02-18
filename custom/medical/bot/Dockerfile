FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including inotify-tools for autopatch and OCR dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    inotify-tools \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY .project/ceramix/bot/core/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy source code
COPY .project/ceramix/bot . .

# Copy and setup autopatch and entrypoint scripts
COPY .project/ceramix/bot/autopatch.sh /autopatch.sh
COPY .project/ceramix/bot/entrypoint.sh /entrypoint.sh
RUN chmod +x /autopatch.sh /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]







