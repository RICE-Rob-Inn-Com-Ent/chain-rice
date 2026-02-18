# Simple development Dockerfile for medical web with autopatch support
FROM node:20-alpine

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash && \
    mv /root/.bun/bin/bun /usr/local/bin/bun

# Install inotify-tools for efficient file watching (autopatch)
RUN apk add --no-cache libc6-compat python3 make g++ inotify-tools curl unzip

WORKDIR /app

# Copy root monorepo files first (needed for bun workspace)
COPY package.json bun.lockb* ./

# Create directories first
RUN mkdir -p .project/medical/web

# Copy package.json files first (needed for workspace resolution)
COPY .project/medical/web/package.json ./.project/medical/web/package.json

# Copy the rest of the source code
COPY .project/medical/web ./.project/medical/web

# Copy and setup entrypoint and autopatch scripts
COPY .project/medical/web/entrypoint.sh /entrypoint.sh
COPY .project/medical/web/autopatch.sh /autopatch.sh
RUN chmod +x /entrypoint.sh /autopatch.sh

# Install dependencies (from root for workspace support)
# Note: This may fail due to network, but entrypoint will retry
RUN bun install || echo "Initial install failed, will retry in entrypoint"

# Expose port
EXPOSE 3002

ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3002

WORKDIR /app/.project/ceramix/web
ENTRYPOINT ["/entrypoint.sh"]





