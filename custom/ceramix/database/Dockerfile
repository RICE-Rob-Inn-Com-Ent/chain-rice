FROM golang:1.23-alpine

WORKDIR /app

# Install dependencies including inotify-tools for autopatch
RUN apk add --no-cache \
    git \
    ca-certificates \
    inotify-tools

# Copy source code
COPY .project/ceramix/database/ ./

# Initialize go module if go.mod doesn't exist
RUN if [ ! -f go.mod ]; then go mod init ceramix-database; fi

# Download dependencies if go.mod exists
RUN if [ -f go.mod ]; then go mod download; fi

# Build the service
RUN if [ -f go.mod ]; then \
    go mod download && \
    go build -o database-service .; \
else \
    go build -o database-service .; \
fi

# Copy and setup autopatch and entrypoint scripts
COPY .project/ceramix/database/autopatch.sh /autopatch.sh
COPY .project/ceramix/database/entrypoint.sh /entrypoint.sh
RUN chmod +x /autopatch.sh /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]

