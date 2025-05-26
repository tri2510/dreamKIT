#!/bin/bash

# Ultra-fast build script using direct source mounting
# Supports both dk_ivi and dk-manager modules with enhanced GUI support

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[BUILD]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

BUILDER_IMAGE="dk-ivi-builder"
RUNTIME_IMAGE="dk-ivi-runtime"
ACTION=${1:-"build"}
TARGET=${2:-"dk_ivi"}

show_help() {
    echo "Usage: $0 [ACTION] [TARGET]"
    echo ""
    echo "Actions:"
    echo "  build     - Build the application (mounting src directly)"
    echo "  run       - Run the built application"
    echo "  clean     - Clean build cache and rebuild"
    echo "  shell     - Open development shell"
    echo "  runtime   - Open shell in runtime environment"
    echo "  images    - Build Docker images (one-time setup)"
    echo ""
    echo "Targets:"
    echo "  dk_ivi      - Build main dk_ivi application (default)"
    echo "  dk-manager  - Build dk-manager module"
    echo "  all         - Build both dk_ivi and dk-manager"
    echo ""
    echo "🚀 Ultra-fast workflow:"
    echo "  1. $0 images              # Build base images (once)"
    echo "  2. $0 build               # Build dk_ivi (~30 seconds)"
    echo "  3. $0 build dk-manager    # Build dk-manager"
    echo "  4. $0 build all           # Build both modules"
    echo "  5. Edit code..."
    echo "  6. $0 build               # Rebuild instantly!"
}

check_requirements() {
    if [ ! -d "src" ]; then
        print_error "src directory not found!"
        exit 1
    fi
    
    # Check for dk-manager if building it
    if [[ "$TARGET" == "dk-manager" || "$TARGET" == "all" ]]; then
        if [ ! -d "dk-manager/src" ]; then
            print_error "dk-manager/src directory not found!"
            print_info "Expected structure: dk-manager/src/CMakeLists.txt"
            exit 1
        fi
        if [ ! -f "dk-manager/src/CMakeLists.txt" ]; then
            print_error "dk-manager/src/CMakeLists.txt not found!"
            exit 1
        fi
        print_info "Found dk-manager module"
    fi
    
    # Enable Docker BuildKit
    export DOCKER_BUILDKIT=1
}

detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l) echo "arm" ;;
        *) echo "$arch" ;;
    esac
}

build_base_images() {
    local target_arch=$(detect_architecture)
    
    print_status "Building base Docker images (one-time setup)..."
    print_info "This takes 2-3 minutes but only needs to be done once or when dependencies change"
    
    # Build builder image
    print_info "Building builder image..."
    docker build \
        --network host \
        --build-arg HTTP_PROXY=http://127.0.0.1:3128 \
        --build-arg HTTPS_PROXY=http://127.0.0.1:3128 \
        --build-arg http_proxy=http://127.0.0.1:3128 \
        --build-arg https_proxy=http://127.0.0.1:3128 \
        --target builder \
        -f Dockerfile.mount \
        -t $BUILDER_IMAGE \
        .
    
    # Build runtime image  
    print_info "Building runtime image..."
    docker build \
        --network host \
        --build-arg HTTP_PROXY=http://127.0.0.1:3128 \
        --build-arg HTTPS_PROXY=http://127.0.0.1:3128 \
        --build-arg http_proxy=http://127.0.0.1:3128 \
        --build-arg https_proxy=http://127.0.0.1:3128 \
        --build-arg TARGETARCH=$target_arch \
        --target runtime \
        -f Dockerfile.mount \
        -t $RUNTIME_IMAGE \
        .
    
    print_status "✅ Base images built successfully!"
    print_info "Now you can use '$0 build' for ultra-fast builds!"
}

build_application() {
    # Check if base images exist
    if ! docker images $BUILDER_IMAGE | grep -q $BUILDER_IMAGE; then
        print_warning "Builder image not found. Building base images first..."
        build_base_images
    fi
    
    local target_arch=$(detect_architecture)
    
    case "$TARGET" in
        "dk_ivi")
            build_dk_ivi "$target_arch"
            ;;
        "dk-manager")
            build_dk_manager "$target_arch"
            ;;
        "all")
            build_dk_ivi "$target_arch"
            build_dk_manager "$target_arch"
            ;;
        *)
            print_error "Unknown target: $TARGET"
            print_info "Available targets: dk_ivi, dk-manager, all"
            exit 1
            ;;
    esac
}

build_dk_ivi() {
    local target_arch=$1
    
    print_status "Building dk_ivi application..."
    print_info "Source: $(pwd)/src"
    
    mkdir -p output
    
    docker run --rm \
        --network host \
        -e HTTP_PROXY=http://127.0.0.1:3128 \
        -e HTTPS_PROXY=http://127.0.0.1:3128 \
        -e http_proxy=http://127.0.0.1:3128 \
        -e https_proxy=http://127.0.0.1:3128 \
        -v $(pwd)/src:/app/src:ro \
        -v $(pwd)/output:/app/output \
        -v dk-ivi-build-cache:/app/build \
        -v dk-ivi-ccache:/cache/ccache \
        $BUILDER_IMAGE \
        bash -c "
            set -e
            echo '=== Building dk_ivi ==='
            cd /app/build
            
            if [ ! -f Makefile ] || [ /app/src/CMakeLists.txt -nt CMakeCache.txt ]; then
                echo 'Configuring dk_ivi with CMake (Unix Makefiles)...'
                cmake /app/src -G \"Unix Makefiles\" -DCMAKE_BUILD_TYPE=Release
            else
                echo 'Using existing dk_ivi configuration'
            fi
            
            echo 'Building dk_ivi with make...'
            make -j\$(nproc)
            
            echo 'Copying dk_ivi executable...'
            cp dk_ivi /app/output/
            
            if [ -d '/app/src/library/target/$target_arch' ]; then
                echo 'Copying dk_ivi libraries...'
                mkdir -p /app/output/library
                cp -r /app/src/library/target/$target_arch/* /app/output/library/
            fi
            
            echo '=== dk_ivi build completed ==='
            ccache -s || true
        "
    
    if [ -f "output/dk_ivi" ]; then
        print_status "✅ dk_ivi build successful!"
        print_info "Executable: $(pwd)/output/dk_ivi ($(ls -lh output/dk_ivi | awk '{print $5}'))"
    else
        print_error "❌ dk_ivi build failed!"
        exit 1
    fi
}

build_dk_manager() {
    local target_arch=$1
    
    print_status "Building dk-manager application (following Dockerfile pattern)..."
    print_info "Source: $(pwd)/dk-manager/src"
    
    mkdir -p output/dk-manager
    
    docker run --rm \
        --network host \
        -e HTTP_PROXY=http://127.0.0.1:3128 \
        -e HTTPS_PROXY=http://127.0.0.1:3128 \
        -e http_proxy=http://127.0.0.1:3128 \
        -e https_proxy=http://127.0.0.1:3128 \
        -v $(pwd)/dk-manager/src:/app/dk-manager-src:ro \
        -v $(pwd)/output/dk-manager:/app/dk-manager-output \
        -v dk-manager-build-cache:/app/dk-manager-build \
        -v dk-ivi-ccache:/cache/ccache \
        $BUILDER_IMAGE \
        bash -c "
            set -e
            echo '=== Building dk-manager (Dockerfile pattern) ==='
            
            # Disable ccache for dk-manager to avoid Qt MOC conflicts
            unset CC
            unset CXX
            export CC=gcc
            export CXX=g++
            
            cd /app
            
            # Check if socket.io-client-cpp is already built
            if [ ! -d socket.io-client-cpp/install ]; then
                echo 'Building socket.io-client-cpp dependency...'
                git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git
                cd socket.io-client-cpp
                mkdir -p build
                cd build
                cmake ..
                make -j4
                make install
                cd /app
                echo 'socket.io-client-cpp installed successfully'
            else
                echo 'socket.io-client-cpp already available'
            fi
            
            # Copy dk-manager source to build location
            echo 'Copying dk-manager source...'
            cp -r /app/dk-manager-src /app/dk-manager
            
            # Build dk-manager following Dockerfile pattern
            echo 'Building dk-manager...'
            cd /app/dk-manager
            mkdir -p build
            cd build
            
            echo 'Configuring dk-manager with CMake...'
            cmake .. -DCMAKE_BUILD_TYPE=Release
            
            echo 'Building dk-manager with make...'
            make -j4
            
            echo 'Build completed, checking outputs...'
            ls -la .
            
            # Copy dk-manager outputs
            echo 'Copying dk-manager build outputs...'
            exe_count=0
            
            # Copy the main executable if it exists
            if [ -f dk_manager ]; then
                echo 'Found dk_manager executable'
                cp dk_manager /app/dk-manager-output/
                exe_count=\$((exe_count + 1))
            fi
            
            # Copy any other executables
            for file in \$(find . -maxdepth 1 -type f -executable ! -name '*.so*' 2>/dev/null); do
                if [ \"\$(basename \$file)\" != \"dk_manager\" ]; then
                    echo \"Copying additional executable: \$file\"
                    cp \"\$file\" /app/dk-manager-output/
                    exe_count=\$((exe_count + 1))
                fi
            done
            
            # Also check for common names
            for file in dk-manager manager; do
                if [ -f \"\$file\" ]; then
                    echo \"Found and copying \$file\"
                    cp \"\$file\" /app/dk-manager-output/
                    exe_count=\$((exe_count + 1))
                fi
            done
            
            echo \"Total executables copied: \$exe_count\"
            
            # If no executables found, list what was built
            if [ \$exe_count -eq 0 ]; then
                echo 'No executables found. Build artifacts:'
                find . -type f -name '*' | head -20
            fi
            
            # List final outputs
            echo 'Final dk-manager outputs:'
            ls -la /app/dk-manager-output/ || echo 'No outputs found'
            
            echo '=== dk-manager build completed ==='
        "
    
    # Check if anything was built
    if [ -d "output/dk-manager" ] && [ "$(ls -A output/dk-manager/ 2>/dev/null)" ]; then
        print_status "✅ dk-manager build successful!"
        print_info "Outputs in: $(pwd)/output/dk-manager/"
        ls -lh output/dk-manager/ | grep -v "^total" | while read line; do
            print_info "  $line"
        done
    else
        print_warning "⚠️  dk-manager build completed but no executables found"
        print_info "Check the build logs above for details"
        print_info "This may be normal if the CMakeLists.txt only builds libraries"
    fi
}

run_application() {
    if [ ! -f "output/dk_ivi" ]; then
        print_warning "dk_ivi not built. Building first..."
        TARGET="dk_ivi"
        build_application
    fi
    
    if ! docker images $RUNTIME_IMAGE | grep -q $RUNTIME_IMAGE; then
        print_warning "Runtime image not found. Building base images first..."
        build_base_images
    fi
    
    print_status "Running dk_ivi application..."
    
    # Set up X11 forwarding and runtime environment
    local runtime_dir="/run/user/$(id -u)"
    
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
    
    docker run --rm -it \
        --network host \
        -e DISPLAY="$DISPLAY" \
        -e XDG_RUNTIME_DIR="$runtime_dir" \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v "$runtime_dir:$runtime_dir" \
        $gpu_opts \
        -v /dev/shm:/dev/shm \
        -v $(pwd)/output:/app/exec:ro \
        -e LD_LIBRARY_PATH=/app/exec/library \
        -e QML_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt6/qml \
        -e QT_QUICK_BACKEND=software \
        $RUNTIME_IMAGE \
        /app/exec/dk_ivi
}

open_dev_shell() {
    if ! docker images $BUILDER_IMAGE | grep -q $BUILDER_IMAGE; then
        print_warning "Builder image not found. Building base images first..."
        build_base_images
    fi
    
    print_status "Opening development shell..."
    
    docker run --rm -it \
        --network host \
        -e HTTP_PROXY=http://127.0.0.1:3128 \
        -e HTTPS_PROXY=http://127.0.0.1:3128 \
        -e http_proxy=http://127.0.0.1:3128 \
        -e https_proxy=http://127.0.0.1:3128 \
        -v $(pwd)/src:/app/src \
        -v $(pwd)/dk-manager:/app/dk-manager \
        -v $(pwd)/output:/app/output \
        -v dk-ivi-build-cache:/app/build \
        -v dk-manager-build-cache:/app/dk-manager-build \
        -v dk-ivi-ccache:/cache/ccache \
        $BUILDER_IMAGE
}

open_runtime_shell() {
    if ! docker images $RUNTIME_IMAGE | grep -q $RUNTIME_IMAGE; then
        print_warning "Runtime image not found. Building base images first..."
        build_base_images
    fi
    
    print_status "Opening runtime shell..."
    
    docker run --rm -it \
        --network host \
        -e DISPLAY=$DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v $(pwd)/output:/app/exec \
        -e LD_LIBRARY_PATH=/app/exec/library \
        -e QML_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt6/qml \
        $RUNTIME_IMAGE
}

clean_build() {
    print_warning "Cleaning build cache for target: $TARGET"
    
    case "$TARGET" in
        "dk_ivi")
            docker volume rm dk-ivi-build-cache 2>/dev/null || true
            rm -rf output/dk_ivi output/library
            print_status "dk_ivi cache cleaned"
            ;;
        "dk-manager")
            docker volume rm dk-manager-build-cache 2>/dev/null || true
            rm -rf output/dk-manager
            print_status "dk-manager cache cleaned"
            ;;
        "all")
            docker volume rm dk-ivi-build-cache 2>/dev/null || true
            docker volume rm dk-manager-build-cache 2>/dev/null || true
            docker volume rm dk-ivi-ccache 2>/dev/null || true
            rm -rf output
            print_status "All caches cleaned"
            ;;
        *)
            print_warning "Unknown target for clean: $TARGET"
            print_info "Cleaning all caches..."
            docker volume rm dk-ivi-build-cache 2>/dev/null || true
            docker volume rm dk-manager-build-cache 2>/dev/null || true
            docker volume rm dk-ivi-ccache 2>/dev/null || true
            rm -rf output
            ;;
    esac
}

show_status() {
    print_info "=== Build Environment Status ==="
    echo "Builder image: $(docker images $BUILDER_IMAGE --format "{{.CreatedSince}} ({{.Size}})" 2>/dev/null || echo "❌ Not built")"
    echo "Runtime image: $(docker images $RUNTIME_IMAGE --format "{{.CreatedSince}} ({{.Size}})" 2>/dev/null || echo "❌ Not built")"
    
    echo ""
    print_info "=== Built Applications ==="
    echo "dk_ivi: $([ -f "output/dk_ivi" ] && echo "✅ $(ls -lh output/dk_ivi | awk '{print $5}')" || echo "❌ Not built")"
    
    if [ -d "output/dk-manager" ] && [ "$(ls -A output/dk-manager/ 2>/dev/null)" ]; then
        echo "dk-manager: ✅ $(ls output/dk-manager/ 2>/dev/null | wc -l) files"
        ls output/dk-manager/ 2>/dev/null | sed 's/^/  - /'
    else
        echo "dk-manager: ❌ Not built"
    fi
    
    echo ""
    print_info "=== Build Caches ==="
    echo "dk_ivi cache: $(docker volume inspect dk-ivi-build-cache >/dev/null 2>&1 && echo "✅ Available" || echo "❌ Not created")"
    echo "dk-manager cache: $(docker volume inspect dk-manager-build-cache >/dev/null 2>&1 && echo "✅ Available" || echo "❌ Not created")"
    echo "Compile cache: $(docker volume inspect dk-ivi-ccache >/dev/null 2>&1 && echo "✅ Available" || echo "❌ Not created")"
    
    echo ""
    print_info "=== Source Directories ==="
    if [ -d "src" ]; then
        echo "dk_ivi source: ✅ $(find src -name "*.cpp" -o -name "*.h" 2>/dev/null | wc -l) source files"
    else
        echo "dk_ivi source: ❌ Not found"
    fi
    
    if [ -d "dk-manager/src" ]; then
        echo "dk-manager source: ✅ $(find dk-manager/src -name "*.cpp" -o -name "*.h" 2>/dev/null | wc -l) source files"
        echo "dk-manager CMake: $([ -f "dk-manager/src/CMakeLists.txt" ] && echo "✅ Found" || echo "❌ Missing")"
    else
        echo "dk-manager source: ❌ Not found"
    fi
}

# Main execution
case $ACTION in
    "help"|"-h"|"--help")
        show_help
        ;;
    "images")
        check_requirements
        build_base_images
        ;;
    "build")
        check_requirements
        build_application
        ;;
    "run")
        check_requirements
        run_application
        ;;
    "clean")
        clean_build
        ;;
    "shell")
        check_requirements
        open_dev_shell
        ;;
    "runtime")
        check_requirements
        open_runtime_shell
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac

print_status "Script completed!"