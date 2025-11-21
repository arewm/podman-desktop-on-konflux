# Containerfile for building Podman Desktop on Konflux
# Multi-stage build for Node.js application with flatpak packaging

# Stage 1: Build podman-desktop from source
FROM registry.access.redhat.com/ubi9/nodejs-20:latest AS builder

USER root

# Install build dependencies
RUN dnf install -y \
    git \
    python3 \
    make \
    gcc \
    gcc-c++ \
    && dnf clean all

# Set working directory
WORKDIR /workspace

# Copy source code (including submodule)
COPY --chown=default:root . .

# Install pnpm globally
RUN npm install -g pnpm@latest

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build the application
RUN pnpm run build

# Stage 2: Create minimal runtime image
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Copy built application from builder
COPY --from=builder /workspace/dist /app

# Set metadata
LABEL name="podman-desktop" \
      vendor="Podman Desktop" \
      version="1.9.1" \
      summary="Podman Desktop built via Konflux" \
      description="Podman Desktop application built from upstream source using Konflux CI/CD"

# Default command (placeholder - this is a desktop app)
CMD ["/bin/sh", "-c", "echo 'Podman Desktop build artifact - not directly executable in container'"]
