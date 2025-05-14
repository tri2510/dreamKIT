#!/bin/bash
#
# build_dk_ivi.sh - Automated build script for dk_ivi on Ubuntu 22.04
#
# This script automates the process of installing dependencies,
# downloading and building Qt 6.9.0, and building the dk_ivi application.
#

set -e  # Exit on any error

# ANSI color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
QT_VERSION="6.9.0"
QT_SOURCE="qt-everywhere-src-${QT_VERSION}.tar.xz"
QT_DIR="qt-everywhere-src-${QT_VERSION}"
BUILD_DIR="$HOME/dk_ivi_build"
APP_SOURCE_DIR="$PWD"
CORES=$(nproc)

# Print header
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   dk_ivi Build Script for Ubuntu 22.04    ${NC}"
echo -e "${BLUE}============================================${NC}"

# Function to print section headers
section() {
    echo -e "\n${GREEN}>> $1${NC}"
}

# Function to prompt for confirmation
confirm() {
    read -p "$1 [Y/n] " response
    case "$response" in
        [nN][oO]|[nN]) 
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}Error: This script should not be run as root${NC}"
    echo "Please run without sudo, the script will prompt for sudo password when needed."
    exit 1
fi

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Install dependencies
section "Installing build dependencies"
if confirm "Do you want to install build dependencies?"; then
    echo "Updating package lists..."
    sudo apt-get update
    
    echo "Adding universe repository..."
    sudo add-apt-repository universe -y
    
    echo "Installing required packages..."
    sudo apt-get install -y \
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
        libxcb-cursor0 \
        libxcb-cursor-dev \
        libgtk-3-dev \
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
        xz-utils
    
    echo -e "${GREEN}Dependencies installed successfully!${NC}"
else
    echo "Skipping dependency installation..."
fi

# Download Qt
section "Downloading Qt $QT_VERSION"
if [ -f "$QT_SOURCE" ]; then
    echo -e "${YELLOW}Qt source archive already exists.${NC}"
    if confirm "Do you want to use the existing archive?"; then
        echo "Using existing Qt source archive."
    else
        echo "Downloading Qt source..."
        wget -q --show-progress -O "$QT_SOURCE" "https://download.qt.io/archive/qt/6.9/$QT_VERSION/single/$QT_SOURCE"
    fi
else
    echo "Downloading Qt source..."
    wget -q --show-progress -O "$QT_SOURCE" "https://download.qt.io/archive/qt/6.9/$QT_VERSION/single/$QT_SOURCE"
fi

# Extract Qt
section "Extracting Qt source"
if [ -d "$QT_DIR" ]; then
    echo -e "${YELLOW}Qt source directory already exists.${NC}"
    if confirm "Do you want to re-extract Qt source?"; then
        echo "Re-extracting Qt source..."
        rm -rf "$QT_DIR"
        tar xf "$QT_SOURCE" --use-compress-program="xz -T0"
    fi
else
    echo "Extracting Qt source (this may take a while)..."
    tar xf "$QT_SOURCE" --use-compress-program="xz -T0"
fi

# Configure and build Qt
section "Building Qt with XCB support"
cd "$BUILD_DIR/$QT_DIR"

if [ ! -f "CMakeCache.txt" ]; then
    echo "Configuring Qt..."
    ./configure -opensource -confirm-license \
        -nomake examples \
        -nomake tests \
        -feature-xcb \
        -feature-xkbcommon \
        -feature-xkbcommon-x11 \
        -prefix /usr/local
else
    echo -e "${YELLOW}Qt already configured.${NC}"
    if confirm "Do you want to reconfigure Qt?"; then
        echo "Reconfiguring Qt..."
        ./configure -opensource -confirm-license \
            -nomake examples \
            -nomake tests \
            -feature-xcb \
            -feature-xkbcommon \
            -feature-xkbcommon-x11 \
            -prefix /usr/local
    fi
fi

echo "Building Qt (using $CORES cores, this will take a while)..."
cmake --build . -j$CORES

echo "Installing Qt (requires sudo)..."
sudo cmake --install .

# Verify XCB plugin was built
section "Verifying XCB plugin"
XCB_PLUGIN=$(find /usr/local -name "libqxcb.so")
if [ -n "$XCB_PLUGIN" ]; then
    echo -e "${GREEN}XCB plugin found at: $XCB_PLUGIN${NC}"
else
    echo -e "${RED}Warning: XCB plugin not found! Qt may not work with X11.${NC}"
fi

# Create environment setup script
section "Creating environment setup script"
ENV_SCRIPT="$HOME/setup-qt-env.sh"

cat > "$ENV_SCRIPT" << 'EOF'
#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export QT_PLUGIN_PATH=/usr/local/plugins
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/local/plugins/platforms
export QT_QPA_PLATFORM=xcb
export XKB_CONFIG_ROOT=/usr/share/X11/xkb
EOF

chmod +x "$ENV_SCRIPT"
echo -e "${GREEN}Environment script created at: $ENV_SCRIPT${NC}"

# Source the environment script
source "$ENV_SCRIPT"

# Build the application
section "Building dk_ivi application"
cd "$APP_SOURCE_DIR"
echo "Current directory: $PWD"

# Clean and create build directory
rm -rf build
mkdir -p build
cd build

# Configure the application
echo "Configuring the application..."
cmake .. \
    -DCMAKE_PREFIX_PATH=/usr/local \
    -DCMAKE_BUILD_TYPE=Release

# Build the application
echo "Building the application (using $CORES cores)..."
cmake --build . -j$CORES

# Display final instructions
section "Build Complete"
echo -e "${GREEN}dk_ivi has been successfully built!${NC}"
echo
echo -e "${YELLOW}To run the application:${NC}"
echo "1. Source the environment script:"
echo "   source $ENV_SCRIPT"
echo
echo "2. Run the application:"
echo "   $APP_SOURCE_DIR/build/dk_ivi"
echo
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Build process completed successfully!    ${NC}"
echo -e "${BLUE}============================================${NC}"

# Offer to run the application
if confirm "Do you want to run dk_ivi now?"; then
    echo "Running dk_ivi..."
    "$APP_SOURCE_DIR/build/dk_ivi"
fi