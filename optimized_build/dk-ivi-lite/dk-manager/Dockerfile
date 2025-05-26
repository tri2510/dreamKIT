# First stage: Build dependencies in a full Python environment
FROM ubuntu:24.04 AS app-builder
#FROM debian:bookworm AS app-builder

WORKDIR /app/

# Install necessary packages for building the environment
RUN apt-get update && apt install -y git cmake build-essential libssl-dev libboost-all-dev curl qt6-base-dev pax-utils

COPY copy-app-lddtree.sh /app/copy-app-lddtree.sh
# COPY src/socket.io-client-cpp /app/socket.io-client-cpp
COPY src/. /app/dk-manager

# Install Python dependencies into a specific directory
RUN cd /app \
    && git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git \
    && cd socket.io-client-cpp \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j4 \
    && make install \
    && cd /app \
    && cd dk-manager \
    && mkdir build \
    && cd build \
    #&& /usr/lib/qt6/bin/qmake .. \
    && cmake .. \
    && make -j4 \
    && chmod +x /app/copy-app-lddtree.sh \
    && /app/copy-app-lddtree.sh 

# Second stage: Create a minimal runtime environment
FROM ubuntu:24.04 AS target
#FROM debian:bookworm AS target

WORKDIR /app

# Copy the Python packages from the builder stage to the Alpine image
COPY --from=app-builder /app/dk-manager/build/exec /app/exec

# Copy application files
COPY start.sh /app/

# Set execute permission for the script
RUN chmod +x /app/start.sh

# Set environment variables
ENV LD_LIBRARY_PATH=/app/exec

# Execute the script
CMD ["/app/start.sh"]
