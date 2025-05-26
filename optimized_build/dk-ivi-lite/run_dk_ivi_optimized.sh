#!/bin/bash

# Enhanced run script for dk_ivi application
# Works with output from build_optimized.sh with GUI support and configuration
# Corrected to align with build_optimized.sh run_application() function

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
CONTAINER_NAME="dk_ivi_run"
BUILDER_IMAGE="dk-ivi-builder"
RUNTIME_IMAGE="dk-ivi-runtime"
ACTION=${1:-"run"}

# Default parameters (can be overridden with environment variables or config file)
DK_USER=${DK_USER:-"$(whoami)"}
DOCKER_HUB_NAMESPACE=${DOCKER_HUB_NAMESPACE:-"local"}
ARCH=${ARCH:-"$(uname -m)"}
HOME_DIR=${HOME_DIR:-"$HOME"}

# Additional configurable parameters
RESTART_POLICY=${RESTART_POLICY:-"no"}
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
            
            # Export the variable
            case "$key" in
                CONTAINER_NAME|BUILDER_IMAGE|RUNTIME_IMAGE|DK_USER|DOCKER_HUB_NAMESPACE|ARCH|HOME_DIR|RESTART_POLICY|LOG_MAX_SIZE|LOG_MAX_FILES|QT_BACKEND|MOUNT_MODE|EXTRA_VOLUMES|EXTRA_ENV_VARS|EXTRA_DOCKER_ARGS|ENABLE_GPU|X11_FORWARDING|RUN_MODE)
                    declare -g "$key=$value"
                    ;;
            esac
        done < "$CONFIG_FILE"
        
        print_info "Configuration loaded successfully"
    else
        print_info "No config file found ($CONFIG_FILE), using defaults"
        print_info "Creating config file with current values for future use..."
        create_config_file
        print_info "You can edit $CONFIG_FILE to customize settings for next run"
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
    
    # Use actual current values instead of placeholders
    cat > "$CONFIG_FILE" << EOF
# dk_ivi Run Configuration
# Auto-generated with current runtime values
# Edit these values to customize container behavior

# Container and Image Settings
CONTAINER_NAME=$CONTAINER_NAME
BUILDER_IMAGE=$BUILDER_IMAGE
RUNTIME_IMAGE=$RUNTIME_IMAGE

# Application Settings
DK_USER=$DK_USER
DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE
ARCH=$ARCH
HOME_DIR=$HOME_DIR

# Docker Runtime Settings
RESTART_POLICY=$RESTART_POLICY        # no/unless-stopped/always
LOG_MAX_SIZE=$LOG_MAX_SIZE
LOG_MAX_FILES=$LOG_MAX_FILES
QT_BACKEND=$QT_BACKEND
MOUNT_MODE=$MOUNT_MODE
RUN_MODE=$RUN_MODE                    # detached/interactive

# GUI and Hardware Settings
ENABLE_GPU=$ENABLE_GPU          # auto/true/false - GPU hardware acceleration
X11_FORWARDING=$X11_FORWARDING  # auto/true/false - X11 display forwarding

# Advanced Settings
# Extra volume mounts (format: "-v host:container -v host2:container2")
EXTRA_VOLUMES="$EXTRA_VOLUMES"

# Extra environment variables (format: "-e VAR1=value1 -e VAR2=value2")
EXTRA_ENV_VARS="$EXTRA_ENV_VARS"

# Extra Docker arguments (any additional docker run arguments)
EXTRA_DOCKER_ARGS="$EXTRA_DOCKER_ARGS"

# Examples of what you can add:
# EXTRA_VOLUMES="-v /my/config:/app/config -v /my/data:/app/data"
# EXTRA_ENV_VARS="-e DEBUG_MODE=1 -e LOG_LEVEL=debug"
# EXTRA_DOCKER_ARGS="--privileged --cap-add=SYS_ADMIN"

# GUI Examples:
# ENABLE_GPU=false              # Force software rendering
# X11_FORWARDING=true           # Force X11 forwarding
# QT_BACKEND=opengl             # Use OpenGL backend instead of software
# RUN_MODE=interactive          # Run in foreground with direct output
EOF
    
    print_status "✅ Configuration file created: $CONFIG_FILE"
    print_info "Config contains your current runtime values:"
    print_info "  User: $DK_USER"
    print_info "  Home: $HOME_DIR" 
    print_info "  Architecture: $ARCH"
    print_info "  Run Mode: $RUN_MODE"
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
    echo "🖥️  GUI Support:"
    echo "   • Automatic X11 forwarding detection"
    echo "   • Hardware GPU acceleration (when available)"
    echo "   • Software fallback rendering"
    echo "   • XDG runtime directory setup"
    echo ""
    echo "Environment Variables (can also be set in config file):"
    echo "  DK_USER                 - User name (default: current user)"
    echo "  DOCKER_HUB_NAMESPACE    - Docker namespace (default: 'local')"
    echo "  ARCH                    - Architecture (default: auto-detected)"
    echo "  HOME_DIR                - Home directory (default: \$HOME)"
    echo "  RESTART_POLICY          - Docker restart policy (default: 'no')"
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
    
    print_info "=== Recommendations ==="
    print_help "For best GUI performance:"
    print_help "  1. Ensure your user is in the 'docker' group"
    print_help "  2. Install x11-xserver-utils for X11 forwarding"
    print_help "  3. Set DISPLAY environment variable if not set"
    print_help "  4. Run 'xhost +local:docker' before starting GUI apps"
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
    # Set up X11 forwarding and runtime environment (following build_optimized.sh pattern)
    local runtime_dir="/run/user/$(id -u)"
    
    # Ensure XDG_RUNTIME_DIR exists
    if [ ! -d "$runtime_dir" ]; then
        print_warning "XDG_RUNTIME_DIR $runtime_dir does not exist, using /tmp/runtime-$(id -u)"
        runtime_dir="/tmp/runtime-$(id -u)"
        mkdir -p "$runtime_dir"
    fi
    
    # Set up DISPLAY
    if [ -z "$DISPLAY" ] && [[ "$X11_FORWARDING" != "false" ]]; then
        print_warning "DISPLAY not set, using :0"
        export DISPLAY=":0"
    fi
    
    # Enable X11 forwarding for Docker (following build_optimized.sh pattern)
    if [[ "$X11_FORWARDING" == "true" ]] || [[ "$X11_FORWARDING" == "auto" && -n "$DISPLAY" ]]; then
        print_info "Enabling X11 forwarding for Docker..."
        xhost +local:docker >/dev/null 2>&1 || {
            print_warning "Failed to run 'xhost +local:docker'"
            print_info "X11 forwarding may not work properly"
            print_info "Try: sudo apt-get install x11-xserver-utils"
        }
        
        X11_OPTS="-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw"
        print_info "X11 Display: $DISPLAY"
    else
        X11_OPTS=""
        print_info "X11 forwarding disabled"
    fi
    
    XDG_RUNTIME_DIR="$runtime_dir"
    print_info "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
    
    # Check GPU setup (following build_optimized.sh pattern)
    if [[ "$ENABLE_GPU" == "true" ]] || [[ "$ENABLE_GPU" == "auto" && -e "/dev/dri" ]]; then
        if [ -e "/dev/dri" ]; then
            GPU_OPTS="--device=/dev/dri:/dev/dri"
            print_info "GPU hardware acceleration enabled"
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
    print_info "=== Container Run Parameters ==="
    echo "Container Name:         $CONTAINER_NAME"
    echo "Runtime Image:          $RUNTIME_IMAGE"
    echo "Executable Source:      $(pwd)/output/dk_ivi"
    echo "Libraries Source:       $(pwd)/output/library/"
    echo "Display:                ${DISPLAY:-"(not set)"}"
    echo "XDG Runtime Dir:        $XDG_RUNTIME_DIR"
    echo "Qt Backend:             $QT_BACKEND"
    echo "Run Mode:               $RUN_MODE"
    echo "Restart Policy:         $RESTART_POLICY"
    echo "Log Settings:           max-size=$LOG_MAX_SIZE, max-file=$LOG_MAX_FILES"
    echo "Mount Mode:             $MOUNT_MODE"
    echo "GPU Support:            $ENABLE_GPU"
    echo "X11 Forwarding:         $X11_FORWARDING"
    echo "DK User:                $DK_USER"
    echo "Docker Namespace:       $DOCKER_HUB_NAMESPACE"
    echo "Architecture:           $ARCH"
    echo "Home Directory:         $HOME_DIR"
    [ -n "$EXTRA_VOLUMES" ] && echo "Extra Volumes:          $EXTRA_VOLUMES"
    [ -n "$EXTRA_ENV_VARS" ] && echo "Extra Environment:      $EXTRA_ENV_VARS"
    [ -n "$EXTRA_DOCKER_ARGS" ] && echo "Extra Docker Args:      $EXTRA_DOCKER_ARGS"
    echo ""
}

run_container() {
    load_config
    check_build_output
    check_runtime_image
    setup_x11_and_gpu
    
    # Stop existing container if running (only for detached mode)
    if [[ "$RUN_MODE" == "detached" ]] && docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_warning "Container '$CONTAINER_NAME' is already running"
        print_info "Stopping existing container..."
        docker stop $CONTAINER_NAME >/dev/null
        docker rm $CONTAINER_NAME >/dev/null
    fi
    
    print_run_parameters
    
    print_status "Starting dk_ivi application..."
    
    # Build docker run command following build_optimized.sh pattern
    if [[ "$RUN_MODE" == "interactive" ]] || [[ "$ACTION" == "run-fg" ]]; then
        # Interactive mode (foreground) - matches build_optimized.sh run_application()
        docker_cmd="docker run --rm -it \
            --network host \
            -e DISPLAY=$DISPLAY \
            -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
            -v $XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR \
            -v /dev/shm:/dev/shm \
            -v $(pwd)/output:/app/exec:$MOUNT_MODE \
            -e LD_LIBRARY_PATH=/app/exec/library \
            -e QML_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt6/qml \
            -e QT_QUICK_BACKEND=$QT_BACKEND"
    else
        # Detached mode (background)
        docker_cmd="docker run -d -it \
            --name $CONTAINER_NAME \
            --restart $RESTART_POLICY \
            --log-opt max-size=$LOG_MAX_SIZE \
            --log-opt max-file=$LOG_MAX_FILES \
            --network host \
            -e DISPLAY=$DISPLAY \
            -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
            -v $XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR \
            -v /dev/shm:/dev/shm \
            -v $(pwd)/output:/app/exec:$MOUNT_MODE \
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
        
        # Check if container started successfully
        if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
            print_status "✅ Container started successfully!"
            print_info "Container ID: $(docker ps -q -f name=$CONTAINER_NAME)"
            print_info "View logs with: $0 logs"
            print_info "Open shell with: $0 shell"
            
            # Show running status
            sleep 2
            if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
                print_status "dk_ivi application is running in background"
                print_info "GUI should be available on display: $DISPLAY"
            else
                print_warning "Container may have stopped. Check logs: $0 logs"
            fi
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
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_status "Stopping container '$CONTAINER_NAME'..."
        docker stop $CONTAINER_NAME
        print_status "✅ Container stopped"
    else
        print_warning "Container '$CONTAINER_NAME' is not running"
    fi
}

restart_container() {
    print_status "Restarting container '$CONTAINER_NAME'..."
    stop_container
    sleep 2
    run_container
}

show_logs() {
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
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_status "Opening shell in container '$CONTAINER_NAME'..."
        docker exec -it $CONTAINER_NAME /bin/bash
    else
        print_error "Container '$CONTAINER_NAME' is not running"
        print_info "Start it first with: $0 run"
    fi
}

show_status() {
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
}

remove_container() {
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