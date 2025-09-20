# ChainRice DATA Tool
FROM nixos/nix:2.18-alpine AS nix-builder

# Install Nix packages
COPY stacks/tools/DEV/packages/flake.nix /tmp/flake.nix
COPY stacks/tools/DEV/packages/libs /tmp/libs

# Build DATA tool using Nix
RUN nix-env -i -f /tmp/flake.nix -A packages.chainrice-data

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata

# Create app user
RUN addgroup -g 1001 -S chainrice && \
    adduser -u 1001 -S chainrice -G chainrice

# Set working directory
WORKDIR /app

# Copy DATA tool from Nix build
COPY --from=nix-builder /nix/store/*chainrice-data*/bin/chainrice-data /app/
COPY stacks/tools/DATA/ ./

# Change ownership
RUN chown -R chainrice:chainrice /app

# Switch to non-root user
USER chainrice

# Expose port for data analysis API
EXPOSE 8089

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8089/health || exit 1

# Run the DATA tool
CMD ["./chainrice-data"]
