# Flutter Desktop Development Dockerfile
# Supports hot reload and X11 forwarding for GUI display

FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxcb1 \
    libxkbcommon-x11-0 \
    libxkbcommon0 \
    libxrandr2 \
    libxss1 \
    libgconf-2-4 \
    libxtst6 \
    libxrender1 \
    libasound2 \
    libpangocairo-1.0-0 \
    libatk1.0-0 \
    libcairo-gobject2 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    clang \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ENV FLUTTER_VERSION=3.35.6
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --branch ${FLUTTER_VERSION} --depth 1 https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    flutter doctor -v && \
    flutter config --enable-linux-desktop

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . ./

# Expose Flutter dev server port (for hot reload)
EXPOSE 3003

# Set environment variables for X11 forwarding
ENV DISPLAY=${DISPLAY:-:0}
ENV XAUTHORITY=${XAUTHORITY:-/tmp/.X11-unix/X0}

# Run Flutter in development mode with hot reload
CMD ["flutter", "run", "-d", "linux", "--hot"]

