#!/bin/bash

# Enhanced run script for dk_ivi application
# Works with output from build_optimized.sh with GUI support and configuration
# Updated to match dk_run.sh configuration and mounts

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[RUN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_help() { echo -e "${CYAN}[HELP]${NC} $1"; }

# Configuration
CONTAINER_NAME="dk_ivi"
BUILDER_IMAGE="dk-ivi-builder"
RUNTIME_IMAGE="dk-ivi-runtime"
ACTION=${1:-"run"}

# Default parameters (can be overridden with environment variables or config file)
DK_USER=${DK_USER:-"$(whoami)"}
DOCKER_HUB_NAMESPACE=${DOCKER_HUB_NAMESPACE:-"ghcr.io/samtranbosch"}
ARCH=${ARCH:-"$(uname -m)"}
HOME_DIR=${HOME_DIR:-"$HOME"}

# Additional configurable parameters (matching dk_run.sh)
RESTART_POLICY=${RESTART_POLICY:-"unless-stopped"}
LOG_MAX_SIZE=${LOG_MAX_SIZE:-"10m"}
LOG_MAX_FILES=${LOG_MAX_FILES:-"3"}
QT_BACKEND=${QT_BACKEND:-"software"}
MOUNT_MODE=${MOUNT_MODE:-"ro"}
EXTRA_VOLUMES=${EXTRA_VOLUMES:-""}
EXTRA_ENV_VARS=${EXTRA_ENV_VARS:-""}
EXTRA_DOCKER_ARGS=${EXTRA_DOCKER_ARGS:-""}
ENABLE_GPU=${ENABLE_GPU:-"auto"}
X11_FORWARDING=${X11_FORWARDING:-"auto"}
RUN_MODE=${RUN_MODE:-"detached"}  # detached or interactive

# Docker parameters (matching dk_run.sh)
LOG_LIMIT_PARAM="--log-opt max-size=${LOG_MAX_SIZE} --log-opt max-file=${LOG_MAX_FILES}"
DOCKER_SHARE_PARAM="-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker"

# Configuration file support
CONFIG_FILE=${CONFIG_FILE:-"run_config.conf"}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        print_info "Loading configuration from: $CONFIG_FILE"
        
        # Source the config file safely
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove any quotes from value
            value=$(echo "$value" | sed 's/^["'\'']*//; s/["'\'']*$//')
            
            # Export the variable (only if not already set by environment)
            case "$key" in
                CONTAINER_NAME|BUILDER_IMAGE|RUNTIME_IMAGE|DK_USER|DOCKER_HUB_NAMESPACE|ARCH|HOME_DIR|RESTART_POLICY|LOG_MAX_SIZE|LOG_MAX_FILES|QT_BACKEND|MOUNT_MODE|EXTRA_VOLUMES|EXTRA_ENV_VARS|EXTRA_DOCKER_ARGS|ENABLE_GPU|X11_FORWARDING|RUN_MODE)
                    # Only set if the variable is not already set by environment
                    if [ -z "${!key}" ] || [ "${!key}" = "${key#*=}" ]; then
                        declare -g "$key=$value"
                    fi
                    ;;
            esac
        done < "$CONFIG_FILE"
        
        print_info "Configuration loaded successfully"
    else
        # Only auto-create config if not running create-config explicitly
        if [[ "$ACTION" != "create-config" ]]; then
            print_info "No config file found ($CONFIG_FILE), using defaults"
        fi
    fi
}

# Function to load dreamOS environment (matching dk_run.sh)
load_dreamos_environment() {
    print_info "Loading dreamOS environment configuration..."
    
    # Determine the user who ran the command
    if [ -n "$SUDO_USER" ]; then
        DK_USER=$SUDO_USER
    else
        DK_USER=$USER
    fi
    
    # Look for environment file
    local env_file="/home/$DK_USER/.dk/dk_swupdate/dk_swupdate_env.sh"
    
    if [ -f "$env_file" ]; then
        source "$env_file"
        print_status "Environment loaded from $env_file"
        print_info "User: $DK_USER, Architecture: $ARCH, Namespace: $DOCKER_HUB_NAMESPACE"
        
        # Update LOG_LIMIT_PARAM and DOCKER_SHARE_PARAM with loaded values
        LOG_LIMIT_PARAM="--log-opt max-size=${LOG_MAX_SIZE} --log-opt max-file=${LOG_MAX_FILES}"
        DOCKER_SHARE_PARAM="-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker"
        
        return 0
    else
        print_warning "Environment file not found at $env_file"
        print_info "Using default values"
        return 1
    fi
}

create_config_file() {
    if [ -f "$CONFIG_FILE" ]; then
        print_warning "Config file '$CONFIG_FILE' already exists"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing config file"
            return 0
        fi
    fi
    
    print_status "Creating configuration file with current runtime values: $CONFIG_FILE"
    
    # Ensure we have the current runtime values (in case config was loaded)
    local current_user="${DK_USER:-$(whoami)}"
    local current_namespace="${DOCKER_HUB_NAMESPACE:-ghcr.io/samtranbosch}"
    local current_arch="${ARCH:-$(uname -m)}"
    local current_home="${HOME_DIR:-$HOME}"
    local current_restart="${RESTART_POLICY:-unless-stopped}"
    local current_log_size="${LOG_MAX_SIZE:-10m}"
    local current_log_files="${LOG_MAX_FILES:-3}"
    local current_qt="${QT_BACKEND:-software}"
    local current_mount="${MOUNT_MODE:-ro}"
    local current_run_mode="${RUN_MODE:-detached}"
    local current_gpu="${ENABLE_GPU:-auto}"
    local current_x11="${X11_FORWARDING:-auto}"
    local current_container="${CONTAINER_NAME:-dk_ivi}"
    local current_builder="${BUILDER_IMAGE:-dk-ivi-builder}"
    local current_runtime="${RUNTIME_IMAGE:-dk-ivi-runtime}"
    
    cat > "$CONFIG_FILE" << EOF
# dk_ivi Run Configuration
# Auto-generated with current runtime values
# Edit these values to customize container behavior

# Container and Image Settings
CONTAINER_NAME=$current_container
BUILDER_IMAGE=$current_builder
RUNTIME_IMAGE=$current_runtime

# Application Settings
DK_USER=$current_user
DOCKER_HUB_NAMESPACE=$current_namespace
ARCH=$current_arch
HOME_DIR=$current_home

# Docker Runtime Settings (matching dk_run.sh)
RESTART_POLICY=$current_restart        # unless-stopped/no/always
LOG_MAX_SIZE=$current_log_size
LOG_MAX_FILES=$current_log_files
QT_BACKEND=$current_qt
MOUNT_MODE=$current_mount
RUN_MODE=$current_run_mode                    # detached/interactive

# GUI and Hardware Settings
ENABLE_GPU=$current_gpu          # auto/true/false - GPU hardware acceleration
X11_FORWARDING=$current_x11  # auto/true/false - X11 display forwarding

# Advanced Settings
# Extra volume mounts (format: "-v host:container -v host2:container2")
EXTRA_VOLUMES="${EXTRA_VOLUMES:-}"

# Extra environment variables (format: "-e VAR1=value1 -e VAR2=value2")
EXTRA_ENV_VARS="${EXTRA_ENV_VARS:-}"

# Extra Docker arguments (any additional docker run arguments)
EXTRA_DOCKER_ARGS="${EXTRA_DOCKER_ARGS:-}"

# Examples of what you can add:
# EXTRA_VOLUMES="-v /my/config:/app/config -v /my/data:/app/data"
# EXTRA_ENV_VARS="-e DEBUG_MODE=1 -e LOG_LEVEL=debug"
# EXTRA_DOCKER_ARGS="--privileged --cap-add=SYS_ADMIN"

# GUI Examples:
# ENABLE_GPU=false              # Force software rendering
# X11_FORWARDING=true           # Force X11 forwarding
# QT_BACKEND=opengl             # Use OpenGL backend instead of software
# RUN_MODE=interactive          # Run in foreground with direct output

# dreamOS Integration:
# This configuration matches the dk_run.sh setup for full dreamOS compatibility
# Container name matches standard dreamOS convention (dk_ivi)
# Restart policy set to unless-stopped for persistence
# Docker socket sharing enabled for dreamOS integration
EOF
    
    print_status "✅ Configuration file created: $CONFIG_FILE"
    print_info "Config contains your current runtime values:"
    print_info "  User: $current_user"
    print_info "  Home: $current_home" 
    print_info "  Architecture: $current_arch"
    print_info "  Run Mode: $current_run_mode"
    print_info "  Container: $current_container (matches dk_run.sh)"
    print_info "Edit this file to customize your container settings, then run: $0 run"
}

show_config() {
    load_config
    print_info "=== Current Configuration ==="
    echo "Config File:            $CONFIG_FILE"
    echo "Container Name:         $CONTAINER_NAME"
    echo "Builder Image:          $BUILDER_IMAGE"
    echo "Runtime Image:          $RUNTIME_IMAGE"
    echo "DK User:                $DK_USER"
    echo "Docker Namespace:       $DOCKER_HUB_NAMESPACE"
    echo "Architecture:           $ARCH"
    echo "Home Directory:         $HOME_DIR"
    echo "Restart Policy:         $RESTART_POLICY"
    echo "Log Max Size:           $LOG_MAX_SIZE"
    echo "Log Max Files:          $LOG_MAX_FILES"
    echo "Qt Backend:             $QT_BACKEND"
    echo "Mount Mode:             $MOUNT_MODE"
    echo "Run Mode:               $RUN_MODE"
    echo "GPU Support:            $ENABLE_GPU"
    echo "X11 Forwarding:         $X11_FORWARDING"
    echo "Extra Volumes:          ${EXTRA_VOLUMES:-"(none)"}"
    echo "Extra Environment:      ${EXTRA_ENV_VARS:-"(none)"}"
    echo "Extra Docker Args:      ${EXTRA_DOCKER_ARGS:-"(none)"}"
}

show_help() {
    echo "Usage: $0 [ACTION] [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  run           - Run dk_ivi container (default)"
    echo "  run-fg        - Run dk_ivi container in foreground (interactive)"
    echo "  stop          - Stop the running container"
    echo "  restart       - Restart the container"
    echo "  logs          - Show container logs"
    echo "  shell         - Open shell in running container"
    echo "  status        - Show container status"
    echo "  remove        - Stop and remove container"
    echo "  create-config - Create sample configuration file"
    echo "  show-config   - Show current configuration"
    echo "  check         - Check system requirements and setup"
    echo ""
    echo "🚀 This script runs the dk_ivi application built by build_optimized.sh"
    echo "   Make sure to run './build_optimized.sh build' first!"
    echo ""
    echo "📁 Configuration:"
    echo "   Config file: $CONFIG_FILE (use CONFIG_FILE=path to override)"
    echo "   Run '$0 create-config' to create/update config file"
    echo ""
    echo "🖥️  GUI Support (matching dk_run.sh):"
    echo "   • Automatic X11 forwarding detection"
    echo "   • Hardware GPU acceleration (when available)"
    echo "   • NVIDIA Jetson optimization support"
    echo "   • Software fallback rendering"
    echo "   • XDG runtime directory setup"
    echo "   • dreamOS environment integration"
    echo ""
    echo "🔧 dreamOS Integration:"
    echo "   • Uses dk_ivi container name (matches dk_run.sh)"
    echo "   • Docker socket sharing for dreamOS integration"
    echo "   • Mounts /home/\$USER/.dk for dreamOS data"
    echo "   • Loads dreamOS environment variables"
    echo "   • Compatible with dk_run.sh service management"
    echo ""
    echo "Environment Variables (can also be set in config file):"
    echo "  DK_USER                 - User name (default: current user)"
    echo "  DOCKER_HUB_NAMESPACE    - Docker namespace (default: 'ghcr.io/samtranbosch')"
    echo "  ARCH                    - Architecture (default: auto-detected)"
    echo "  HOME_DIR                - Home directory (default: \$HOME)"
    echo "  RESTART_POLICY          - Docker restart policy (default: 'unless-stopped')"
    echo "  QT_BACKEND              - Qt backend (default: 'software')"
    echo "  ENABLE_GPU              - GPU support (default: 'auto')"
    echo "  X11_FORWARDING          - X11 forwarding (default: 'auto')"
    echo "  RUN_MODE                - Run mode (default: 'detached')"
    echo ""
    echo "Examples:"
    echo "  $0 create-config        # Create/update config file"
    echo "  $0 check                # Check system requirements"
    echo "  $0 run                  # Run in background (detached)"
    echo "  $0 run-fg               # Run in foreground (interactive)"
    echo "  CONFIG_FILE=my.conf $0 run  # Use custom config file"
    echo "  $0 show-config          # Show current settings"
    echo "  ENABLE_GPU=false $0 run # Force software rendering"
    echo ""
    echo "Note: This script is fully compatible with dk_run.sh and uses the same"
    echo "      container name and configuration for seamless dreamOS integration."
}

check_system_requirements() {
    print_info "=== System Requirements Check ==="
    
    # Check Docker
    if command -v docker &> /dev/null; then
        echo "Docker: ✅ Available ($(docker --version | cut -d' ' -f3 | cut -d',' -f1))"
        
        # Check if Docker daemon is running
        if docker ps &> /dev/null; then
            echo "Docker daemon: ✅ Running"
        else
            echo "Docker daemon: ❌ Not running or no permission"
            print_warning "You may need to start Docker or add your user to the docker group"
        fi
    else
        echo "Docker: ❌ Not installed"
        print_error "Please install Docker first"
        return 1
    fi
    
    # Check for built application
    if [ -f "output/dk_ivi" ]; then
        echo "dk_ivi executable: ✅ Found ($(ls -lh output/dk_ivi | awk '{print $5}'))"
    else
        echo "dk_ivi executable: ❌ Not found"
        print_warning "Run './build_optimized.sh build' to build the application"
    fi
    
    # Check runtime image
    if docker images $RUNTIME_IMAGE | grep -q $RUNTIME_IMAGE; then
        echo "Runtime image: ✅ Available"
    else
        echo "Runtime image: ❌ Not found"
        print_warning "Run './build_optimized.sh images' to build runtime image"
    fi
    
    # Check X11 setup
    print_info "=== X11 and GUI Setup ==="
    
    if [ -n "$DISPLAY" ]; then
        echo "DISPLAY variable: ✅ Set to $DISPLAY"
    else
        echo "DISPLAY variable: ⚠️  Not set"
        print_info "Will default to :0 for GUI applications"
    fi
    
    if [ -d "/tmp/.X11-unix" ]; then
        echo "X11 socket: ✅ Available"
    else
        echo "X11 socket: ❌ Not found"
        print_warning "GUI applications may not work"
    fi
    
    # Check XDG runtime
    local runtime_dir="/run/user/$(id -u)"
    if [ -d "$runtime_dir" ]; then
        echo "XDG runtime dir: ✅ $runtime_dir"
    else
        echo "XDG runtime dir: ⚠️  Will create $runtime_dir"
    fi
    
    # Check GPU
    print_info "=== GPU and Hardware Acceleration ==="
    
    if [ -e "/dev/dri" ]; then
        echo "GPU devices: ✅ Found"
        ls /dev/dri/ | sed 's/^/  - /'
    else
        echo "GPU devices: ⚠️  Not found"
        print_info "Will use software rendering"
    fi
    
    # Check xhost
    if command -v xhost &> /dev/null; then
        echo "xhost utility: ✅ Available"
    else
        echo "xhost utility: ⚠️  Not found"
        print_info "Install with: sudo apt-get install x11-xserver-utils"
    fi
    
    # Check dreamOS environment
    print_info "=== dreamOS Environment ==="
    local env_file="/home/$(whoami)/.dk/dk_swupdate/dk_swupdate_env.sh"
    if [ -f "$env_file" ]; then
        echo "dreamOS environment: ✅ Found"
        echo "  File: $env_file"
    else
        echo "dreamOS environment: ⚠️  Not found"
        print_info "Will use default values"
    fi
    
    print_info "=== Recommendations ==="
    print_help "For best GUI performance:"
    print_help "  1. Ensure your user is in the 'docker' group"
    print_help "  2. Install x11-xserver-utils for X11 forwarding"
    print_help "  3. Set DISPLAY environment variable if not set"
    print_help "  4. Run 'xhost +local:docker' before starting GUI apps"
    print_help "  5. Install dreamOS for full integration (./dk_install)"
}

check_build_output() {
    if [ ! -f "output/dk_ivi" ]; then
        print_error "Built application not found in output/dk_ivi"
        print_info "Please build first with: ./build_optimized.sh build"
        exit 1
    fi
    
    if [ ! -d "output/library" ]; then
        print_warning "Library directory output/library not found"
        print_info "Application may not run properly without required libraries"
    fi
    
    print_info "Found built application: output/dk_ivi ($(ls -lh output/dk_ivi | awk '{print $5}'))"
}

check_runtime_image() {
    if ! docker images $RUNTIME_IMAGE | grep -q $RUNTIME_IMAGE; then
        print_error "Runtime image '$RUNTIME_IMAGE' not found!"
        print_info "Please build the images first with: ./build_optimized.sh images"
        exit 1
    fi
}

setup_x11_and_gpu() {
    # Set up X11 forwarding and runtime environment (matching dk_run.sh pattern)
    
    # Enable X11 forwarding (matching dk_run.sh)
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$current_dir/scripts/dk_enable_xhost.sh" ]; then
        print_info "Running dk_enable_xhost.sh script..."
        "$current_dir/scripts/dk_enable_xhost.sh" >/dev/null 2>&1
    fi
    
    # Set XDG_RUNTIME_DIR
    if [ -z "$XDG_RUNTIME_DIR" ]; then
        XDG_RUNTIME_DIR="/run/user/$(id -u)"
        if [ ! -d "$XDG_RUNTIME_DIR" ]; then
            print_warning "XDG_RUNTIME_DIR $XDG_RUNTIME_DIR does not exist, using /tmp/runtime-$(id -u)"
            XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
            mkdir -p "$XDG_RUNTIME_DIR"
        fi
    fi
    
    # Set up DISPLAY
    if [ -z "$DISPLAY" ] && [[ "$X11_FORWARDING" != "false" ]]; then
        print_warning "DISPLAY not set, using :0"
        export DISPLAY=":0"
    fi
    
    # Enable X11 forwarding for Docker (matching dk_run.sh pattern)
    if [[ "$X11_FORWARDING" == "true" ]] || [[ "$X11_FORWARDING" == "auto" && -n "$DISPLAY" ]]; then
        print_info "Enabling X11 forwarding for Docker..."
        xhost +local:docker >/dev/null 2>&1 || {
            print_warning "Failed to run 'xhost +local:docker'"
            print_info "X11 forwarding may not work properly"
            print_info "Try: sudo apt-get install x11-xserver-utils"
        }
        
        X11_OPTS="-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY"
        print_info "X11 Display: $DISPLAY"
    else
        X11_OPTS=""
        print_info "X11 forwarding disabled"
    fi
    
    print_info "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
    
    # Check GPU setup (matching dk_run.sh pattern)
    if [[ "$ENABLE_GPU" == "true" ]] || [[ "$ENABLE_GPU" == "auto" && -e "/dev/dri" ]]; then
        if [ -e "/dev/dri" ]; then
            # Check for NVIDIA hardware (matching dk_run.sh)
            if [ -f "/etc/nv_tegra_release" ]; then
                print_info "NVIDIA Jetson detected - using optimized configuration"
                GPU_OPTS="-e QT_QUICK_BACKEND=software"
            else
                print_info "Standard hardware detected - enabling GPU acceleration"
                GPU_OPTS="--device /dev/dri:/dev/dri"
            fi
        else
            GPU_OPTS=""
            print_warning "GPU requested but /dev/dri not found, using software rendering"
        fi
    else
        GPU_OPTS=""
        print_info "Using software rendering (GPU disabled)"
    fi
}

print_run_parameters() {
    print_info "=== Container Run Parameters (dk_run.sh compatible) ==="
    echo "Container Name:         $CONTAINER_NAME"
    echo "Runtime Image:          $RUNTIME_IMAGE"
    echo "Executable Source:      $(pwd)/output/dk_ivi"
    echo "Libraries Source:       $(pwd)/output/library/"
    echo "Display:                ${DISPLAY:-"(not set)"}"
    echo "XDG Runtime Dir:        $XDG_RUNTIME_DIR"
    echo "Qt Backend:             $QT_BACKEND"
    echo "Run Mode:               $RUN_MODE"
    echo "Restart Policy:         $RESTART_POLICY"
    echo "Log Settings:           $LOG_LIMIT_PARAM"
    echo "Mount Mode:             $MOUNT_MODE"
    echo "GPU Support:            $ENABLE_GPU"
    echo "X11 Forwarding:         $X11_FORWARDING"
    echo "DK User:                $DK_USER"
    echo "Docker Namespace:       $DOCKER_HUB_NAMESPACE"
    echo "Architecture:           $ARCH"
    echo "Home Directory:         $HOME_DIR"
    echo "Data Directory:         $HOME_DIR/.dk"
    echo "Container Data Path:    /app/.dk/"
    echo "Docker Socket Sharing:  Enabled"
    [ -n "$EXTRA_VOLUMES" ] && echo "Extra Volumes:          $EXTRA_VOLUMES"
    [ -n "$EXTRA_ENV_VARS" ] && echo "Extra Environment:      $EXTRA_ENV_VARS"
    [ -n "$EXTRA_DOCKER_ARGS" ] && echo "Extra Docker Args:      $EXTRA_DOCKER_ARGS"
    echo ""
}

run_container() {
    # Load dreamOS environment first, then config
    load_dreamos_environment
    
    # Only load config if not explicitly running create-config
    if [[ "$ACTION" != "create-config" ]]; then
        load_config
    fi
    
    check_build_output
    check_runtime_image
    setup_x11_and_gpu
    
    # Ensure data directory exists (matching dk_run.sh)
    mkdir -p "$HOME_DIR/.dk"
    
    # Stop existing container if running (always for matching dk_run.sh behavior)
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_warning "Container '$CONTAINER_NAME' is already running"
        print_info "Stopping existing container..."
        docker stop $CONTAINER_NAME >/dev/null 2>&1
        docker rm $CONTAINER_NAME >/dev/null 2>&1
    fi
    
    print_run_parameters
    
    print_status "Starting dk_ivi application..."
    
    # Build docker run command matching dk_run.sh pattern
    if [[ "$RUN_MODE" == "interactive" ]] || [[ "$ACTION" == "run-fg" ]]; then
        # Interactive mode (foreground) - matches build_optimized.sh run_application()
        docker_cmd="docker run --rm -it \
            --network host \
            -e DISPLAY=$DISPLAY \
            -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
            -v $(pwd)/output:/app/exec:$MOUNT_MODE \
            -e LD_LIBRARY_PATH=/app/exec/library \
            -e QML_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt6/qml \
            -e QT_QUICK_BACKEND=$QT_BACKEND"
    else
        # Detached mode (background) - matches dk_run.sh pattern exactly
        docker_cmd="docker run -d -it \
            --name $CONTAINER_NAME \
            --network host \
            --restart $RESTART_POLICY \
            $LOG_LIMIT_PARAM \
            $DOCKER_SHARE_PARAM \
            -v $HOME_DIR/.dk:/app/.dk \
            -v $(pwd)/output:/app/exec:$MOUNT_MODE \
            -e DKCODE=dreamKIT \
            -e DK_USER=$DK_USER \
            -e DK_DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE \
            -e DK_ARCH=$ARCH \
            -e DK_CONTAINER_ROOT=/app/.dk/ \
            -e DISPLAY=$DISPLAY \
            -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
            -e LD_LIBRARY_PATH=/app/exec/library \
            -e QML_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt6/qml \
            -e QT_QUICK_BACKEND=$QT_BACKEND"
    fi
    
    # Add X11 options if enabled
    if [ -n "$X11_OPTS" ]; then
        docker_cmd="$docker_cmd $X11_OPTS"
    fi
    
    # Add GPU options if enabled
    if [ -n "$GPU_OPTS" ]; then
        docker_cmd="$docker_cmd $GPU_OPTS"
    fi
    
    # Add extra volumes if specified
    if [ -n "$EXTRA_VOLUMES" ]; then
        docker_cmd="$docker_cmd $EXTRA_VOLUMES"
    fi
    
    # Add extra environment variables if specified
    if [ -n "$EXTRA_ENV_VARS" ]; then
        docker_cmd="$docker_cmd $EXTRA_ENV_VARS"
    fi
    
    # Add extra docker arguments if specified
    if [ -n "$EXTRA_DOCKER_ARGS" ]; then
        docker_cmd="$docker_cmd $EXTRA_DOCKER_ARGS"
    fi
    
    # Add image and command
    docker_cmd="$docker_cmd $RUNTIME_IMAGE /app/exec/dk_ivi"
    
    # Execute the docker command
    if [[ "$RUN_MODE" == "interactive" ]] || [[ "$ACTION" == "run-fg" ]]; then
        print_status "Running dk_ivi in foreground (interactive mode)..."
        print_info "Press Ctrl+C to stop the application"
        eval $docker_cmd
    else
        print_status "Running dk_ivi in background (detached mode)..."
        eval $docker_cmd
        
        # Check if container started successfully (matching dk_run.sh verification)
        sleep 2
        if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
            print_status "✅ Container started successfully!"
            print_info "Container ID: $(docker ps -q -f name=$CONTAINER_NAME)"
            print_info "View logs with: $0 logs"
            print_info "Open shell with: $0 shell"
            print_status "dk_ivi application is running in background"
            print_info "IVI dashboard should now be available on display: $DISPLAY"
            
            # Show useful commands (matching dk_run.sh)
            echo -e "\nUseful commands:"
            echo -e "  View IVI logs: docker logs -f $CONTAINER_NAME"
            echo -e "  Stop IVI:      docker stop $CONTAINER_NAME"  
            echo -e "  Restart IVI:   docker restart $CONTAINER_NAME"
        else
            print_error "❌ Failed to start container"
            print_info "Check logs with: docker logs $CONTAINER_NAME"
            exit 1
        fi
    fi
}

run_interactive() {
    RUN_MODE="interactive"
    run_container
}

stop_container() {
    load_config
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_status "Stopping container '$CONTAINER_NAME'..."
        docker stop $CONTAINER_NAME
        print_status "✅ Container stopped"
    else
        print_warning "Container '$CONTAINER_NAME' is not running"
    fi
}

restart_container() {
    load_config
    print_status "Restarting container '$CONTAINER_NAME'..."
    stop_container
    sleep 2
    run_container
}

show_logs() {
    load_config
    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        print_info "Showing logs for container '$CONTAINER_NAME'..."
        print_info "Press Ctrl+C to stop following logs"
        echo ""
        docker logs -f $CONTAINER_NAME
    else
        print_error "Container '$CONTAINER_NAME' does not exist"
    fi
}

open_shell() {
    load_config
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_status "Opening shell in container '$CONTAINER_NAME'..."
        docker exec -it $CONTAINER_NAME /bin/bash
    else
        print_error "Container '$CONTAINER_NAME' is not running"
        print_info "Start it first with: $0 run"
    fi
}

show_status() {
    load_config
    print_info "=== Container Status ==="
    
    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        echo "Container exists: ✅"
        
        if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
            echo "Container running: ✅"
            echo "Container ID: $(docker ps -q -f name=$CONTAINER_NAME)"
            echo "Uptime: $(docker ps --format "table {{.Status}}" -f name=$CONTAINER_NAME | tail -n +2)"
        else
            echo "Container running: ❌ (stopped)"
        fi
        
        echo "Image: $(docker inspect $CONTAINER_NAME --format '{{.Config.Image}}' 2>/dev/null)"
    else
        echo "Container exists: ❌"
    fi
    
    print_info "=== Build Output Status ==="
    echo "Built executable: $([ -f "output/dk_ivi" ] && echo "✅ $(ls -lh output/dk_ivi | awk '{print $5}')" || echo "❌ Not built")"
    echo "Libraries: $([ -d "output/library" ] && echo "✅ $(ls output/library/ | wc -l) files" || echo "❌ Not found")"
    
    print_info "=== Docker Images ==="
    echo "Runtime image: $(docker images $RUNTIME_IMAGE --format "{{.CreatedSince}} ({{.Size}})" 2>/dev/null || echo "❌ Not built")"
    echo "Builder image: $(docker images $BUILDER_IMAGE --format "{{.CreatedSince}} ({{.Size}})" 2>/dev/null || echo "❌ Not built")"
    
    print_info "=== X11 and GPU Status ==="
    echo "DISPLAY: ${DISPLAY:-"(not set)"}"
    echo "XDG_RUNTIME_DIR: $([ -d "/run/user/$(id -u)" ] && echo "/run/user/$(id -u)" || echo "fallback mode")"
    echo "GPU devices: $([ -e "/dev/dri" ] && echo "✅ Available" || echo "❌ Not found")"
    echo "xhost: $(command -v xhost &> /dev/null && echo "✅ Available" || echo "❌ Not found")"
    
    print_info "=== dreamOS Integration ==="
    local env_file="/home/$(whoami)/.dk/dk_swupdate/dk_swupdate_env.sh"
    echo "Environment file: $([ -f "$env_file" ] && echo "✅ Found" || echo "❌ Not found")"
    echo "Data directory: $([ -d "$HOME/.dk" ] && echo "✅ $HOME/.dk" || echo "❌ Not found")"
}

remove_container() {
    load_config
    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        print_warning "Removing container '$CONTAINER_NAME'..."
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME
        print_status "✅ Container removed"
    else
        print_warning "Container '$CONTAINER_NAME' does not exist"
    fi
}

# Main execution
case $ACTION in
    "help"|"-h"|"--help")
        show_help
        ;;
    "create-config")
        create_config_file
        ;;
    "show-config")
        show_config
        ;;
    "check")
        check_system_requirements
        ;;
    "run")
        run_container
        ;;
    "run-fg")
        run_interactive
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
    "remove"|"rm")
        remove_container
        ;;
    *)
        echo "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac