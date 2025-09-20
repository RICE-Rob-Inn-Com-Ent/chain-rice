# ChainRice CONTRACTS Tool
FROM nixos/nix:2.18-alpine AS nix-builder

# Install Nix packages
COPY stacks/tools/DEV/packages/flake.nix /tmp/flake.nix
COPY stacks/tools/DEV/packages/libs /tmp/libs

# Build CONTRACTS tool using Nix
RUN nix-env -i -f /tmp/flake.nix -A packages.chainrice-contracts

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata

# Create app user
RUN addgroup -g 1001 -S chainrice && \
    adduser -u 1001 -S chainrice -G chainrice

# Set working directory
WORKDIR /app

# Copy CONTRACTS tool from Nix build
COPY --from=nix-builder /nix/store/*chainrice-contracts*/bin/chainrice-contracts /app/
COPY stacks/tools/CONTRACTS/ ./

# Change ownership
RUN chown -R chainrice:chainrice /app

# Switch to non-root user
USER chainrice

# Expose port for contract testing API
EXPOSE 8088

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8088/health || exit 1

# Run the CONTRACTS tool
CMD ["./chainrice-contracts"]
