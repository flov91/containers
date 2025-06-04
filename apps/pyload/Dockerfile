# syntax=docker/dockerfile:1

ARG PYLOAD_VERSION="0.5.0b3.dev87"
ARG TARGETPLATFORM
ARG VERSION="1.0.0"
ARG BUILD_DATE="2025-03-08"

# Build stage
FROM ghcr.io/linuxserver/unrar:latest as unrar

FROM docker.io/library/alpine:3.19 AS prereq

# Set build environment variables
ENV CARGO_HOME="/cargo" \
    RUSTUP_HOME="/rustup" \
    PATH="/cargo/bin:$PATH" \
    PYTHONPATH="/app/lib/python3.11/site-packages"

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
        bash \
        build-base \
        cargo \
        curl \
        curl-dev \
        gcc \
        git \
        jq \
        libffi-dev \
        libjpeg-turbo-dev \
        musl-dev \
        openssl-dev \
        python3 \
        python3-dev \
        py3-pip \
        zlib-dev && \
    # Install Rust toolchain
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --default-toolchain 1.75.0

FROM prereq AS builder

ARG PYLOAD_VERSION

# Set up Python virtual environment and install dependencies
RUN python3 -m venv /app/venv && \
    source /app/venv/bin/activate && \
    pip install -U --no-cache-dir \
        pip \
        wheel \
        setuptools \
        dnspython \
        aiodns \
        maturin && \
    git clone https://github.com/poezio/slixmpp.git /app/slixmpp && \
    cd /app/slixmpp && \
    python3 setup.py install && \
    if [ -z ${PYLOAD_VERSION+x} ]; then \
        PYLOAD_VERSION=$(curl -sL https://pypi.python.org/pypi/pyload-ng/json | jq -r '. | .info.version'); \
    fi && \
    pip install -U --no-cache-dir "pyload-ng[all]==${PYLOAD_VERSION}" && \
    chown -R 568:568 /app/venv

# Final stage
FROM docker.io/library/alpine:3.19

# Build arguments
ARG BUILD_DATE
ARG VERSION
ARG PYLOAD_VERSION
ARG TARGETPLATFORM

# Set environment variables
ENV UMASK="0002" \
    TZ="Etc/UTC" \
    PYTHONPATH="/app/lib/python3.11/site-packages" \
    HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/config"

WORKDIR /app

# Install runtime dependencies
RUN   apk add --no-cache \
    ffmpeg \
    libjpeg-turbo \
    7zip \
    python3 \
    sqlite \
    catatonit \
    curl \
    tesseract-ocr && \
    rm -rf /tmp/*

# Copy built artifacts from builder
COPY --from=builder /app/venv /app/venv
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# Copy application files
COPY ./entrypoint.sh /entrypoint.sh
COPY ./pyload.config /app/pyload.config

# Set up permissions
RUN chmod +x /entrypoint.sh && \
    mkdir -p /config && \
    addgroup -g 568 pyload && \
    adduser -h /config -s /sbin/nologin -G pyload -D -u 568 pyload && \
    chown -R pyload:pyload /config /app

USER pyload
WORKDIR /config

VOLUME ["/config"]
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -sf -X GET http://localhost:8000 || exit 1

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]

# Labels
LABEL org.opencontainers.image.title="pyload-ng" \
    org.opencontainers.image.description="Modern download manager based on Python3 (pyload version: ${PYLOAD_VERSION} )" \
    org.opencontainers.image.source="https://github.com/pyload/pyload" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.documentation="https://github.com/flov91/containers/apps/pyload" \
    org.opencontainers.image.authors="flov91" \
    maintainer="flov91"
