#!/bin/bash

# Enhanced run script for dk-manager application
# Works with output from build_optimized.sh for dk-manager target

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
CONTAINER_NAME="dk_manager"
BUILDER_IMAGE="dk-ivi-builder"
RUNTIME_IMAGE="dk-ivi-runtime"
ACTION=${1:-"run"}

# Default parameters (can be overridden with environment variables or config file)
DK_USER=${DK_USER:-"$(whoami)"}
DOCKER_HUB_NAMESPACE=${DOCKER_HUB_NAMESPACE:-"ghcr.io/samtranbosch"}
ARCH=${ARCH:-"$(uname -m)"}
HOME_DIR=${HOME_DIR:-"$HOME"}

# Additional configurable parameters for dk-manager
RESTART_POLICY=${RESTART_POLICY:-"unless-stopped"}
LOG_MAX_SIZE=${LOG_MAX_SIZE:-"10m"}
LOG_MAX_FILES=${LOG_MAX_FILES:-"3"}
MOUNT_MODE=${MOUNT_MODE:-"ro"}
EXTRA_VOLUMES=${EXTRA_VOLUMES:-""}
EXTRA_ENV_VARS=${EXTRA_ENV_VARS:-""}
EXTRA_DOCKER_ARGS=${EXTRA_DOCKER_ARGS:-""}

# dk-manager specific settings from dk_install.sh reference
DOCKER_SHARE_PARAM=${DOCKER_SHARE_PARAM:-"-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker"}
MANAGER_EXECUTABLE=${MANAGER_EXECUTABLE:-"dk_manager"}

# Configuration file support
CONFIG_FILE=${CONFIG_FILE:-"dk_manager_config.conf"}

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
                CONTAINER_NAME|BUILDER_IMAGE|RUNTIME_IMAGE|DK_USER|DOCKER_HUB_NAMESPACE|ARCH|HOME_DIR|RESTART_POLICY|LOG_MAX_SIZE|LOG_MAX_FILES|MOUNT_MODE|EXTRA_VOLUMES|EXTRA_ENV_VARS|EXTRA_DOCKER_ARGS|DOCKER_SHARE_PARAM|MANAGER_EXECUTABLE)
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
# dk-manager Run Configuration
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
RESTART_POLICY=$RESTART_POLICY
LOG_MAX_SIZE=$LOG_MAX_SIZE
LOG_MAX_FILES=$LOG_MAX_FILES
MOUNT_MODE=$MOUNT_MODE

# dk-manager Specific Settings
DOCKER_SHARE_PARAM="$DOCKER_SHARE_PARAM"
MANAGER_EXECUTABLE=$MANAGER_EXECUTABLE

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

# dk-manager Examples:
# MANAGER_EXECUTABLE=manager              # If executable has different name
# DOCKER_SHARE_PARAM=""                   # Disable Docker socket sharing
EOF
    
    print_status "✅ Configuration file created: $CONFIG_FILE"
    print_info "Config contains your current runtime values:"
    print_info "  User: $DK_USER"
    print_info "  Home: $HOME_DIR" 
    print_info "  Architecture: $ARCH"
    print_info "  Manager Executable: $MANAGER_EXECUTABLE"
    print_info "Edit this file to customize your container settings, then run: $0 run"
}

show_config() {
    load_config
    print_info "=== Current dk-manager Configuration ==="
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
    echo "Mount Mode:             $MOUNT_MODE"
    echo "Manager Executable:     $MANAGER_EXECUTABLE"
    echo "Docker Socket Sharing:  ${DOCKER_SHARE_PARAM:-"(disabled)"}"
    echo "Extra Volumes:          ${EXTRA_VOLUMES:-"(none)"}"
    echo "Extra Environment:      ${EXTRA_ENV_VARS:-"(none)"}"
    echo "Extra Docker Args:      ${EXTRA_DOCKER_ARGS:-"(none)"}"
}

show_help() {
    echo "Usage: $0 [ACTION] [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  run           - Run dk-manager container (default)"
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
    echo "🚀 This script runs the dk-manager application built by build_optimized.sh"
    echo "   Make sure to run './build_optimized.sh build dk-manager' first!"
    echo ""
    echo "📁 Configuration:"
    echo "   Config file: $CONFIG_FILE (use CONFIG_FILE=path to override)"
    echo "   Run '$0 create-config' to create/update config file"
    echo ""
    echo "🔧 dk-manager Features:"
    echo "   • Docker socket sharing for container orchestration"
    echo "   • DreamOS application lifecycle management"
    echo "   • VSS (Vehicle Signal Specification) integration"
    echo "   • Software update and patch management"
    echo ""
    echo "Environment Variables (can also be set in config file):"
    echo "  DK_USER                 - User name (default: current user)"
    echo "  DOCKER_HUB_NAMESPACE    - Docker namespace (default: 'ghcr.io/samtranbosch')"
    echo "  ARCH                    - Architecture (default: auto-detected)"
    echo "  HOME_DIR                - Home directory (default: \$HOME)"
    echo "  RESTART_POLICY          - Docker restart policy (default: 'unless-stopped')"
    echo "  MANAGER_EXECUTABLE      - Executable name (default: 'dk_manager')"
    echo "  DOCKER_SHARE_PARAM      - Docker socket sharing options"
    echo ""
    echo "Examples:"
    echo "  $0 create-config        # Create/update config file"
    echo "  $0 check                # Check system requirements"
    echo "  $0 run                  # Run with config/defaults"
    echo "  CONFIG_FILE=my.conf $0 run  # Use custom config file"
    echo "  $0 show-config          # Show current settings"
    echo "  MANAGER_EXECUTABLE=manager $0 run # Use different executable name"
}

check_system_requirements() {
    print_info "=== System Requirements Check ==="
    
    # Check Docker
    if command -v docker &> /dev/null; then
        echo "Docker: ✅ Available ($(docker --version | cut -d' ' -f3 | cut -d',' -f1))"
        
        # Check if Docker daemon is running
        if docker ps &> /dev/null; then
            echo "Docker daemon: ✅ Running"
            
            # Check Docker socket access (important for dk-manager)
            if [ -S "/var/run/docker.sock" ]; then
                echo "Docker socket: ✅ Available"
                if docker info &> /dev/null; then
                    echo "Docker socket access: ✅ Working"
                else
                    echo "Docker socket access: ⚠️  Limited (may need to add user to docker group)"
                fi
            else
                echo "Docker socket: ❌ Not found"
                print_warning "dk-manager needs Docker socket access for container management"
            fi
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
    if [ -d "output/dk-manager" ] && [ "$(ls -A output/dk-manager/ 2>/dev/null)" ]; then
        echo "dk-manager build output: ✅ Found"
        
        # Look for executables
        local exec_count=0
        for file in output/dk-manager/*; do
            if [ -f "$file" ] && [ -x "$file" ]; then
                echo "  - $(basename "$file") ($(ls -lh "$file" | awk '{print $5}'))"
                exec_count=$((exec_count + 1))
            fi
        done
        
        if [ $exec_count -eq 0 ]; then
            echo "dk-manager executables: ⚠️  No executable files found"
            print_warning "Check if build completed successfully"
        else
            echo "dk-manager executables: ✅ $exec_count found"
        fi
    else
        echo "dk-manager build output: ❌ Not found"
        print_warning "Run './build_optimized.sh build dk-manager' to build the application"
    fi
    
    # Check runtime image
    if docker images $RUNTIME_IMAGE | grep -q $RUNTIME_IMAGE; then
        echo "Runtime image: ✅ Available"
    else
        echo "Runtime image: ❌ Not found"
        print_warning "Run './build_optimized.sh images' to build runtime image"
    fi
    
    # Check DreamOS data directory
    print_info "=== DreamOS Data Directory ==="
    
    local dk_dir="$HOME_DIR/.dk"
    if [ -d "$dk_dir" ]; then
        echo "DreamOS data dir: ✅ $dk_dir"
        
        # Check subdirectories that dk-manager needs
        local subdirs=("dk_swupdate" "dk_marketplace" "dk_manager")
        for subdir in "${subdirs[@]}"; do
            if [ -d "$dk_dir/$subdir" ]; then
                echo "  - $subdir: ✅"
            else
                echo "  - $subdir: ⚠️  Missing (will be created)"
            fi
        done
    else
        echo "DreamOS data dir: ⚠️  Will create $dk_dir"
    fi
    
    print_info "=== dk-manager Specific Checks ==="
    
    # Check if user is in docker group (important for dk-manager Docker operations)
    if groups "$DK_USER" | grep -q docker; then
        echo "Docker group membership: ✅ User '$DK_USER' is in docker group"
    else
        echo "Docker group membership: ❌ User '$DK_USER' not in docker group"
        print_warning "dk-manager may not be able to manage Docker containers"
        print_help "Add user to docker group: sudo usermod -aG docker $DK_USER"
    fi
    
    # Check if dk_network exists (used by dreamOS applications)
    if docker network ls | grep -q dk_network; then
        echo "dk_network: ✅ Available"
    else
        echo "dk_network: ⚠️  Not found (will be created if needed)"
        print_info "dk-manager can create Docker networks as needed"
    fi
    
    print_info "=== Recommendations ==="
    print_help "For optimal dk-manager operation:"
    print_help "  1. Ensure your user is in the 'docker' group"
    print_help "  2. Keep Docker daemon running"
    print_help "  3. Ensure /var/run/docker.sock is accessible"
    print_help "  4. Run dk-manager with appropriate permissions"
}

check_build_output() {
    if [ ! -d "output/dk-manager" ] || [ ! "$(ls -A output/dk-manager/ 2>/dev/null)" ]; then
        print_error "Built application not found in output/dk-manager/"
        print_info "Please build first with: ./build_optimized.sh build dk-manager"
        exit 1
    fi
    
    # Find the executable to run
    local found_executable=""
    
    # First try the configured executable name
    if [ -f "output/dk-manager/$MANAGER_EXECUTABLE" ]; then
        found_executable="$MANAGER_EXECUTABLE"
    else
        # Look for any executable file
        for file in output/dk-manager/*; do
            if [ -f "$file" ] && [ -x "$file" ]; then
                found_executable="$(basename "$file")"
                break
            fi
        done
    fi
    
    if [ -z "$found_executable" ]; then
        print_error "No executable found in output/dk-manager/"
        print_info "Available files:"
        ls -la output/dk-manager/ 2>/dev/null | sed 's/^/  /'
        exit 1
    fi
    
    # Update the executable name if we found a different one
    if [ "$found_executable" != "$MANAGER_EXECUTABLE" ]; then
        print_warning "Configured executable '$MANAGER_EXECUTABLE' not found"
        print_info "Using found executable: $found_executable"
        MANAGER_EXECUTABLE="$found_executable"
    fi
    
    print_info "Found dk-manager executable: $found_executable ($(ls -lh "output/dk-manager/$found_executable" | awk '{print $5}'))"
}

check_runtime_image() {
    if ! docker images $RUNTIME_IMAGE | grep -q $RUNTIME_IMAGE; then
        print_error "Runtime image '$RUNTIME_IMAGE' not found!"
        print_info "Please build the images first with: ./build_optimized.sh images"
        exit 1
    fi
}

setup_docker_environment() {
    # Ensure dk_network exists
    if ! docker network ls | grep -q dk_network; then
        print_info "Creating dk_network for dreamOS applications..."
        docker network create dk_network 2>/dev/null || {
            print_warning "Failed to create dk_network (may already exist)"
        }
    fi
    
    print_info "Docker network 'dk_network' ready"
}

print_run_parameters() {
    print_info "=== dk-manager Container Run Parameters ==="
    echo "Container Name:         $CONTAINER_NAME"
    echo "Runtime Image:          $RUNTIME_IMAGE"
    echo "Executable Source:      $(pwd)/output/dk-manager/$MANAGER_EXECUTABLE"
    echo "Restart Policy:         $RESTART_POLICY"
    echo "Log Settings:           max-size=$LOG_MAX_SIZE, max-file=$LOG_MAX_FILES"
    echo "Mount Mode:             $MOUNT_MODE"
    echo "DK User:                $DK_USER"
    echo "Docker Namespace:       $DOCKER_HUB_NAMESPACE"
    echo "Architecture:           $ARCH"
    echo "Home Directory:         $HOME_DIR"
    echo "Data Directory:         $HOME_DIR/.dk"
    echo "Container Data Path:    /app/.dk/"
    echo "Docker Socket Sharing:  ${DOCKER_SHARE_PARAM:-"(disabled)"}"
    [ -n "$EXTRA_VOLUMES" ] && echo "Extra Volumes:          $EXTRA_VOLUMES"
    [ -n "$EXTRA_ENV_VARS" ] && echo "Extra Environment:      $EXTRA_ENV_VARS"
    [ -n "$EXTRA_DOCKER_ARGS" ] && echo "Extra Docker Args:      $EXTRA_DOCKER_ARGS"
    echo ""
}

run_container() {
    load_config
    check_build_output
    check_runtime_image
    setup_docker_environment
    
    # Stop existing container if running
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_warning "Container '$CONTAINER_NAME' is already running"
        print_info "Stopping existing container..."
        docker stop $CONTAINER_NAME >/dev/null
        docker rm $CONTAINER_NAME >/dev/null
    fi
    
    # Ensure data directory and subdirectories exist
    mkdir -p "$HOME_DIR/.dk"/{dk_swupdate,dk_marketplace,dk_manager}
    
    # Create required environment files if they don't exist
    local env_file="$HOME_DIR/.dk/dk_swupdate/dk_swupdate_env.sh"
    if [ ! -f "$env_file" ]; then
        print_info "Creating environment file: $env_file"
        cat > "$env_file" << EOF
#!/bin/bash
DK_USER="$DK_USER"
ARCH="$ARCH"
HOME_DIR="$HOME_DIR"
DOCKER_HUB_NAMESPACE="$DOCKER_HUB_NAMESPACE"
EOF
        chmod +x "$env_file"
    fi
    
    print_run_parameters
    
    print_status "Starting dk-manager container..."
    
    # Build docker run command with configurable parameters
    docker_cmd="docker run -d -it \
        --name $CONTAINER_NAME \
        --restart $RESTART_POLICY \
        --log-opt max-size=$LOG_MAX_SIZE \
        --log-opt max-file=$LOG_MAX_FILES \
        --network dk_network \
        -v $HOME_DIR/.dk:/app/.dk \
        -v $(pwd)/output/dk-manager:/app/exec:$MOUNT_MODE \
        -e USER=$DK_USER \
        -e DK_USER=$DK_USER \
        -e DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE \
        -e DK_ARCH=$ARCH \
        -e ARCH=$ARCH"
    
    # Add Docker socket sharing if enabled
    if [ -n "$DOCKER_SHARE_PARAM" ]; then
        docker_cmd="$docker_cmd $DOCKER_SHARE_PARAM"
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
    docker_cmd="$docker_cmd $RUNTIME_IMAGE /app/exec/$MANAGER_EXECUTABLE"
    
    # Execute the docker command
    eval $docker_cmd
    
    # Check if container started successfully
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_status "✅ dk-manager container started successfully!"
        print_info "Container ID: $(docker ps -q -f name=$CONTAINER_NAME)"
        print_info "View logs with: $0 logs"
        print_info "Open shell with: $0 shell"
        
        # Show running status
        sleep 2
        if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
            print_status "dk-manager is running in background"
            print_info "The manager handles:"
            print_info "  • Application lifecycle management"
            print_info "  • Docker container orchestration"
            print_info "  • Software updates and patches"
            print_info "  • VSS (Vehicle Signal Specification) management"
        else
            print_warning "Container may have stopped. Check logs: $0 logs"
        fi
    else
        print_error "❌ Failed to start container"
        print_info "Check logs with: docker logs $CONTAINER_NAME"
        exit 1
    fi
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
    print_info "=== dk-manager Container Status ==="
    
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
    if [ -d "output/dk-manager" ] && [ "$(ls -A output/dk-manager/ 2>/dev/null)" ]; then
        echo "Built dk-manager: ✅ $(ls output/dk-manager/ | wc -l) files"
        ls output/dk-manager/ 2>/dev/null | sed 's/^/  - /'
        
        # Check if configured executable exists
        if [ -f "output/dk-manager/$MANAGER_EXECUTABLE" ]; then
            echo "Target executable: ✅ $MANAGER_EXECUTABLE ($(ls -lh "output/dk-manager/$MANAGER_EXECUTABLE" | awk '{print $5}'))"
        else
            echo "Target executable: ❌ $MANAGER_EXECUTABLE not found"
        fi
    else
        echo "Built dk-manager: ❌ Not built"
    fi
    
    echo "Data directory: $HOME_DIR/.dk ($([ -d "$HOME_DIR/.dk" ] && echo "exists" || echo "missing"))"
    
    # Check DreamOS subdirectories
    local subdirs=("dk_swupdate" "dk_marketplace" "dk_manager")
    for subdir in "${subdirs[@]}"; do
        if [ -d "$HOME_DIR/.dk/$subdir" ]; then
            echo "  - $subdir: ✅"
        else
            echo "  - $subdir: ❌"
        fi
    done
    
    print_info "=== Docker Environment ==="
    if docker network ls | grep -q dk_network; then
        echo "dk_network: ✅ Available"
    else
        echo "dk_network: ❌ Missing"
    fi
    
    echo "Runtime image: $(docker images $RUNTIME_IMAGE --format "{{.CreatedSince}} ({{.Size}})" 2>/dev/null || echo "❌ Not built")"
    echo "Builder image: $(docker images $BUILDER_IMAGE --format "{{.CreatedSince}} ({{.Size}})" 2>/dev/null || echo "❌ Not built")"
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