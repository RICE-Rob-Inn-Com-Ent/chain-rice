# Simple development Dockerfile for meowtopia web
FROM node:20-alpine

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash && \
    mv /root/.bun/bin/bun /usr/local/bin/bun

# Install inotify-tools for efficient file watching (autopatch)
RUN apk add --no-cache libc6-compat python3 make g++ inotify-tools curl unzip

# Create symlinks for Prisma (requires OpenSSL 1.1, but Alpine 3.22 has OpenSSL 3.x)
RUN ln -sf /usr/lib/libssl.so.3 /usr/lib/libssl.so.1.1 && \
    ln -sf /usr/lib/libcrypto.so.3 /usr/lib/libcrypto.so.1.1

WORKDIR /app

# Copy root monorepo files first (needed for bun workspace)
COPY package.json bun.lockb* ./

# Create directories first
RUN mkdir -p .project/meowtopia/web

# Copy package.json files first (needed for workspace resolution)
COPY .project/meowtopia/web/package.json ./.project/meowtopia/web/package.json

# Copy the rest of the source code
COPY .project/meowtopia/web ./.project/meowtopia/web

# Copy and setup entrypoint and autopatch scripts
COPY .project/meowtopia/web/entrypoint.sh /entrypoint.sh
COPY .project/meowtopia/web/autopatch.sh /autopatch.sh
RUN chmod +x /entrypoint.sh /autopatch.sh

# Install dependencies (from root for workspace support)
# Note: This may fail due to network, but entrypoint will retry
RUN bun install || echo "Initial install failed, will retry in entrypoint"

# Generate Prisma Client (using bunx to use the correct Prisma version)
# Then copy it to the expected location for Next.js
WORKDIR /app/.project/meowtopia/web
RUN bunx prisma@5.22.0 generate --schema=./prisma/schema.prisma || true && \
    mkdir -p node_modules/.prisma

# Expose port
EXPOSE 3001

ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3001

WORKDIR /app/.project/meowtopia/web
ENTRYPOINT ["/entrypoint.sh"]



