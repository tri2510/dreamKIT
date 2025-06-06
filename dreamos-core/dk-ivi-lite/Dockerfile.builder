# ==============================================
# DreamKIT IVI Builder Image - Development Environment
# ==============================================
FROM ubuntu:24.04

WORKDIR /app

# Install all build dependencies
RUN apt-get update && apt-get install -y \
    git cmake build-essential libssl-dev libboost-all-dev curl \
    qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-declarative-private-dev \
    libqt6quick6 qml6-module-qtquick qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts qml6-module-qtquick-window \
    qml6-module-qtqml-workerscript qml6-module-qtquick-templates \
    python3.12 python3.12-dev libpython3.12 pax-utils \
    ccache ninja-build \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup ccache for faster compilation
ENV CCACHE_DIR=/cache/ccache
ENV CC="ccache gcc"
ENV CXX="ccache g++"

# Create build directories
RUN mkdir -p /app/build /cache/ccache

# Labels for GHCR
LABEL org.opencontainers.image.source=https://github.com/tri2510/dreamKIT
LABEL org.opencontainers.image.description="DreamKIT IVI Builder - Development environment with Qt6 and build tools"
LABEL org.opencontainers.image.licenses=MIT

# Default command
CMD ["/bin/bash"]