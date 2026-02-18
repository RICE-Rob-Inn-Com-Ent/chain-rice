# Simple development Dockerfile for code-rice web with autopatch support
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
RUN mkdir -p .project/code-rice/web

# Copy package.json files first (needed for workspace resolution)
COPY .project/code-rice/web/package.json ./.project/code-rice/web/package.json

# Copy the rest of the source code
COPY .project/code-rice/web ./.project/code-rice/web

# Copy and setup entrypoint and autopatch scripts
COPY .project/code-rice/web/entrypoint.sh /entrypoint.sh
COPY .project/code-rice/web/autopatch.sh /autopatch.sh
RUN chmod +x /entrypoint.sh /autopatch.sh

# Install dependencies (from root for workspace support)
# Note: This may fail due to network, but entrypoint will retry
RUN bun install || echo "Initial install failed, will retry in entrypoint"

# Expose port
EXPOSE 3003

ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3003

WORKDIR /app/.project/code-rice/web
ENTRYPOINT ["/entrypoint.sh"]





