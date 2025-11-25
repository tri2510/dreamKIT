#!/bin/bash
# Docker-based dreamKIT deployment script
# Replaces K3s with Docker Compose for easier management

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Unicode symbols
CHECKMARK="✓"
CROSS="✗"
ARROW="→"
GEAR="⚙"
ROCKET="🚀"

# Default values
COMPOSE_FILE="docker-compose.yml"
SERVICES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SERVICES_DIR}/.env"

# Load environment variables
load_environment() {
    # Set default values
    export DK_USER="${DK_USER:-$(whoami)}"
    export RUNTIME_NAME="${RUNTIME_NAME:-dreamkit-runtime}"
    export ARCH="${ARCH:-$(uname -m)}"
    export DOCKER_HUB_NAMESPACE="${DOCKER_HUB_NAMESPACE:-ghcr.io/eclipse-autowrx}"
    export DISPLAY="${DISPLAY:-:0}"
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
    export HOME_DIR="${HOME_DIR:-$HOME}"

    # Create .env file for Docker Compose
    cat > "$ENV_FILE" << EOF
DK_USER=$DK_USER
RUNTIME_NAME=$RUNTIME_NAME
ARCH=$ARCH
DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE
DISPLAY=$DISPLAY
XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
HOME_DIR=$HOME_DIR
EOF
}

# Utility functions
show_info() {
    echo -e "${BLUE} ${ARROW} ${1}${NC}"
}

show_success() {
    echo -e "${GREEN}${BOLD} ${CHECKMARK} ${1}${NC}"
}

show_error() {
    echo -e "${RED}${BOLD} ${CROSS} ${1}${NC}"
}

show_warning() {
    echo -e "${YELLOW}${BOLD} ⚠ ${1}${NC}"
}

# Check Docker availability
check_docker() {
    if ! command -v docker &> /dev/null; then
        show_error "Docker is not installed or not in PATH"
        return 1
    fi

    if ! docker info &> /dev/null; then
        show_error "Docker daemon is not running or user lacks permissions"
        show_info "Try: sudo systemctl start docker"
        show_info "And ensure your user is in the docker group"
        return 1
    fi

    # Prefer modern docker compose plugin, fallback to docker-compose
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        show_success "Using modern Docker Compose plugin"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
        show_warning "Using legacy docker-compose (consider upgrading to docker compose plugin)"
    else
        show_error "Docker Compose is not available"
        show_info "Install it with: sudo apt install docker-compose-plugin"
        return 1
    fi

    # Test Docker Compose connectivity
    if ! $COMPOSE_CMD --version &> /dev/null; then
        show_error "Docker Compose is not working properly"
        show_info "Try restarting Docker: sudo systemctl restart docker"
        return 1
    fi

    show_success "Docker and Docker Compose are ready"
    return 0
}

# Initialize directories
init_directories() {
    show_info "Initializing dreamKIT directories..."

    # Create necessary directories
    local dirs=(
        "$HOME_DIR/.dk/sdv-runtime"
        "$HOME_DIR/.dk/dk_swupdate"
        "$HOME_DIR/.dk/dk_swupdate/dk_patch"
        "$HOME_DIR/.dk/dk_swupdate/dk_current"
        "$HOME_DIR/.dk/dk_swupdate/dk_current_patch"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" 2>/dev/null || {
            show_error "Failed to create directory: $dir"
            return 1
        }
    done

    show_success "Directories initialized"
}

# Pull all required images
pull_images() {
    show_info "Pulling Docker images..."

    local images=(
        "eclipse-mosquitto:2.0.14"
        "ghcr.io/eclipse-autowrx/sdv-runtime:latest"
        "${DOCKER_HUB_NAMESPACE}/dk_manager:latest"
        "${DOCKER_HUB_NAMESPACE}/dk_ivi:latest"
        "registry:2.8"
    )

    for image in "${images[@]}"; do
        show_info "Pulling $image..."
        if docker pull "$image"; then
            show_success "$image pulled successfully"
        else
            show_error "Failed to pull $image"
            return 1
        fi
    done
}

# Deploy core services
deploy_core_services() {
    show_info "Deploying core dreamKIT services..."

    cd "$SERVICES_DIR"

    # Deploy without IVI and registry first
    if $COMPOSE_CMD --env-file "$ENV_FILE" up -d mqtt-broker sdv-runtime dk-manager; then
        show_success "Core services deployed successfully"
        return 0
    else
        show_error "Failed to deploy core services"
        return 1
    fi
}

# Deploy IVI service (optional)
deploy_ivi_service() {
    if [[ "$dk_ivi_value" == "true" ]]; then
        show_info "Deploying IVI interface..."

        cd "$SERVICES_DIR"
        if $COMPOSE_CMD --env-file "$ENV_FILE" --profile ivi up -d dk-ivi; then
            show_success "IVI interface deployed successfully"
            show_info "Access IVI interface at: http://localhost:8080"
            return 0
        else
            show_error "Failed to deploy IVI interface"
            return 1
        fi
    else
        show_info "Skipping IVI interface deployment (dk_ivi=false)"
        return 0
    fi
}

# Deploy local registry (optional)
deploy_local_registry() {
    show_info "Deploying local Docker registry..."

    cd "$SERVICES_DIR"
    if $COMPOSE_CMD --env-file "$ENV_FILE" --profile registry up -d local-registry; then
        show_success "Local registry deployed successfully"
        show_info "Local registry available at: http://localhost:5000"
        return 0
    else
        show_error "Failed to deploy local registry"
        return 1
    fi
}

# Wait for services to be healthy
wait_for_services() {
    show_info "Waiting for services to be healthy..."

    local services=("mqtt-broker" "sdv-runtime" "dk-manager")
    local max_attempts=30
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        local all_healthy=true

        for service in "${services[@]}"; do
            local container_name="dreamkit-${service}"
            local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")

            if [[ "$health" == "healthy" ]]; then
                echo -e "${GREEN}  ✓ $service is healthy${NC}"
            elif [[ "$health" == "unknown" ]]; then
                # Check if container is running (no healthcheck)
                if docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
                    echo -e "${GREEN}  ✓ $service is running${NC}"
                else
                    echo -e "${YELLOW}  ⏳ $service is starting...${NC}"
                    all_healthy=false
                fi
            else
                echo -e "${YELLOW}  ⏳ $service health: $health${NC}"
                all_healthy=false
            fi
        done

        if $all_healthy; then
            show_success "All services are healthy!"
            return 0
        fi

        echo -e "${DIM}  Waiting... (attempt $attempt/$max_attempts)${NC}"
        sleep 10
        ((attempt++))
    done

    show_error "Services did not become healthy within expected time"
    return 1
}

# Show service status
show_status() {
    show_info "dreamKIT Service Status:"
    echo

    cd "$SERVICES_DIR"
    docker-compose --env-file "$ENV_FILE" ps

    echo
    show_info "Service URLs:"
    echo -e "${CYAN}  • MQTT Broker:      mqtt://localhost:1883${NC}"
    echo -e "${CYAN}  • MQTT WebSocket:    ws://localhost:9001${NC}"
    echo -e "${CYAN}  • SDV Runtime:       tcp://localhost:55555${NC}"
    if [[ "$dk_ivi_value" == "true" ]]; then
        echo -e "${CYAN}  • IVI Interface:    http://localhost:8080${NC}"
    fi
    echo -e "${CYAN}  • Local Registry:   http://localhost:5000${NC}"
}

# Cleanup function
cleanup() {
    show_info "Cleaning up temporary files..."
    rm -f "$ENV_FILE"
}

# Main deployment function
deploy() {
    echo -e "${BLUE}${BOLD}dreamKIT Docker-based Deployment${NC}"
    echo -e "${DIM}Deploying dreamKIT services using Docker Compose${NC}"
    echo

    # Load environment variables
    load_environment

    # Check prerequisites
    if ! check_docker; then
        cleanup
        exit 1
    fi

    # Initialize system
    if ! init_directories; then
        cleanup
        exit 1
    fi

    # Pull images
    if ! pull_images; then
        cleanup
        exit 1
    fi

    # Deploy services
    if ! deploy_core_services; then
        cleanup
        exit 1
    fi

    if ! deploy_ivi_service; then
        cleanup
        exit 1
    fi

    # Deploy local registry
    if ! deploy_local_registry; then
        # This is optional, so don't fail the deployment
        show_warning "Local registry deployment failed, continuing..."
    fi

    # Wait for services to be healthy
    wait_for_services

    # Show final status
    show_status

    show_success "dreamKIT deployment completed successfully!"
    echo
    echo -e "${CYAN}${BOLD}🚀 dreamKIT is ready!${NC}"
    echo -e "${DIM}Use './docker-manage.sh status' to check service status${NC}"
    echo -e "${DIM}Use './docker-manage.sh logs <service>' to view logs${NC}"

    cleanup
}

# Handle command line arguments
dk_ivi_value="true"  # Default
for arg in "$@"; do
    case "$arg" in
        dk_ivi=*)
            dk_ivi_value="${arg#*=}"
            ;;
        help|--help|-h)
            echo "dreamKIT Docker Deployment Script"
            echo
            echo "Usage: $0 [dk_ivi=true|false]"
            echo
            echo "Options:"
            echo "  dk_ivi=true|false  Enable/disable IVI interface (default: true)"
            echo "  help               Show this help message"
            exit 0
            ;;
    esac
done

# Run deployment
deploy "$@"