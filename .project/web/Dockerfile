# Next.js Frontend Dockerfile with @rice/ui-kit workspace dependency
# Multi-stage build for optimal production deployment

# Stage 1: Dependencies
FROM node:20-alpine AS deps

# Install dependencies for node-gyp
RUN apk add --no-cache libc6-compat python3 make g++

WORKDIR /app

# Copy root workspace configuration
COPY package.json yarn.lock ./

# Copy workspace package.json files
COPY .frontend/web/package.json ./.frontend/web/package.json
COPY .project/web/package.json ./.project/web/package.json

# Install all workspace dependencies
RUN yarn install --frozen-lockfile || yarn install

# Stage 2: Builder
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/.frontend/web/node_modules ./.frontend/web/node_modules
COPY --from=deps /app/.project/web/node_modules ./.project/web/node_modules

# Copy source code for both workspaces
COPY .frontend/web ./.frontend/web
COPY .project/web ./.project/web

# Set build args
ARG NEXT_PUBLIC_API_URL=http://api.rice-mono.local
ARG NODE_ENV=production

ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NODE_ENV=$NODE_ENV
ENV NEXT_TELEMETRY_DISABLED=1

# Build Next.js app (will resolve @rice/ui-kit from workspace)
WORKDIR /app/.project/web
RUN yarn build

# Stage 3: Runner (Production)
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=builder /app/.project/web/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.project/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.project/web/.next/static ./.next/static

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3001

ENV PORT=3001
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3001/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "server.js"]
