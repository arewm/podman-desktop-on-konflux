# Containerfile for building Podman Desktop flatpak on Konflux
# Multi-stage build: build app -> install to /app -> export as OCI flatpak

# Stage 1: Build podman-desktop from source
FROM registry.redhat.io/ubi10/nodejs-22:latest AS builder

USER root

# Install pnpm for v1.23.1 (packageManager field specifies pnpm@10.20.0)
RUN npm install -g pnpm@10.20.0

WORKDIR /workspace
COPY --chown=default:root . .

WORKDIR /workspace/podman-desktop

# Install dependencies and build
RUN pnpm install --frozen-lockfile

ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN pnpm run build

# Stage 2: Install into /app using flatpak-sdk as base
FROM registry.redhat.io/rhel10/flatpak-sdk AS install

# Import repos and gpg keys from UBI to install nodejs
COPY --from=registry.redhat.io/ubi10:latest /etc/yum.repos.d /etc/yum.repos.d
RUN rpm -e $(rpm -q 'gpg-pubkey-*-*') && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

# Install nodejs and relocate to /app
RUN dnf -y install nodejs nodejs-full-i18n npm --setopt=install_weak_deps=False && \
    mkdir -p /app/{bin,lib,lib64,share} && \
    mv /usr/lib64/libnode* /usr/lib64/libuv* /app/lib64 && \
    mv /usr/lib/node_modules* /app/lib && \
    mv /usr/share/node* /app/share && \
    mv /usr/bin/{node*,npm*,npx*} /app/bin && \
    sed -i --follow-symlinks s@/usr/bin@/app/bin@ /app/bin/{npm*,npx*} && \
    /sbin/ldconfig

# Set PATH for build stage
ENV PATH=/app/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Copy built application from builder stage
COPY --from=builder /workspace/podman-desktop/packages /app/podman-desktop/packages
COPY --from=builder /workspace/podman-desktop/extensions /app/podman-desktop/extensions

# Create wrapper script to launch podman-desktop
RUN mkdir -p /app/bin && \
    cat > /app/bin/podman-desktop <<'EOF' && \
#!/bin/bash
exec /app/podman-desktop/packages/main/dist/index.js "$@"
EOF
    chmod +x /app/bin/podman-desktop

# Stage 3: Export as OCI flatpak
FROM quay.io/flatpak-container/flatpak-build AS export

COPY container.yaml /tmp

RUN --mount=type=bind,src=/,dst=/contents,from=install \
    flatpak-container container-export \
    --containerspec=/tmp/container.yaml \
    --resultdir=/export

# Final stage - this becomes the OCI flatpak image
FROM scratch

COPY --from=export /export /
