# Containerfile for building Podman Desktop on Konflux
# Multi-stage build for Node.js application with flatpak packaging

# Stage 1: Build podman-desktop from source
FROM quay.io/konflux-ci/yarn3-nodejs20-ubi9-minimal:latest AS builder

USER root

# Install build dependencies
RUN microdnf install -y \
    git \
    python3 \
    make \
    gcc \
    gcc-c++ \
    && microdnf clean all

# Set working directory
WORKDIR /workspace

# Copy source code (including submodule)
COPY --chown=default:root . .

# Change to podman-desktop submodule directory
WORKDIR /workspace/podman-desktop

# Install dependencies
RUN yarn install --frozen-lockfile

# Build the application
RUN yarn run build

# Stage 2: Package build artifacts
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

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
