#!/bin/bash
# Copyright (c) 2025 Eclipse Foundation.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License which is available at
# https://opensource.org/licenses/MIT.
#
# SPDX-License-Identifier: MIT

# Separate K3s installation script for dreamKIT
# This script installs K3s with proper sudo handling
# Usage: sudo ./install_k3s_separately.sh

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

# Utility functions
show_info() {
    local message=$1
    echo -e "${BLUE} ${ARROW} ${message}${NC}"
}

show_success() {
    local message=$1
    echo -e "${GREEN}${BOLD} ${CHECKMARK} ${message}${NC}"
}

show_error() {
    local message=$1
    echo -e "${RED}${BOLD} ${CROSS} ${message}${NC}"
}

show_warning() {
    local message=$1
    echo -e "${YELLOW}${BOLD} ⚠ ${message}${NC}"
}

run_with_feedback() {
    local command=$1
    local success_msg=$2
    local error_msg=$3
    local show_output=${4:-false}

    if [ "$show_output" = "true" ]; then
        echo -e "${DIM}${CYAN}Running: $command${NC}"
        if eval "$command"; then
            show_success "$success_msg"
            return 0
        else
            show_error "$error_msg"
            return 1
        fi
    else
        eval "$command" >/dev/null 2>&1
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            show_success "$success_msg"
            return 0
        else
            show_error "$error_msg"
            return 1
        fi
    fi
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_error "This script requires sudo privileges to install K3s"
        echo -e "${YELLOW}Usage: sudo $0${NC}"
        exit 1
    fi
}

# Install K3s with Docker integration
install_k3s() {
    show_info "Installing K3s with Docker integration..."

    # Install K3s with Docker as container runtime
    run_with_feedback \
        "curl -sfL https://get.k3s.io | sh -s - --docker" \
        "K3s installed successfully with Docker runtime" \
        "Failed to install K3s" \
        true

    if [ $? -eq 0 ]; then
        # Enable K3s service
        run_with_feedback \
            "systemctl enable --now k3s" \
            "K3s service enabled and started" \
            "Failed to enable K3s service"

        # Wait for K3s to be ready
        show_info "Waiting for K3s to become ready..."
        local retry_count=0
        local max_retries=30

        while [ $retry_count -lt $max_retries ]; do
            if kubectl get nodes >/dev/null 2>&1; then
                show_success "K3s is ready and responding"
                break
            fi

            if [ $retry_count -eq 0 ]; then
                echo -n "Waiting for K3s to initialize"
            else
                echo -n "."
            fi

            sleep 2
            ((retry_count++))
        done

        if [ $retry_count -eq $max_retries ]; then
            show_error "K3s failed to become ready after 60 seconds"
            return 1
        else
            echo
        fi

        return 0
    else
        return 1
    fi
}

# Configure K3s for dreamKIT
configure_k3s() {
    show_info "Configuring K3s for dreamKIT..."

    # Create dreamKIT namespace
    run_with_feedback \
        "kubectl create namespace dreamkit --dry-run=client -o yaml | kubectl apply -f -" \
        "dreamKIT namespace created" \
        "Failed to create dreamKIT namespace"

    # Set up Kubeconfig for the user
    local user_home="/home/$SUDO_USER"
    if [ -z "$SUDO_USER" ]; then
        user_home="$HOME"
    fi

    show_info "Setting up Kubeconfig for user..."

    # Create .kube directory if it doesn't exist
    mkdir -p "$user_home/.kube"

    # Copy K3s kubeconfig to user's directory
    if [ -f "/etc/rancher/k3s/k3s.yaml" ]; then
        run_with_feedback \
            "cp /etc/rancher/k3s/k3s.yaml \"$user_home/.kube/config\" && \
             chmod 600 \"$user_home/.kube/config\" && \
             chown $SUDO_USER:$SUDO_USER \"$user_home/.kube/config\" && \
             sed -i 's/127.0.0.1/$(hostname -I | awk '{print $1}')/g' \"$user_home/.kube/config\"" \
            "Kubeconfig configured for user" \
            "Failed to configure kubeconfig"

        # Set KUBECONFIG environment variable in user's .bashrc
        if ! grep -q "export KUBECONFIG" "$user_home/.bashrc"; then
            echo "export KUBECONFIG=\"$user_home/.kube/config\"" >> "$user_home/.bashrc"
            show_success "Added KUBECONFIG to .bashrc"
        fi
    else
        show_warning "K3s kubeconfig not found at /etc/rancher/k3s/k3s.yaml"
    fi
}

# Install additional K3s tools
install_k3s_tools() {
    show_info "Installing K3s management tools..."

    # Check if kubectl is available
    if ! command -v kubectl >/dev/null 2>&1; then
        show_warning "kubectl not found, installing..."
        run_with_feedback \
            "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\" && \
             install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl" \
            "kubectl installed successfully" \
            "Failed to install kubectl"
    fi

    # Install helm if not present
    if ! command -v helm >/dev/null 2>&1; then
        show_info "Installing Helm..."
        run_with_feedback \
            "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash" \
            "Helm installed successfully" \
            "Failed to install Helm"
    fi
}

# Show K3s status
show_k3s_status() {
    echo
    show_success "K3s Installation Summary:"
    echo

    # Service status
    echo -e "${BLUE}Service Status:${NC}"
    systemctl is-active k3s && echo -e "  ${GREEN}${CHECKMARK} k3s service is running${NC}" || echo -e "  ${RED}${CROSS} k3s service is not running${NC}"
    systemctl is-enabled k3s && echo -e "  ${GREEN}${CHECKMARK} k3s service is enabled${NC}" || echo -e "  ${RED}${CROSS} k3s service is not enabled${NC}"
    echo

    # Node status
    if command -v kubectl >/dev/null 2>&1; then
        echo -e "${BLUE}Kubernetes Cluster Status:${NC}"
        if kubectl get nodes >/dev/null 2>&1; then
            echo -e "  ${GREEN}${CHECKMARK} Kubernetes cluster is accessible${NC}"
            echo -e "  ${DIM}Nodes:$(kubectl get nodes -o name)${NC}"
        else
            echo -e "  ${RED}${CROSS} Kubernetes cluster is not accessible${NC}"
        fi
        echo
    fi

    # Tool availability
    echo -e "${BLUE}Management Tools:${NC}"
    command -v kubectl >/dev/null 2>&1 && echo -e "  ${GREEN}${CHECKMARK} kubectl: $(kubectl version --client --short 2>/dev/null | head -1)${NC}" || echo -e "  ${RED}${CROSS} kubectl: not found${NC}"
    command -v helm >/dev/null 2>&1 && echo -e "  ${GREEN}${CHECKMARK} helm: $(helm version --short 2>/dev/null)${NC}" || echo -e "  ${RED}${CROSS} helm: not found${NC}"
    echo

    # Next steps
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "  1. ${GREEN}Log out and log back in${NC} to apply group changes"
    echo -e "  2. Run ${YELLOW}source ~/.bashrc${NC} to set up KUBECONFIG"
    echo -e "  3. Use ${YELLOW}kubectl get nodes${NC} to verify cluster access"
    echo -e "  4. Continue with dreamKIT installation steps that require K3s"
    echo
}

# Main function
main() {
    echo -e "${BLUE}${BOLD}dreamKIT K3s Installation${NC}"
    echo -e "${DIM}Installing K3s Kubernetes distribution with Docker integration...${NC}"
    echo

    # Check for root privileges
    check_root

    # Install K3s
    if install_k3s; then
        # Configure K3s
        configure_k3s

        # Install additional tools
        install_k3s_tools

        # Show status
        show_k3s_status

        show_success "K3s installation completed successfully!"
    else
        show_error "K3s installation failed!"
        exit 1
    fi
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi