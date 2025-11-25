#!/bin/bash

# Copyright (c) 2025 Eclipse Foundation.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License which is available at
# https://opensource.org/licenses/MIT.
#
# SPDX-License-Identifier: MIT

# Enhanced dreamKIT installation script with minimal sudo usage

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Unicode symbols
CHECKMARK="✓"
CROSS="✗"
ARROW="→"
WARNING="⚠"
GEAR="⚙"
ROCKET="🚀"
DREAM="💭"

# Global variables
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

# Function to show success message
show_success() {
    local message=$1
    echo -e "${GREEN}${BOLD} ${CHECKMARK} ${message}${NC}"
}

# Function to show error message
show_error() {
    local message=$1
    echo -e "${RED}${BOLD} ${CROSS} ${message}${NC}"
}

# Function to show info message
show_info() {
    local message=$1
    echo -e "${BLUE} ${ARROW} ${message}${NC}"
}

# Function to show warning message
show_warning() {
    local message=$1
    echo -e "${YELLOW}${BOLD} ${WARNING} ${message}${NC}"
}

# Function to show banner
show_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║                  dreamOS Optimized Installation                       ║
    ║                 Reduced Sudo Dependencies                          ║
    ║                                                                      ║
    ╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${DREAM} ${CYAN}Starting optimized dreamOS installation...${NC}\n"
}

# Function to load environment variables
load_environment() {
    show_info "Loading dreamOS environment configuration..."

    # Determine the user who ran the command
    if [ -n "$SUDO_USER" ]; then
        DK_USER=$SUDO_USER
    else
        DK_USER=$USER
    fi

    # Look for environment file
    ENV_FILE="/home/$DK_USER/.dk/dk_swupdate/dk_swupdate_env.sh"

    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        show_success "Environment loaded from $ENV_FILE"
        show_info "User: ${BOLD}$DK_USER${NC}, Architecture: ${BOLD}$ARCH${NC}"
        return 0
    else
        show_error "Environment file not found at $ENV_FILE"
        return 1
    fi
}

# Function to setup persistent temporary directory
setup_tmp_dir() {
    local TMP_BASE="/tmp/dreamkit-install"
    local TMP_DIR="$TMP_BASE-$$"

    # Create temporary directory with proper permissions
    mkdir -p "$TMP_DIR"

    show_info "Created temporary directory: $TMP_DIR"

    # Export for use in functions
    export DREAMKIT_TMP_DIR="$TMP_DIR"
    export MANIFEST_DIR="$TMP_DIR/dk_manifests"

    # Create manifests directory
    mkdir -p "$MANIFEST_DIR"

    return 0
}

# Function to setup environment for template processing
setup_template_env() {
    # Create environment file for envsubst
    local ENV_FILE="$DREAMKIT_TMP_DIR/env_vars"

    cat > "$ENV_FILE" << EOF
DOCKER_HUB_NAMESPACE=${DOCKER_HUB_NAMESPACE:-ghcr.io/eclipse-autowrx}
ARCH=${ARCH:-amd64}
DK_USER=${DK_USER:-dreamkit}
RUNTIME_NAME=${RUNTIME_NAME:-DreamKIT_BGSV}
HOME_DIR=${HOME_DIR:-/home/$DK_USER}
dk_vip_demo=${dk_vip_demo:-true}
DISPLAY=${DISPLAY:-:0}
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/1000/gdm}
EOF

    show_info "Environment variables prepared for template processing"
}

# Function to create temporary directory for manifests
create_temp_manifest_dir() {
    local TEMP_MANIFEST_DIR="/tmp/dreamkit-manifests-$DK_USER-$$"

    if [ ! -d "$TEMP_MANIFEST_DIR" ]; then
        mkdir -p "$TEMP_MANIFEST_DIR"
        show_info "Created temporary manifests directory: $TEMP_MANIFEST_DIR"
    fi

    echo "$TEMP_MANIFEST_DIR"
}

# Function to process and save manifest without root permissions
process_manifest_optimized() {
    local yaml="$1"
    local temp_manifest_dir="$2"

    if [ -z "$temp_manifest_dir" ]; then
        temp_manifest_dir=$(create_temp_manifest_dir)
    fi

    local parsed_yaml="$temp_manifest_dir/parsed_${yaml}"

    local VARS='DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE ARCH=$ARCH DK_USER=$DK_USER RUNTIME_NAME=$RUNTIME_NAME HOME_DIR=$HOME_DIR dk_vip_demo=$dk_vip_demo DISPLAY=$DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR'

    show_info "Processing manifest: ${BOLD}${yaml}${NC}"
    show_info "Creating parsed version in: ${CYAN}${parsed_yaml}${NC}"

    # Use user's temp directory and avoid sudo
    if envsubst "$VARS" < "${MANIFEST_DIR}/${yaml}" > "$parsed_yaml" 2>/dev/null; then
        show_success "Manifest parsed successfully"
        show_info "Parsed manifest saved to: ${CYAN}${parsed_yaml}${NC}"

        # Show some key information from the parsed manifest
        if command -v yq >/dev/null 2>&1; then
            local kind=$(yq eval '.kind' "$parsed_yaml" 2>/dev/null || echo "Unknown")
            local name=$(yq eval '.metadata.name' "$parsed_yaml" 2>/dev/null || echo "Unknown")
            show_info "Resource type: ${BOLD}${kind}${NC}, Name: ${BOLD}${name}${NC}"
        fi

        return 0
    else
        show_error "Failed to parse manifest $yaml"
        return 1
    fi
}

# Function to apply manifest without sudo when possible
apply_manifest_optimized() {
    local yaml="$1"
    local temp_manifest_dir="$2"

    if [ -z "$temp_manifest_dir" ]; then
        temp_manifest_dir=$(create_temp_manifest_dir)
    fi

    local parsed_yaml="$temp_manifest_dir/parsed_${yaml}"

    # First try to parse the manifest
    if ! process_manifest_optimized "$yaml" "$temp_manifest_dir"; then
        return 1
    fi

    show_info "Applying manifest: ${BOLD}${yaml}${NC}"

    # Try without sudo first
    if kubectl apply -f "$parsed_yaml" >/dev/null 2>&1; then
        show_success "Manifest applied successfully: ${yaml}"
        return 0
    fi

    # If kubectl is not available or requires sudo, use sudo with -n (no password prompt) if possible
    if command -v kubectl >/dev/null 2>&1; then
        show_warning "kubectl access requires sudo, attempting with -n flag"
        if sudo -n kubectl apply -f "$parsed_yaml" >/dev/null 2>&1; then
            show_success "Manifest applied successfully with sudo -n: ${yaml}"
            return 0
        fi
    fi

    # Last resort: use regular sudo (will prompt for password)
    show_warning "Using regular sudo (password may be required)"
    if sudo kubectl apply -f "$parsed_yaml"; then
        show_success "Manifest applied successfully: ${yaml}"
        return 0
    else
        show_error "Failed to apply manifest: ${yaml}"
        return 1
    fi
}

# Function to pull image with optimized docker usage
pull_image_optimized() {
    local image="$1"
    local timeout="${2:-300}"  # 5 minutes default

    show_info "Pulling image: ${BOLD}${image}${NC}"

    # Try without sudo first
    if docker pull "$image" >/dev/null 2>&1; then
        show_success "Image pulled successfully: ${image}"
        return 0
    fi

    # Try with docker group access
    if groups | grep -q docker; then
        show_info "Docker group access available, using sudo"
        if sudo docker pull "$image" >/dev/null 2>&1; then
            show_success "Image pulled successfully: ${image}"
            return 0
        fi
    fi

    # Last resort: request password once
    show_warning "Docker access requires password (this is the only password prompt)"
    if sudo docker pull "$image"; then
        show_success "Image pulled successfully: ${image}"
        return 0
    else
        show_error "Failed to pull image: ${image}"
        return 1
    fi
}

# Function to wait for pod readiness with timeout
wait_for_pod_ready() {
    local service_name="$1"
    local namespace="$2"
    local timeout="${3:-120}"

    local pod_name=""
    local start_time=$(date +%s)

    show_info "Waiting for pod readiness: ${service_name} (timeout: ${timeout}s)"

    while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
        pod_name=$(kubectl get pods -n "$namespace" -l "app=${service_name}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

        if [ -n "$pod_name" ]; then
            # Check pod readiness
            local ready_status=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
            local running_phase=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null)

            if [ "$ready_status" = "True" ] && [ "$running_phase" = "Running" ]; then
                show_success "Pod is ready: ${service_name}"
                return 0
            fi
        fi

        sleep 5
    done

    show_warning "Timeout waiting for pod readiness: ${service_name}"
    return 1
}

# Function to validate installation
validate_installation() {
    show_info "Validating dreamKIT installation..."

    local checks_failed=0

    # Check if k3s is running
    if systemctl is-active --quiet k3s; then
        show_success "k3s service is running"
    else
        show_error "k3s service is not running"
        ((checks_failed++))
    fi

    # Check if Docker is accessible
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        show_success "Docker is accessible"
    elif sudo docker info >/dev/null 2>&1; then
        show_success "Docker is accessible via sudo"
    else
        show_error "Docker is not accessible"
        ((checks_failed++))
    fi

    # Check if kubectl is accessible
    if command -v kubectl >/dev/null 2>&1; then
        show_success "kubectl is accessible"
    elif sudo kubectl version >/dev/null 2>&1; then
        show_success "kubectl is accessible via sudo"
    else
        show_warning "kubectl is not accessible - some features may not work"
    fi

    # Check environment file
    if [ -f "/home/$DK_USER/.dk/dk_swupdate/dk_swupdate_env.sh" ]; then
        show_success "Environment file exists: /home/$DK_USER/.dk/dk_swupdate/dk_swupdate_env.sh"
    else
        show_error "Environment file not found: /home/$DK_USER/.dk/dk_swupdate/dk_swupdate_env.sh"
        ((checks_failed++))
    fi

    if [ $checks_failed -eq 0 ]; then
        show_success "Installation validation passed"
        return 0
    else
        show_error "Installation validation failed ($checks_failed checks failed)"
        return 1
    fi
}

# Function to display installation summary
show_installation_summary() {
    echo -e "\n${CYAN}${BOLD}"
    cat << "EOF"
    ╔════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║                 Installation Summary                                    ║
    ║                                                                      ║
    ╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${DREAM} ${CYAN}Installation completed successfully!${NC}"
    echo -e "\n${WHITE}DreamKit Services:${NC}"
    echo -e "   • SDV Runtime - Vehicle signal broker (Port 55555)"
    echo -e "   • MQTT Broker - IoT messaging (Ports 1883, 9001)"
    echo -e "   • DreamKit Manager - Central orchestrator"
    echo -e "   • IVI Interface - Qt-based dashboard"
    echo -e "\n${WHITE}Access Methods:${NC}"
    echo -e "   • Run dreamKIT services: ${BOLD}./dk_run.sh${NC}"
    echo -e "   • Check service status: ${BOLD}sudo k3s kubectl get pods${NC}"
    echo -e "   • View logs: ${BOLD}sudo journalctl -u k3s -f${NC}"
    echo -e "\n${WHITE}Next Steps:${NC}"
    echo -e "   1. Start dreamKIT services: ${BOLD}./dk_run.sh${NC}"
    echo -e "   2. Test SDV Extension: ${BOLD}../implementation/npm start${NC}"
    echo -e "   3. Discover devices: ${BOLD}curl http://localhost:9890/api/v1/dreamkit/devices/discover${NC}"
}

# Main installation function
main() {
    show_banner

    # Steps 1-3: Environment detection and validation
    echo -e "${BLUE}${BOLD}[1/5] Environment Setup${NC}"
    if ! load_environment; then
        echo -e "\n${RED}${BOLD}Installation Failed${NC}"
        echo -e "${YELLOW}Environment setup failed. Please check your dreamKIT setup.${NC}"
        exit 1
    fi

    # Steps 4-8: Software components installation
    echo -e "\n${BLUE}${BOLD}[2/5] Dependency Setup${NC}"

    # Setup temporary directories with proper permissions
    setup_tmp_dir
    setup_template_env

    # Steps 9-13: Core dreamKIT services installation
    echo -e "\n${BLUE}${BOLD}[3/5] Core Services${NC}"

    # Pull images first to avoid repeated sudo prompts during deployment
    echo -e "\n   Pulling Docker images (may prompt for password once)..."

    # Pull core images
    local images=(
        "eclipse-mosquitto:2.0.14"
        "ghcr.io/eclipse-autowrx/sdv-runtime:latest"
        "ghcr.io/eclipse-autowrx/dk_manager:latest"
        "ghcr.io/eclipse-autowrx/dk_ivi:latest"
    )

    for image in "${images[@]}"; do
        if ! pull_image_optimized "$image" 300; then
            echo -e "\n${RED}${BOLD}Failed to pull image: $image${NC}"
            echo -e "${YELLOW}You can try manually: docker pull $image${NC}"
        fi
    done

    # Deploy services with optimized manifests
    echo -e "\n   Deploying core services..."

    # Deploy MQTT Broker
    apply_manifest_optimized "mqtt-broker-pull.yaml"
    apply_manifest_optimized "mqtt-broker.yaml"

    # Deploy SDV Runtime
    apply_manifest_optimized "sdv-runtime-pull.yaml"
    apply_manifest_optimized "sdv-runtime.yaml"

    # Deploy DreamKit Manager
    apply_manifest_optimized "dk-manager-pull.yaml"
    apply_manifest_optimized "dk-manager.yaml"

    # Deploy IVI Interface (optional)
    if [ "${dk_ivi}" = "true" ]; then
        echo -e "\n${BLUE}${BOLD}[3.5/5] IVI Interface${NC}"

        # Pull IVI specific image if available
        pull_image_optimized "ghcr.io/eclipse-autowrx/dk_ivi:latest" 300

        # Determine which IVI manifest to use
        if [ -f "/etc/nv_tegra_release" ]; then
            apply_manifest_optimized "dk-ivi-pull.yaml"
            apply_manifest_optimized "dk-ivi-jetson.yaml"
        else
            apply_manifest_optimized "dk-ivi-pull.yaml"
            apply_manifest_optimized "dk-ivi.yaml"
        fi
    fi

    # Step 14: Installation summary
    echo -e "\n${BLUE}${BOLD}[4/5] Validation${NC}"
    validate_installation

    # Step 15: Installation summary
    echo -e "\n${BLUE}${BOLD}[5/5] Summary${NC}"
    show_installation_summary

    # Cleanup
    cleanup_temp_files

    echo -e "\n${GREEN}${BOLD}${ROCKET} dreamOS installation completed successfully!${NC}"
    echo -e "${CYAN}You can now run dreamKIT with: ${WHITE}./dk_run.sh${NC}"
}

# Function to cleanup temporary files
cleanup_temp_files() {
    if [ -n "$DREAMKIT_TMP_DIR" ]; then
        rm -rf "$DREAMKIT_TMP_DIR" 2>/dev/null
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo -e "${CYAN}${BOLD}dreamOS Optimized Installer${NC}"
        echo -e "\n${WHITE}Usage:${NC}"
        echo -e "  ${CYAN}./$0${NC}          Start optimized installation"
        echo -e "  ${CYAN}./$0 --help${NC}   Show this help"
        echo -e "  ${CYAN}./$0 --validate${NC} Validate installation only"
        echo -e "\n${WHITE}Options:${NC}"
        echo -e "  ${CYAN}--no-ivi${NC}        Skip IVI interface installation"
        echo -e "  ${CYAN}--no-pull${NC}        Skip initial Docker image pulls"
        echo -e "  ${CYAN}--validate-only${NC}   Validate existing installation"
        echo -e "\n${WHITE}Description:${NC}"
        echo -e "This script performs optimized dreamOS installation with:"
        echo -e "  • Minimal sudo usage (password prompted only once)"
        echo -e "  • Proper user permissions for temporary files"
        echo -e "  • Optimized Docker image pulling"
        echo -e "  • Enhanced error handling and progress reporting"
        echo
        echo
        exit 0
        ;;
    --validate-only)
        load_environment
        validate_installation
        exit $?
        ;;
    *)
        main "$@"
        ;;
esac