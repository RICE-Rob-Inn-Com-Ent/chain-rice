# Vite UI Kit Dockerfile
# Development and production build for @rice-mono/ui-kit

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

# Copy source code
COPY .frontend/web ./.frontend/web

# Build Vite app
WORKDIR /app/.frontend/web
RUN yarn build

# Stage 3: Production server (Nginx)
FROM nginx:alpine AS production

# Copy built assets to nginx
COPY --from=builder /app/.frontend/web/dist /usr/share/nginx/html

# Copy nginx configuration
COPY .frontend/web/nginx.conf /etc/nginx/conf.d/default.conf 2>/dev/null || \
    echo 'server { listen 80; location / { root /usr/share/nginx/html; try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]

# Stage 4: Development server
FROM node:20-alpine AS development

WORKDIR /app

# Copy everything for development
COPY package.json yarn.lock ./
COPY .frontend/web ./.frontend/web
COPY .project/web/package.json ./.project/web/package.json

# Install dependencies
RUN yarn install

WORKDIR /app/.frontend/web

EXPOSE 5173

ENV VITE_HOST=0.0.0.0
ENV CHOKIDAR_USEPOLLING=true

CMD ["yarn", "dev", "--host", "0.0.0.0", "--port", "5173"]

