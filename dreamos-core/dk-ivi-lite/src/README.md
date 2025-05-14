# dk_ivi Application

This repository contains the dk_ivi application with two build options: a local Ubuntu build or a Docker-based build. Choose the method that best suits your requirements.

## Prerequisites

- Ubuntu 22.04 LTS (Jammy Jellyfish)
- At least 8GB RAM and 20GB free disk space
- Internet connection

## Build Options

### Option 1: Local Build on Ubuntu

The local build method installs all dependencies and builds Qt directly on your system.

#### Quick Start

1. Download the build script:
   ```bash
   chmod +x build_dk_ivi.sh
   ```

2. Run the script:
   ```bash
   ./build_dk_ivi.sh
   ```

3. Follow the on-screen prompts to complete the build process.

#### What the Script Does

- Installs all required build dependencies
- Downloads and builds Qt 6.9.0 with XCB support
- Sets up the environment variables
- Builds the dk_ivi application
- Creates an environment setup script for future use

#### Running the Application

After building:

```bash
# Set up the environment
source ~/setup-qt-env.sh

# Run the application
~/path/to/your/build/dk_ivi
```

### Option 2: Docker Build

The Docker method builds the application in a container, providing isolation from your system.

#### Building the Docker Image

1. Clean up old Docker resources (optional):
   ```bash
   # Stop and remove all containers
   docker stop $(docker ps -a -q)
   docker rm $(docker ps -a -q)

   # Remove old images
   docker rmi $(docker images -q) -f

   # Remove all volumes (optional)
   docker volume prune -f

   # Remove all build cache
   docker builder prune -f
   ```

2. Build the Docker image:
   ```bash
   docker build \
     --no-cache \
     -t qt-build-dk-ivi .
   ```

   If you're behind a proxy, use:
   ```bash
   docker build \
     --no-cache \
     --build-arg HTTP_PROXY=http://your-proxy:port \
     --build-arg HTTPS_PROXY=http://your-proxy:port \
     --build-arg http_proxy=http://your-proxy:port \
     --build-arg https_proxy=http://your-proxy:port \
     --network=host \
     -t qt-build-dk-ivi .
   ```

#### Running the Application with Docker

To run the application with X11 forwarding:

```bash
# Allow X connections on the host
xhost +local:docker

# Run the container with X11 forwarding
docker run -it --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  --device /dev/dri:/dev/dri \
  qt-build-dk-ivi
```

For interactive testing:

```bash
# Get a shell in the container
docker run -it --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  --device /dev/dri:/dev/dri \
  qt-build-dk-ivi /bin/bash

# Inside the container, run:
/usr/local/bin/x11-run /app/build/dk_ivi
```



## Performance Tips

- For faster local builds:
  ```bash
  # Use ccache
  sudo apt-get install ccache
  export PATH=/usr/lib/ccache:$PATH
  ```

- For faster Docker builds:
  ```bash
  # Use buildkit
  export DOCKER_BUILDKIT=1
  ```

## Notes

- The Qt build process may take 1-2 hours depending on your system.
- Building with Docker provides better isolation but may be slower than a native build.
- The local build uses your system's resources directly, which can be faster but modifies your system.
