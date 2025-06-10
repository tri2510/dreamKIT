#!/bin/bash

# Enhanced DreamKIT IVI Builder
# Builds the new enhanced dk_ivi image with embedded services

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[BUILD]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║                Enhanced DreamKIT IVI Builder                         ║
    ║                    Version 2.0 - Embedded Services                   ║
    ║                                                                      ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TYPE="${1:-release}"
REPO_OWNER="${REPO_OWNER:-tri2510}"
ARCH="$(uname -m)"

# Enhanced image naming to distinguish from original
ENHANCED_IMAGE_NAME="dk-ivi-enhanced"
BUILDER_IMAGE="ghcr.io/${REPO_OWNER}/dk-ivi-builder:latest"
RUNTIME_IMAGE="ghcr.io/${REPO_OWNER}/dk-ivi-runtime:latest"
TARGET_IMAGE="ghcr.io/${REPO_OWNER}/${ENHANCED_IMAGE_NAME}:latest"

show_banner

print_info "Enhanced DreamKIT IVI Build Configuration"
print_info "=========================================="
print_info "Script Directory: $SCRIPT_DIR"
print_info "Build Type: $BUILD_TYPE"
print_info "Architecture: $ARCH"
print_info "Repository: $REPO_OWNER"
print_info "Enhanced Image: $TARGET_IMAGE"
print_info "Builder Image: $BUILDER_IMAGE"
print_info "Runtime Image: $RUNTIME_IMAGE"
echo

# Function to check Docker availability
check_docker() {
    print_info "Checking Docker availability..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running or not accessible"
        exit 1
    fi
    
    print_status "Docker is available and running"
}

# Function to check base images
check_base_images() {
    print_info "Checking required base images..."
    
    local missing_images=()
    
    for image in "$BUILDER_IMAGE" "$RUNTIME_IMAGE"; do
        if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
            print_status "Found: $image"
        else
            print_warning "Missing: $image"
            missing_images+=("$image")
        fi
    done
    
    if [ ${#missing_images[@]} -gt 0 ]; then
        print_info "Pulling missing base images..."
        for image in "${missing_images[@]}"; do
            print_info "Pulling $image..."
            if docker pull "$image"; then
                print_status "Successfully pulled: $image"
            else
                print_error "Failed to pull: $image"
                print_info "Please ensure the base images are available or build them first:"
                print_info "  ./build_optimized.sh images"
                exit 1
            fi
        done
    fi
}

# Function to validate source files
validate_sources() {
    print_info "Validating source files for enhanced build..."
    
    local required_dirs=(
        "src"
        "dk-manager/src"
        "dk_appinstallservice"
        "tools/scripts"
    )
    
    local missing_dirs=()
    local project_root="$SCRIPT_DIR/.."
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$project_root/$dir" ]; then
            print_status "Found: $dir/"
        else
            print_warning "Missing: $dir/"
            missing_dirs+=("$dir")
        fi
    done
    
    if [ ${#missing_dirs[@]} -gt 0 ]; then
        print_error "Missing required directories for enhanced build:"
        for dir in "${missing_dirs[@]}"; do
            print_error "  - $dir"
        done
        exit 1
    fi
    
    # Check for essential files
    local required_files=(
        "build/Dockerfile.enhanced"
        "src/main/main.cpp"
        "dk-manager/src/main.cpp"
        "dk_appinstallservice/scripts/main.py"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$project_root/$file" ]; then
            print_status "Found: $file"
        else
            print_error "Missing required file: $file"
            exit 1
        fi
    done
}

# Function to build enhanced image
build_enhanced_image() {
    print_info "Building enhanced DreamKIT IVI image..."
    print_info "This may take several minutes..."
    echo
    
    # Set build context
    cd "$SCRIPT_DIR/.."
    
    # Build arguments
    local build_args=(
        "--file" "build/Dockerfile.enhanced"
        "--tag" "$TARGET_IMAGE"
        "--build-arg" "BUILD_TYPE=$BUILD_TYPE"
        "--build-arg" "ARCH=$ARCH"
        "--build-arg" "REPO_OWNER=$REPO_OWNER"
    )
    
    # Add platform-specific arguments for multi-arch support
    case "$ARCH" in
        "x86_64")
            build_args+=("--platform" "linux/amd64")
            ;;
        "aarch64")
            build_args+=("--platform" "linux/arm64")
            ;;
    esac
    
    print_info "Build command: docker build ${build_args[*]} ."
    echo
    
    # Execute build
    if docker build "${build_args[@]}" .; then
        print_status "Successfully built enhanced image: $TARGET_IMAGE"
    else
        print_error "Failed to build enhanced image"
        exit 1
    fi
}

# Function to verify enhanced image
verify_enhanced_image() {
    print_info "Verifying enhanced image functionality..."
    
    # Check if image exists
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$TARGET_IMAGE$"; then
        print_error "Enhanced image not found after build"
        exit 1
    fi
    
    # Get image info
    local image_id=$(docker images --format "{{.ID}}" "$TARGET_IMAGE")
    local image_size=$(docker images --format "{{.Size}}" "$TARGET_IMAGE")
    
    print_status "Enhanced image verification:"
    print_info "  Image ID: $image_id"
    print_info "  Image Size: $image_size"
    
    # Test container creation (dry run)
    print_info "Testing enhanced container creation..."
    if docker create --name "test-enhanced-dk-ivi" "$TARGET_IMAGE" >/dev/null 2>&1; then
        print_status "Enhanced container creation test passed"
        docker rm "test-enhanced-dk-ivi" >/dev/null 2>&1
    else
        print_error "Enhanced container creation test failed"
        exit 1
    fi
}

# Function to show usage information
show_usage() {
    echo -e "${CYAN}Enhanced DreamKIT IVI Builder${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ${GREEN}./build_enhanced.sh${NC} [BUILD_TYPE]"
    echo
    echo -e "${YELLOW}Build Types:${NC}"
    echo -e "  ${BLUE}release${NC}     Production build with optimizations (default)"
    echo -e "  ${BLUE}debug${NC}       Development build with debug symbols"
    echo
    echo -e "${YELLOW}Environment Variables:${NC}"
    echo -e "  ${BLUE}REPO_OWNER${NC}  Repository owner (default: tri2510)"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}./build_enhanced.sh${NC}                    # Build release version"
    echo -e "  ${GREEN}./build_enhanced.sh debug${NC}              # Build debug version"
    echo -e "  ${GREEN}REPO_OWNER=myorg ./build_enhanced.sh${NC}   # Build with custom repo"
    echo
    echo -e "${YELLOW}Enhanced Features:${NC}"
    echo -e "  ${BLUE}•${NC} Embedded dk_manager (no separate container)"
    echo -e "  ${BLUE}•${NC} Integrated app install service"
    echo -e "  ${BLUE}•${NC} Supervisor-managed services"
    echo -e "  ${BLUE}•${NC} Enhanced health monitoring"
    echo -e "  ${BLUE}•${NC} Optimized resource usage"
    echo
}

# Function to clean up previous builds
cleanup_previous() {
    print_info "Cleaning up previous enhanced builds..."
    
    # Remove existing enhanced containers
    if docker ps -a --format "{{.Names}}" | grep -q "enhanced"; then
        print_info "Removing existing enhanced containers..."
        docker ps -a --filter "name=enhanced" -q | xargs -r docker rm -f
    fi
    
    # Clean up build cache for enhanced image
    print_info "Cleaning Docker build cache..."
    docker builder prune -f >/dev/null 2>&1 || true
    
    print_status "Cleanup completed"
}

# Function to tag additional versions
tag_additional_versions() {
    print_info "Creating additional image tags..."
    
    # Tag with version
    local version_tag="ghcr.io/${REPO_OWNER}/${ENHANCED_IMAGE_NAME}:v2.0-enhanced"
    docker tag "$TARGET_IMAGE" "$version_tag"
    print_status "Tagged: $version_tag"
    
    # Tag with architecture
    local arch_tag="ghcr.io/${REPO_OWNER}/${ENHANCED_IMAGE_NAME}:latest-${ARCH}"
    docker tag "$TARGET_IMAGE" "$arch_tag"
    print_status "Tagged: $arch_tag"
    
    # Tag with build type
    local build_tag="ghcr.io/${REPO_OWNER}/${ENHANCED_IMAGE_NAME}:${BUILD_TYPE}"
    docker tag "$TARGET_IMAGE" "$build_tag"
    print_status "Tagged: $build_tag"
}

# Main execution
main() {
    case "${1:-}" in
        "--help"|"-h")
            show_usage
            exit 0
            ;;
        "clean")
            cleanup_previous
            exit 0
            ;;
    esac
    
    print_status "Starting enhanced DreamKIT IVI build process..."
    
    # Execute build steps
    check_docker
    check_base_images
    validate_sources
    cleanup_previous
    build_enhanced_image
    verify_enhanced_image
    tag_additional_versions
    
    # Build summary
    echo
    print_status "🎉 Enhanced DreamKIT IVI build completed successfully!"
    echo
    print_info "Enhanced Image Information:"
    print_info "  Name: $TARGET_IMAGE"
    print_info "  Features: Embedded services, integrated management"
    print_info "  Architecture: $ARCH"
    print_info "  Build Type: $BUILD_TYPE"
    echo
    print_info "Available Tags:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep "$ENHANCED_IMAGE_NAME" | head -5
    echo
    print_info "Quick Start:"
    print_info "  docker run -it --rm $TARGET_IMAGE"
    echo
    print_info "Production Deployment:"
    print_info "  Use updated dk_install.sh and dk_run.sh scripts"
    print_info "  Image will be automatically pulled and configured"
    echo
}

# Execute main function with all arguments
main "$@"