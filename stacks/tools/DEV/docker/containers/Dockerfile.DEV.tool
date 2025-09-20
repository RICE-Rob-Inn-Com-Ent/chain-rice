# ChainRice DEV Tool
FROM nixos/nix:2.18-alpine AS nix-builder

# Install Nix packages
COPY stacks/tools/DEV/packages/flake.nix /tmp/flake.nix
COPY stacks/tools/DEV/packages/libs /tmp/libs

# Build DEV tool using Nix
RUN nix-env -i -f /tmp/flake.nix -A packages.chainrice-dev

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata docker-cli

# Create app user
RUN addgroup -g 1001 -S chainrice && \
    adduser -u 1001 -S chainrice -G chainrice

# Set working directory
WORKDIR /app

# Copy DEV tool from Nix build
COPY --from=nix-builder /nix/store/*chainrice-dev*/bin/chainrice-dev /app/
COPY stacks/tools/DEV/ ./

# Change ownership
RUN chown -R chainrice:chainrice /app

# Switch to non-root user
USER chainrice

# Expose port for DevOps services
EXPOSE 8090

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8090/health || exit 1

# Run the DEV tool
CMD ["./chainrice-dev"]
