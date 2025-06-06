#!/bin/bash

# ==============================================
# Enhanced DK IVI Runner with Unified Configuration
# ==============================================
# Improved version of run_dk_ivi_optimized.sh with better parameter management

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[RUN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_MANAGER="$SCRIPT_DIR/scripts/config-manager.sh"
DEFAULT_CONFIG="$SCRIPT_DIR/config/dk_ivi.yml"

# Command line parameters
ACTION=${1:-"run"}
CONFIG_FILE=${2:-"$DEFAULT_CONFIG"}

show_help() {
    echo "Usage: $0 [ACTION] [CONFIG_FILE]"
    echo ""
    echo "Actions:"
    echo "  run           - Run dk_ivi application (default)"
    echo "  run-fg        - Run in foreground (interactive)"
    echo "  stop          - Stop running container"
    echo "  restart       - Restart container"
    echo "  logs          - Show container logs"
    echo "  shell         - Open shell in container"
    echo "  status        - Show container status"
    echo "  config        - Show current configuration"
    echo "  validate      - Validate configuration file"
    echo ""
    echo "Configuration:"
    echo "  Default config: $DEFAULT_CONFIG"
    echo "  Custom config:  $0 run /path/to/custom.yml"
    echo ""
    echo "🚀 Enhanced Features:"
    echo "  • Unified YAML configuration"
    echo "  • Parameter validation"
    echo "  • Clear error messages"
    echo "  • Developer-friendly debugging"
    echo "  • Runtime parameter injection"
    echo ""
    echo "Examples:"
    echo "  $0 run                          # Use default config"
    echo "  $0 run config/debug.yml         # Use custom config"
    echo "  $0 config                       # Show current config"
    echo "  $0 validate config/test.yml     # Validate config"
}

load_and_validate_config() {
    local config_file="$1"
    
    if [ ! -f "$CONFIG_MANAGER" ]; then
        print_error "Configuration manager not found: $CONFIG_MANAGER"
        exit 1
    fi
    
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    print_info "Loading configuration from: $config_file"
    
    # Load and validate configuration
    if ! source "$CONFIG_MANAGER" load "$config_file"; then
        print_error "Failed to load configuration"
        exit 1
    fi
    
    print_status "✅ Configuration loaded and validated"
}

check_requirements() {
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required but not installed"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker ps &> /dev/null; then
        print_error "Docker daemon is not running or permission denied"
        exit 1
    fi
    
    # Check if output directory exists (from config)
    if [ ! -d "output" ]; then
        print_warning "Output directory not found - run build first"
    fi
}

setup_display_and_gpu() {
    print_info "Setting up display and GPU configuration..."
    
    # X11 Display setup
    if [ "$DK_X11_FORWARDING" = "true" ]; then
        if [ -z "$DISPLAY" ]; then
            print_warning "DISPLAY not set, using :0"
            export DISPLAY=":0"
        fi
        
        # Enable X11 forwarding
        xhost +local:docker >/dev/null 2>&1 || {
            print_warning "Failed to run 'xhost +local:docker'"
            print_info "X11 forwarding may not work properly"
        }
        
        print_info "X11 Display: $DISPLAY"
    fi
    
    # GPU setup
    if [ "$DK_ENABLE_GPU" = "true" ]; then
        if [ -e "/dev/dri" ]; then
            print_info "GPU devices found - hardware acceleration enabled"
        else
            print_warning "GPU requested but /dev/dri not found - using software rendering"
        fi
    fi
    
    # XDG Runtime setup
    local runtime_dir="/run/user/$(id -u)"
    if [ ! -d "$runtime_dir" ]; then
        print_warning "XDG_RUNTIME_DIR $runtime_dir does not exist"
        runtime_dir="/tmp/runtime-$(id -u)"
        mkdir -p "$runtime_dir"
    fi
    export XDG_RUNTIME_DIR="$runtime_dir"
    print_info "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
}

run_container() {
    load_and_validate_config "$CONFIG_FILE"
    check_requirements
    setup_display_and_gpu
    
    # Stop existing container if running
    if docker ps -q -f name="$DK_CONTAINER_NAME" | grep -q .; then
        print_warning "Container '$DK_CONTAINER_NAME' is already running"
        print_info "Stopping existing container..."
        docker stop "$DK_CONTAINER_NAME" >/dev/null 2>&1
        docker rm "$DK_CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    print_status "Starting dk_ivi application with enhanced configuration..."
    
    # Generate Docker arguments from configuration
    local docker_args
    docker_args=$("$CONFIG_MANAGER" docker-args "$CONFIG_FILE")
    
    # Generate application arguments from configuration
    local app_args
    app_args=$("$CONFIG_MANAGER" app-args "$CONFIG_FILE")
    
    print_info "=== Runtime Parameters ==="
    echo "Container Name:    $DK_CONTAINER_NAME"
    echo "Docker Image:      $DK_DOCKER_IMAGE"
    echo "Run Mode:          $DK_RUN_MODE"
    echo "Qt Backend:        $DK_QT_BACKEND"
    echo "Log Level:         $DK_LOG_LEVEL"
    echo "CAN Interface:     $DK_CAN_INTERFACE"
    echo "VAPI Broker:       $DK_VAPI_DATABROKER"
    echo "GPU Enabled:       $DK_ENABLE_GPU"
    echo "X11 Forwarding:    $DK_X11_FORWARDING"
    echo "App Arguments:     $app_args"
    echo ""
    
    # Build Docker command
    local docker_cmd
    if [[ "$DK_RUN_MODE" == "interactive" ]] || [[ "$ACTION" == "run-fg" ]]; then
        docker_cmd="docker run --rm -it $docker_args $DK_DOCKER_IMAGE /app/exec/dk_ivi $app_args"
    else
        docker_cmd="docker run -d $docker_args $DK_DOCKER_IMAGE /app/exec/dk_ivi $app_args"
    fi
    
    # Execute Docker command
    print_status "Executing: docker run [args] $DK_DOCKER_IMAGE /app/exec/dk_ivi $app_args"
    
    if [[ "$DK_RUN_MODE" == "interactive" ]] || [[ "$ACTION" == "run-fg" ]]; then
        print_status "Running in foreground (interactive mode)..."
        print_info "Press Ctrl+C to stop the application"
        eval "$docker_cmd"
    else
        print_status "Running in background (detached mode)..."
        eval "$docker_cmd"
        
        # Verify container started
        sleep 2
        if docker ps -q -f name="$DK_CONTAINER_NAME" | grep -q .; then
            print_status "✅ Container started successfully!"
            print_info "Container ID: $(docker ps -q -f name="$DK_CONTAINER_NAME")"
            print_info "View logs: $0 logs"
            print_info "Open shell: $0 shell"
            print_status "dk_ivi application is running with enhanced configuration"
        else
            print_error "❌ Failed to start container"
            print_info "Check logs: docker logs $DK_CONTAINER_NAME"
            exit 1
        fi
    fi
}

stop_container() {
    load_and_validate_config "$CONFIG_FILE"
    
    if docker ps -q -f name="$DK_CONTAINER_NAME" | grep -q .; then
        print_status "Stopping container '$DK_CONTAINER_NAME'..."
        docker stop "$DK_CONTAINER_NAME"
        print_status "✅ Container stopped"
    else
        print_warning "Container '$DK_CONTAINER_NAME' is not running"
    fi
}

restart_container() {
    print_status "Restarting dk_ivi application..."
    stop_container
    sleep 2
    run_container
}

show_logs() {
    load_and_validate_config "$CONFIG_FILE"
    
    if docker ps -aq -f name="$DK_CONTAINER_NAME" | grep -q .; then
        print_info "Showing logs for container '$DK_CONTAINER_NAME'..."
        print_info "Press Ctrl+C to stop following logs"
        echo ""
        docker logs -f "$DK_CONTAINER_NAME"
    else
        print_error "Container '$DK_CONTAINER_NAME' does not exist"
    fi
}

open_shell() {
    load_and_validate_config "$CONFIG_FILE"
    
    if docker ps -q -f name="$DK_CONTAINER_NAME" | grep -q .; then
        print_status "Opening shell in container '$DK_CONTAINER_NAME'..."
        docker exec -it "$DK_CONTAINER_NAME" /bin/bash
    else
        print_error "Container '$DK_CONTAINER_NAME' is not running"
        print_info "Start it first with: $0 run"
    fi
}

show_status() {
    load_and_validate_config "$CONFIG_FILE"
    
    print_info "=== Container Status ==="
    
    if docker ps -aq -f name="$DK_CONTAINER_NAME" | grep -q .; then
        echo "Container exists: ✅"
        
        if docker ps -q -f name="$DK_CONTAINER_NAME" | grep -q .; then
            echo "Container running: ✅"
            echo "Container ID: $(docker ps -q -f name="$DK_CONTAINER_NAME")"
            echo "Uptime: $(docker ps --format "table {{.Status}}" -f name="$DK_CONTAINER_NAME" | tail -n +2)"
        else
            echo "Container running: ❌ (stopped)"
        fi
        
        echo "Image: $(docker inspect "$DK_CONTAINER_NAME" --format '{{.Config.Image}}' 2>/dev/null)"
    else
        echo "Container exists: ❌"
    fi
}

show_config() {
    load_and_validate_config "$CONFIG_FILE"
    "$CONFIG_MANAGER" show "$CONFIG_FILE"
}

validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    print_info "Validating configuration file: $CONFIG_FILE"
    "$CONFIG_MANAGER" validate "$CONFIG_FILE"
}

# ==============================================
# Main Execution
# ==============================================

case $ACTION in
    "help"|"-h"|"--help")
        show_help
        ;;
    "run")
        run_container
        ;;
    "run-fg")
        run_container
        ;;
    "stop")
        stop_container
        ;;
    "restart")
        restart_container
        ;;
    "logs")
        show_logs
        ;;
    "shell")
        open_shell
        ;;
    "status")
        show_status
        ;;
    "config")
        show_config
        ;;
    "validate")
        validate_config
        ;;
    *)
        print_error "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac