#!/bin/bash

# ==============================================
# DK IVI Debug Runner
# ==============================================
# Runs dk_ivi with comprehensive debug logging

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[DEBUG]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"
DK_IVI_BINARY="$OUTPUT_DIR/dk_ivi"

print_info "DK IVI Debug Runner Starting..."
print_info "Script directory: $SCRIPT_DIR"
print_info "Output directory: $OUTPUT_DIR"
print_info "Binary path: $DK_IVI_BINARY"

# Check if binary exists
if [ ! -f "$DK_IVI_BINARY" ]; then
    print_error "dk_ivi binary not found at: $DK_IVI_BINARY"
    print_info "Please build the application first with: ./build_optimized.sh"
    exit 1
fi

# Set up environment variables for debugging
export QT_LOGGING_RULES="*=true;dk.ivi.*=true;dk.ivi.marketplace=true;dk.ivi.main=true"
export QT_FORCE_STDERR_LOGGING=1

# Set library path for shared libraries
export LD_LIBRARY_PATH="$OUTPUT_DIR/library:$LD_LIBRARY_PATH"

# Debug environment variables
export DK_USER="${DK_USER:-$(whoami)}"
export DK_EMBEDDED_MODE="${DK_EMBEDDED_MODE:-1}"
export DK_MOCK_MODE="${DK_MOCK_MODE:-1}"
export DK_CONTAINER_ROOT="${DK_CONTAINER_ROOT:-/home/$DK_USER/.dk/}"

print_status "Environment setup for debugging:"
print_info "DK_USER: $DK_USER"
print_info "DK_EMBEDDED_MODE: $DK_EMBEDDED_MODE"
print_info "DK_MOCK_MODE: $DK_MOCK_MODE"
print_info "DK_CONTAINER_ROOT: $DK_CONTAINER_ROOT"
print_info "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
print_info "QT_LOGGING_RULES: $QT_LOGGING_RULES"

# Ensure .dk directory structure exists
mkdir -p "$DK_CONTAINER_ROOT"
mkdir -p "$DK_CONTAINER_ROOT/dk_marketplace"
mkdir -p "$DK_CONTAINER_ROOT/dk_installedapps"
mkdir -p "$DK_CONTAINER_ROOT/dk_installedservices"
mkdir -p "$DK_CONTAINER_ROOT/dk_manager"

print_info ".dk directory structure verified"

# Use Docker runtime like the normal build script
REPO_OWNER=${REPO_OWNER:-"tri2510"}
RUNTIME_IMAGE="ghcr.io/${REPO_OWNER}/dk-ivi-runtime:latest"

# Check if runtime image exists
if ! docker images $RUNTIME_IMAGE | grep -q $RUNTIME_IMAGE; then
    print_warning "Runtime image not found. Pulling from GHCR first..."
    if ! docker pull $RUNTIME_IMAGE; then
        print_error "Failed to pull runtime image. Please run: ./build_optimized.sh images"
        exit 1
    fi
fi

# Set up X11 forwarding and runtime environment (from build_optimized.sh)
runtime_dir="/run/user/$(id -u)"

# Ensure XDG_RUNTIME_DIR exists
if [ ! -d "$runtime_dir" ]; then
    print_warning "XDG_RUNTIME_DIR $runtime_dir does not exist, using /tmp/runtime-$(id -u)"
    runtime_dir="/tmp/runtime-$(id -u)"
    mkdir -p "$runtime_dir"
fi

# Set up DISPLAY
if [ -z "$DISPLAY" ]; then
    print_warning "DISPLAY not set, using :0"
    export DISPLAY=":0"
fi

# Enable X11 forwarding for Docker
print_info "Enabling X11 forwarding for Docker..."
xhost +local:docker >/dev/null 2>&1 || {
    print_warning "Failed to run 'xhost +local:docker'"
    print_info "X11 forwarding may not work properly"
}

print_info "X11 Display: $DISPLAY"
print_info "XDG_RUNTIME_DIR: $runtime_dir"

# Check if DRI devices exist
if [ ! -e "/dev/dri" ]; then
    print_warning "No GPU devices found (/dev/dri), using software rendering only"
    gpu_opts=""
else
    print_info "GPU devices found, enabling hardware acceleration"
    gpu_opts="--device=/dev/dri:/dev/dri"
fi

print_status "🚀 Starting dk_ivi with full debug logging in Docker runtime..."
print_info "Runtime image: $RUNTIME_IMAGE"
print_info "All marketplace operations will be logged with detailed information"
print_info "Press Ctrl+C to stop the application"
print_info "================================================"

# Run dk_ivi in Docker runtime with debug logging enabled
docker run --rm -it \
    --network host \
    -e DISPLAY="$DISPLAY" \
    -e XDG_RUNTIME_DIR="$runtime_dir" \
    -e QT_LOGGING_RULES="$QT_LOGGING_RULES" \
    -e QT_FORCE_STDERR_LOGGING=1 \
    -e DK_USER="$DK_USER" \
    -e DK_EMBEDDED_MODE="$DK_EMBEDDED_MODE" \
    -e DK_MOCK_MODE="$DK_MOCK_MODE" \
    -e DK_CONTAINER_ROOT="$DK_CONTAINER_ROOT" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$runtime_dir:$runtime_dir" \
    $gpu_opts \
    -v /dev/shm:/dev/shm \
    -v $(pwd)/output:/app/exec:ro \
    -v /home/$DK_USER/.dk:/home/$DK_USER/.dk \
    -e LD_LIBRARY_PATH=/app/exec/library \
    -e QML_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt6/qml \
    -e QT_QUICK_BACKEND=software \
    $RUNTIME_IMAGE \
    /app/exec/dk_ivi