#!/bin/bash

# ==============================================
# DK App Install Service - Direct Execution
# ==============================================
# Runs dk_appinstallservice directly in embedded mode

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INSTALL]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPINSTALL_DIR="$(dirname "$SCRIPT_DIR")/dk_appinstallservice"
SCRIPTS_DIR="$APPINSTALL_DIR/scripts"

# Check if config file is provided
if [ $# -ne 1 ]; then
    print_error "Usage: $0 <app_config.json>"
    print_info "Example: $0 /home/user/.dk/dk_marketplace/app123_installcfg.json"
    exit 1
fi

CONFIG_FILE="$1"

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

print_info "Starting app installation service in embedded mode"
print_info "Configuration file: $CONFIG_FILE"

# Set up environment variables for dk_appinstallservice
export DK_USER="${DK_USER:-$(whoami)}"
export HOME_DIR="/home/$DK_USER"
export DK_EMBEDDED_MODE="${DK_EMBEDDED_MODE:-1}"
export DK_MOCK_MODE="${DK_MOCK_MODE:-1}"

print_status "Environment:"
print_info "DK_USER: $DK_USER"
print_info "HOME_DIR: $HOME_DIR"
print_info "Scripts directory: $SCRIPTS_DIR"

# Check if Python dependencies are available
if ! command -v python3 >/dev/null 2>&1; then
    print_error "Python3 is required but not installed"
    exit 1
fi

# Check if required Python modules are available
python3 -c "import json, os, sys, yaml, time, requests, subprocess, zipfile" 2>/dev/null || {
    print_warning "Some Python dependencies may be missing (yaml, requests)"
    print_info "Attempting to continue with available modules..."
}

# Change to scripts directory
cd "$SCRIPTS_DIR"

# Run the main installation script
print_status "Executing app installation..."
print_info "Working directory: $(pwd)"
print_info "Running: python3 main_simple.py $CONFIG_FILE"

# Execute the installation
print_status "🚀 Starting app installation..."
if python3 main_simple.py "$CONFIG_FILE"; then
    print_status "✅ App installation completed successfully"
    exit 0
else
    print_error "❌ App installation failed"
    exit 1
fi