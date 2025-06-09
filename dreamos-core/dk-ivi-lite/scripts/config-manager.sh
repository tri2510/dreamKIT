#!/bin/bash

# ==============================================
# DK IVI Configuration Manager
# ==============================================
# Centralized configuration validation and management

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
DEFAULT_CONFIG="$CONFIG_DIR/dk_ivi.yml"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[CONFIG]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ==============================================
# Configuration Loading Functions
# ==============================================

load_config() {
    local config_file="${1:-$DEFAULT_CONFIG}"
    
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    print_info "Loading configuration from: $config_file"
    
    # Parse YAML and export variables (simplified - would use yq in production)
    # For now, convert to environment variables
    parse_yaml_to_env "$config_file"
}

parse_yaml_to_env() {
    local config_file="$1"
    
    # Simple YAML parser for key-value extraction
    # In production, use 'yq' tool: yq eval '.app.name' config.yml
    
    # Extract main configuration values (handle comments with #)
    export DK_APP_NAME=$(grep "^[[:space:]]*name:" "$config_file" | head -1 | sed 's/.*name: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_LOG_LEVEL=$(grep "^[[:space:]]*log_level:" "$config_file" | head -1 | sed 's/.*log_level: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_CONTAINER_NAME=$(grep "^[[:space:]]*container_name:" "$config_file" | head -1 | sed 's/.*container_name: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_RESTART_POLICY=$(grep "^[[:space:]]*restart_policy:" "$config_file" | head -1 | sed 's/.*restart_policy: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_RUN_MODE=$(grep "^[[:space:]]*run_mode:" "$config_file" | head -1 | sed 's/.*run_mode: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_QT_BACKEND=$(grep "^[[:space:]]*qt_backend:" "$config_file" | head -1 | sed 's/.*qt_backend: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_ENABLE_GPU=$(grep "^[[:space:]]*enable_gpu:" "$config_file" | head -1 | sed 's/.*enable_gpu: *\([^#[:space:]]*\).*/\1/')
    export DK_X11_FORWARDING=$(grep "^[[:space:]]*x11_forwarding:" "$config_file" | head -1 | sed 's/.*x11_forwarding: *\([^#[:space:]]*\).*/\1/')
    export DK_VAPI_DATABROKER=$(grep "^[[:space:]]*vapi_databroker:" "$config_file" | head -1 | sed 's/.*vapi_databroker: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_SYSTEM_DATABROKER=$(grep "^[[:space:]]*system_databroker:" "$config_file" | head -1 | sed 's/.*system_databroker: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_CAN_INTERFACE=$(grep "^[[:space:]]*can_interface:" "$config_file" | head -1 | sed 's/.*can_interface: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    export DK_DOCKER_IMAGE=$(grep "^[[:space:]]*image:" "$config_file" | head -1 | sed 's/.*image: *"\?\([^"#]*\)"\?.*/\1/' | tr -d ' ')
    
    print_info "Configuration loaded and exported to environment"
}

# ==============================================
# Validation Functions
# ==============================================

validate_config() {
    print_status "Validating configuration..."
    
    local errors=0
    
    # Validate required fields
    [ -z "$DK_APP_NAME" ] && { print_error "app.name is required"; ((errors++)); }
    [ -z "$DK_CONTAINER_NAME" ] && { print_error "runtime.container_name is required"; ((errors++)); }
    [ -z "$DK_DOCKER_IMAGE" ] && { print_error "docker.image is required"; ((errors++)); }
    
    # Validate enums
    case "$DK_LOG_LEVEL" in
        debug|info|warn|error) ;;
        *) print_error "Invalid log_level: $DK_LOG_LEVEL (must be: debug, info, warn, error)"; ((errors++)) ;;
    esac
    
    case "$DK_QT_BACKEND" in
        software|opengl|vulkan) ;;
        *) print_error "Invalid qt_backend: $DK_QT_BACKEND (must be: software, opengl, vulkan)"; ((errors++)) ;;
    esac
    
    case "$DK_RUN_MODE" in
        detached|interactive) ;;
        *) print_error "Invalid run_mode: $DK_RUN_MODE (must be: detached, interactive)"; ((errors++)) ;;
    esac
    
    # Validate network endpoints
    if ! [[ "$DK_VAPI_DATABROKER" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
        print_error "Invalid vapi_databroker format: $DK_VAPI_DATABROKER (expected: IP:PORT)"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        print_status "✅ Configuration validation passed"
        return 0
    else
        print_error "❌ Configuration validation failed with $errors errors"
        return 1
    fi
}

# ==============================================
# Configuration Display Functions
# ==============================================

show_config() {
    print_info "=== Current Configuration ==="
    echo "Application:"
    echo "  Name:                 $DK_APP_NAME"
    echo "  Log Level:            $DK_LOG_LEVEL"
    echo ""
    echo "Runtime:"
    echo "  Container Name:       $DK_CONTAINER_NAME"
    echo "  Restart Policy:       $DK_RESTART_POLICY"
    echo "  Run Mode:             $DK_RUN_MODE"
    echo ""
    echo "Display:"
    echo "  Qt Backend:           $DK_QT_BACKEND"
    echo "  GPU Enabled:          $DK_ENABLE_GPU"
    echo "  X11 Forwarding:       $DK_X11_FORWARDING"
    echo ""
    echo "Network:"
    echo "  VAPI DataBroker:      $DK_VAPI_DATABROKER"
    echo "  System DataBroker:    $DK_SYSTEM_DATABROKER"
    echo ""
    echo "Vehicle:"
    echo "  CAN Interface:        $DK_CAN_INTERFACE"
    echo ""
    echo "Docker:"
    echo "  Image:                $DK_DOCKER_IMAGE"
}

# ==============================================
# Configuration Generation Functions
# ==============================================

generate_docker_args() {
    print_info "Generating Docker arguments from configuration..."
    
    # Base Docker arguments
    local docker_args=""
    
    # Container name and restart policy
    docker_args="$docker_args --name $DK_CONTAINER_NAME"
    docker_args="$docker_args --restart $DK_RESTART_POLICY"
    
    # Network configuration
    docker_args="$docker_args --network host"
    
    # Environment variables
    docker_args="$docker_args -e DKCODE=dreamKIT"
    docker_args="$docker_args -e DK_LOG_LEVEL=$DK_LOG_LEVEL"
    docker_args="$docker_args -e DK_CAN_INTERFACE=$DK_CAN_INTERFACE"
    docker_args="$docker_args -e DK_VAPI_DATABROKER=$DK_VAPI_DATABROKER"
    docker_args="$docker_args -e DK_SYSTEM_DATABROKER=$DK_SYSTEM_DATABROKER"
    docker_args="$docker_args -e QT_QUICK_BACKEND=$DK_QT_BACKEND"
    
    # Display configuration
    if [ "$DK_X11_FORWARDING" = "true" ]; then
        docker_args="$docker_args -e DISPLAY=$DISPLAY"
        docker_args="$docker_args -v /tmp/.X11-unix:/tmp/.X11-unix"
    fi
    
    # GPU configuration
    if [ "$DK_ENABLE_GPU" = "true" ] && [ -e "/dev/dri" ]; then
        docker_args="$docker_args --device /dev/dri:/dev/dri"
    fi
    
    # Standard volumes
    docker_args="$docker_args -v $HOME/.dk:/app/.dk"
    docker_args="$docker_args -v $(pwd)/output:/app/exec:ro"
    
    echo "$docker_args"
}

generate_app_args() {
    print_info "Generating application arguments from configuration..."
    
    local app_args=""
    
    # Configuration file path
    app_args="$app_args --config=/app/config/dk_ivi.yml"
    
    # Log level
    app_args="$app_args --log-level=$DK_LOG_LEVEL"
    
    # CAN interface
    app_args="$app_args --can-interface=$DK_CAN_INTERFACE"
    
    # Data broker endpoints
    app_args="$app_args --vapi-broker=$DK_VAPI_DATABROKER"
    app_args="$app_args --system-broker=$DK_SYSTEM_DATABROKER"
    
    echo "$app_args"
}

# ==============================================
# Main Functions
# ==============================================

show_help() {
    echo "Usage: $0 [COMMAND] [CONFIG_FILE]"
    echo ""
    echo "Commands:"
    echo "  load           - Load and validate configuration"
    echo "  show           - Display current configuration"
    echo "  validate       - Validate configuration file"
    echo "  docker-args    - Generate Docker run arguments"
    echo "  app-args       - Generate application arguments"
    echo "  help           - Show this help"
    echo ""
    echo "Config file defaults to: $DEFAULT_CONFIG"
    echo ""
    echo "Examples:"
    echo "  $0 load config/custom.yml"
    echo "  $0 show"
    echo "  $0 validate"
    echo "  $0 docker-args"
}

# ==============================================
# Main Execution
# ==============================================

COMMAND=${1:-"load"}
CONFIG_FILE=${2:-"$DEFAULT_CONFIG"}

case $COMMAND in
    "load")
        load_config "$CONFIG_FILE"
        validate_config
        ;;
    "show")
        load_config "$CONFIG_FILE"
        show_config
        ;;
    "validate")
        load_config "$CONFIG_FILE"
        validate_config
        ;;
    "docker-args")
        load_config "$CONFIG_FILE"
        validate_config && generate_docker_args
        ;;
    "app-args")
        load_config "$CONFIG_FILE"
        validate_config && generate_app_args
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac