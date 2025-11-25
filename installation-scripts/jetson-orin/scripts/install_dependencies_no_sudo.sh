#!/bin/bash
# Copyright (c) 2025 Eclipse Foundation.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License which is available at
# https://opensource.org/licenses/MIT.
#
# SPDX-License-Identifier: MIT

# Modified install_dependencies.sh - User-space installation only
# This version only installs tools that don't require sudo/root privileges

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

# Create local bin directory for user installations
LOCAL_BIN="$HOME/.local/bin"

setup_user_bin() {
    show_info "Setting up user bin directory: $LOCAL_BIN"
    mkdir -p "$LOCAL_BIN"

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
        show_success "Added $LOCAL_BIN to PATH"
    fi
}

# Install tool to user directory
install_to_user_bin() {
    local tool_name="$1"
    local install_command="$2"
    local success_msg="$3"
    local error_msg="$4"

    show_info "Installing $tool_name to user directory..."

    if run_with_feedback "$install_command" "$success_msg" "$error_msg"; then
        show_success "$tool_name installed successfully"
    else
        show_error "Failed to install $tool_name"
        return 1
    fi
}

# Install k9s to user directory
install_k9s_user() {
    local VERSION="${K9S_VERSION:-0.50.9}"

    # Check if already installed
    if [ -f "$LOCAL_BIN/k9s" ]; then
        local current_version=$("$LOCAL_BIN/k9s" version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^v//')
        if [[ -n "$current_version" ]]; then
            show_success "k9s v$current_version already installed in user directory"
            return 0
        fi
    fi

    # Detect architecture
    local ARCH
    case "$(uname -m)" in
        x86_64|amd64)   ARCH="amd64" ;;
        aarch64|arm64)  ARCH="arm64" ;;
        armv7l|armv7)   ARCH="armv7" ;;
        *)
            show_error "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac

    local TARBALL="k9s_Linux_${ARCH}.tar.gz"
    local URL="https://github.com/derailed/k9s/releases/download/v${VERSION}/${TARBALL}"

    show_info "Installing k9s v${VERSION} to user directory..."

    local install_command="tmp_dir=\$(mktemp -d) && \
        curl -fsSL \"${URL}\" -o \"\$tmp_dir/${TARBALL}\" && \
        tar -xzf \"\$tmp_dir/${TARBALL}\" -C \"\$tmp_dir\" && \
        cp \"\$tmp_dir/k9s\" \"$LOCAL_BIN/\" && \
        chmod +x \"$LOCAL_BIN/k9s\" && \
        rm -rf \"\$tmp_dir\""

    install_to_user_bin "k9s" "$install_command" \
        "k9s v${VERSION} installed to user directory" \
        "Failed to install k9s to user directory"
}

# Install yq to user directory
install_yq_user() {
    local target_version="${YQ_VERSION:-4.35.2}"

    # Check if already installed
    if [ -f "$LOCAL_BIN/yq" ]; then
        local current_version=$("$LOCAL_BIN/yq" --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^v//')
        if [[ -n "$current_version" ]]; then
            show_success "yq v$current_version already installed in user directory"
            return 0
        fi
    fi

    # Detect architecture
    local ARCH
    case "$(uname -m)" in
        x86_64|amd64)   ARCH="amd64" ;;
        aarch64|arm64)  ARCH="arm64" ;;
        armv7l|armv7)   ARCH="arm" ;;
        *)
            show_error "Unsupported architecture for yq: $(uname -m)"
            return 1
            ;;
    esac

    local URL="https://github.com/mikefarah/yq/releases/download/v${target_version}/yq_linux_${ARCH}"

    show_info "Installing yq v${target_version} to user directory..."

    install_to_user_bin "yq" "curl -fsSL \"${URL}\" -o \"$LOCAL_BIN/yq\" && chmod +x \"$LOCAL_BIN/yq\"" \
        "yq v${target_version} installed to user directory" \
        "Failed to install yq to user directory"
}

# Check if tool exists in system or user directory
check_tool() {
    local tool="$1"

    # Check system PATH
    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    fi

    # Check user bin directory
    if [ -f "$LOCAL_BIN/$tool" ]; then
        return 0
    fi

    return 1
}

# Main installation function
install_dependencies_no_sudo() {
    echo -e "${BLUE}${BOLD}User-space Dependencies Installation${NC}"
    echo -e "${DIM}Installing tools that don't require sudo privileges...${NC}"
    echo

    # Setup user bin directory
    setup_user_bin

    # Install tools that can be installed without sudo
    show_info "Installing user-space tools..."

    # k9s - Kubernetes CLI
    if check_tool "k9s"; then
        show_success "k9s is already available"
    else
        install_k9s_user
    fi

    # yq - YAML processor
    if check_tool "yq"; then
        show_success "yq is already available"
    else
        install_yq_user
    fi

    echo
    show_success "User-space dependencies installation completed!"

    # Show what's installed
    echo
    show_info "Available tools in user directory:"
    for tool in k9s yq; do
        if [ -f "$LOCAL_BIN/$tool" ]; then
            local version=$("$LOCAL_BIN/$tool" --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
            show_success "$tool: v$version (user directory)"
        fi
    done

    # Check system tools
    echo
    show_info "System tool availability:"
    for tool in git docker node npm jq; do
        if command -v "$tool" >/dev/null 2>&1; then
            show_success "$tool: available"
        else
            show_warning "$tool: not found (may require sudo for installation)"
        fi
    done

    echo
    show_info "Note: Tools requiring system privileges (Docker, Node.js, etc.) will need to be installed separately with sudo."
}

# Main execution
main() {
    install_dependencies_no_sudo
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi