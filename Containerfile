# Containerfile for building Podman Desktop on Konflux
# Multi-stage build for Node.js application with flatpak packaging

# Stage 1: Build podman-desktop from source
FROM registry.access.redhat.com/ubi10/nodejs-22:latest AS builder

USER root

# Install pnpm for v1.23.1 (packageManager field specifies pnpm@10.20.0)
# Note: git, python3, make, gcc, gcc-c++ already present in nodejs-20 image
RUN npm install -g pnpm@10.20.0

# Set working directory
WORKDIR /workspace

# Copy source code (including submodule)
COPY --chown=default:root . .

# Change to podman-desktop submodule directory
WORKDIR /workspace/podman-desktop

# Install dependencies using pnpm
RUN pnpm install --frozen-lockfile

# Build the application with increased heap size
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN pnpm run build

# Stage 2: Package build artifacts
FROM registry.access.redhat.com/ubi10/ubi-minimal:latest

# Copy all build outputs from podman-desktop packages
COPY --from=builder /workspace/podman-desktop/packages /app/packages
COPY --from=builder /workspace/podman-desktop/extensions /app/extensions

# Set metadata
LABEL name="podman-desktop" \
      vendor="Podman Desktop" \
      version="1.9.1" \
      summary="Podman Desktop built via Konflux" \
      description="Podman Desktop application built from upstream source using Konflux CI/CD"

# Default command (placeholder - this is a desktop app, not runnable as container)
CMD ["/bin/sh", "-c", "echo 'Podman Desktop build artifacts packaged successfully'"]
