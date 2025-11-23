# Containerfile for building Podman Desktop flatpak on Konflux
# Uses flatpak-builder to create a flatpak bundle from source

FROM registry.redhat.io/rhel10/flatpak-sdk:latest

USER root

# Install required build tools
RUN dnf install -y \
    flatpak-builder \
    git \
    curl \
    jq \
    && dnf clean all

# Set working directory
WORKDIR /workspace

# Copy source code (including submodule and flatpak manifest)
COPY --chown=root:root . .

# Build the flatpak
RUN flatpak-builder --repo=/workspace/repo --force-clean /workspace/build io.podman_desktop.PodmanDesktop.yml

# Create flatpak bundle
RUN flatpak build-bundle /workspace/repo /workspace/podman-desktop.flatpak io.podman_desktop.PodmanDesktop

# Export the flatpak bundle to final stage
FROM registry.access.redhat.com/ubi10/ubi-minimal:latest

COPY --from=0 /workspace/podman-desktop.flatpak /podman-desktop.flatpak

LABEL name="podman-desktop-flatpak" \
      vendor="Podman Desktop" \
      version="1.23.1" \
      summary="Podman Desktop flatpak bundle built via Konflux" \
      description="Podman Desktop application packaged as flatpak from upstream source using Konflux CI/CD"

CMD ["/bin/sh", "-c", "echo 'Podman Desktop flatpak bundle available at /podman-desktop.flatpak'"]
