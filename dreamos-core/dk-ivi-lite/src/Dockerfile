FROM ubuntu:22.04

# Arguments for Qt package and proxy settings
ARG QT_SOURCE="qt-everywhere-src-6.9.0.tar.xz"
ARG QT_VERSION="6.9.0"
ARG QT_DIR="qt-everywhere-src-6.9.0"
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG http_proxy=""
ARG https_proxy=""

# Set environment variables for proxy
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
ENV DEBIAN_FRONTEND=noninteractive
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV QT_QPA_PLATFORM=xcb
ENV QT_PLUGIN_PATH=/usr/local/plugins
ENV QT_QPA_PLATFORM_PLUGIN_PATH=/usr/local/plugins/platforms
ENV XKB_CONFIG_ROOT=/usr/share/X11/xkb

# Add Ubuntu universe repository
RUN echo "deb http://archive.ubuntu.com/ubuntu jammy main universe" > /etc/apt/sources.list.d/universe.list

# Install required build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    perl \
    python3 \
    python3-dev \
    git \
    cmake \
    ninja-build \
    pkg-config \
    libglib2.0-dev \
    libdbus-1-dev \
    libicu-dev \
    libsqlite3-dev \
    libvulkan-dev \
    libxcb1-dev \
    libxcb-glx0-dev \
    libxcb-xinerama0-dev \
    libxcb-icccm4-dev \
    libxcb-image0-dev \
    libxcb-keysyms1-dev \
    libxcb-randr0-dev \
    libxcb-render-util0-dev \
    libxcb-render0-dev \
    libxcb-shape0-dev \
    libxcb-sync-dev \
    libxcb-xfixes0-dev \
    libxcb-xkb-dev \
    libxcb-util-dev \
    libxcb-shm0-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxrender-dev \
    libssl-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    mesa-common-dev \
    libglvnd-dev \
    libglx-dev \
    # These needed additional packages
    libxcb-cursor0 \
    libxcb-cursor-dev \
    libgtk-3-dev \
    # Runtime libraries for XCB
    libxcb1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-render0 \
    libxcb-shape0 \
    libxcb-shm0 \
    libxcb-sync1 \
    libxcb-xfixes0 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Create cache directories
RUN mkdir -p /qt-cache

# Copy the app files
COPY . /app/

# Download and extract Qt
RUN echo "🔄 Starting Qt acquisition..." && \
    if [ -f "/app/${QT_SOURCE}" ]; then \
        echo "📦 Using Qt package from /app"; \
        cp "/app/${QT_SOURCE}" "/qt-cache/${QT_SOURCE}"; \
    else \
        echo "⬇️ Downloading Qt package..."; \
        wget -q --show-progress -O "/qt-cache/${QT_SOURCE}" \
        "https://download.qt.io/archive/qt/6.9/${QT_VERSION}/single/${QT_SOURCE}"; \
    fi && \
    echo "📂 Extracting Qt package..." && \
    tar xf "/qt-cache/${QT_SOURCE}" -C / --use-compress-program="xz -T0" && \
    echo "✅ Extraction complete" && \
    rm -f "/qt-cache/${QT_SOURCE}"

# Build Qt with XCB support
WORKDIR /${QT_DIR}

# Configure Qt with XCB support
RUN echo "🔧 Configuring Qt with XCB support..." && \
    ./configure -opensource -confirm-license \
        -nomake examples \
        -nomake tests \
        -feature-xcb \
        -feature-xkbcommon \
        -feature-xkbcommon-x11 \
        -prefix /usr/local

# Build and install Qt
RUN echo "🔨 Building and installing Qt..." && \
    cmake --build . && \
    cmake --install .

# Verify XCB plugin was built
RUN find /usr/local -name "libqxcb.so" || echo "⚠️ XCB plugin not found"

# Set up a helper script for running with X11
RUN echo '#!/bin/bash\n\
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/local/plugins/platforms\n\
export QT_PLUGIN_PATH=/usr/local/plugins\n\
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH\n\
export QT_QPA_PLATFORM=xcb\n\
export DISPLAY=${DISPLAY:-:1}\n\
\n\
# Check if X11 is available\n\
if [ ! -e "/tmp/.X11-unix/X${DISPLAY#:}" ]; then\n\
    echo "⚠️ Warning: X11 socket for $DISPLAY not found. GUI applications may not display."\n\
    echo "Make sure to run the container with: -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY"\n\
fi\n\
\n\
# Run the command passed as arguments\n\
exec "$@"\n\
' > /usr/local/bin/x11-run && chmod +x /usr/local/bin/x11-run

# Build your application
WORKDIR /app
RUN rm -rf build && mkdir build
WORKDIR /app/build
RUN cmake .. \
    -DCMAKE_PREFIX_PATH=/usr/local \
    -DCMAKE_BUILD_TYPE=Release && \
    cmake --build .

# Set entrypoint to the X11 runner script
ENTRYPOINT ["/usr/local/bin/x11-run"]

# Default command runs your application
CMD ["/app/build/dk_ivi"]