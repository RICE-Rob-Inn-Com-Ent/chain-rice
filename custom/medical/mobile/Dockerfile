# Flutter Mobile Development Dockerfile

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    openjdk-25-jdk \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ENV FLUTTER_VERSION=3.35.6
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --branch ${FLUTTER_VERSION} --depth 1 https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    flutter doctor -v && \
    flutter config --enable-android

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . ./

EXPOSE 3004

# Keep container running - mobile apps need to be built/run manually or via CI/CD
CMD ["sh", "-c", "echo 'Flutter mobile container ready. Use flutter build or flutter run manually.' && sleep infinity"]

