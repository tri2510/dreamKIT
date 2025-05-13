# Building and Running dk_ivi on Ubuntu 22.04

This README provides instructions for manually building and running the dk_ivi application on Ubuntu 22.04, without using Docker.

## Prerequisites

### System Requirements
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- At least 8GB RAM and 20GB free disk space
- Internet connection

## Step 1: Install Required Dependencies

Open a terminal and run the following commands to install all required build dependencies:

```bash
# Update package lists
sudo apt-get update

# Add Ubuntu universe repository if not already enabled
sudo add-apt-repository universe

# Install build dependencies
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
```

## Step 2: Download and Extract Qt 6.9.0

```bash
# Create a directory for Qt
mkdir -p ~/qt-build
cd ~/qt-build

# Download Qt 6.9.0 source
wget https://download.qt.io/archive/qt/6.9/6.9.0/single/qt-everywhere-src-6.9.0.tar.xz

# Extract Qt (this may take a while)
tar xf qt-everywhere-src-6.9.0.tar.xz --use-compress-program="xz -T0"
```

## Step 3: Configure and Build Qt with XCB Support

```bash
# Change to Qt source directory
cd ~/qt-build/qt-everywhere-src-6.9.0

# Configure Qt with XCB support
./configure -opensource -confirm-license \
    -nomake examples \
    -nomake tests \
    -feature-xcb \
    -feature-xkbcommon \
    -feature-xkbcommon-x11 \
    -prefix /usr/local

# Build Qt (this will take significant time)
# You can use -j flag to specify number of cores to use, e.g., -j4 for 4 cores
cmake --build .

# Install Qt (requires sudo)
sudo cmake --install .
```

## Step 4: Set Up Environment Variables

Create a file named `setup-env.sh` in your home directory with the following content:

```bash
#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export QT_PLUGIN_PATH=/usr/local/plugins
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/local/plugins/platforms
export QT_QPA_PLATFORM=xcb
export XKB_CONFIG_ROOT=/usr/share/X11/xkb
```

Make the script executable and source it:

```bash
chmod +x ~/setup-env.sh
source ~/setup-env.sh
```

> Note: You may want to add these environment variables to your `~/.bashrc` file for permanent setup.

## Step 5: Build Your Application

```bash
# Clone or navigate to your application source
# Assuming your application source is in ~/app
cd ~/app

# Create and navigate to build directory
rm -rf build
mkdir build
cd build

# Configure your application
cmake .. \
    -DCMAKE_PREFIX_PATH=/usr/local \
    -DCMAKE_BUILD_TYPE=Release

# Build your application
cmake --build .
```

## Step 6: Run Your Application

```bash
# Make sure environment is set up
source ~/setup-env.sh

# Run your application
~/app/build/dk_ivi
```

## Troubleshooting

### XCB Plugin Issues

If you encounter XCB plugin issues, verify that the plugin was built correctly:

```bash
# Check if XCB plugin exists
find /usr/local -name "libqxcb.so"
```

If the plugin isn't found, ensure you've configured Qt with the correct XCB options.

### Qt Display Problems

If your application shows "Could not connect to display" errors:

1. Check that your X11 server is running:
   ```bash
   echo $DISPLAY
   ```

2. Try explicitly setting the display:
   ```bash
   export DISPLAY=:0
   ```

3. Verify XCB environment variables are set correctly:
   ```bash
   echo $QT_QPA_PLATFORM
   echo $QT_QPA_PLATFORM_PLUGIN_PATH
   echo $QT_PLUGIN_PATH
   ```

### Library Path Issues

If you get missing library errors:

```bash
# Update shared library cache
sudo ldconfig

# Check that Qt libraries are in the path
ldconfig -p | grep libQt
```

## Performance Optimization

For faster build times:

- Use multiple cores for building Qt and your application:
  ```bash
  cmake --build . -j$(nproc)
  ```

- Consider using ccache for faster rebuilds:
  ```bash
  sudo apt-get install ccache
  export PATH=/usr/lib/ccache:$PATH
  ```
