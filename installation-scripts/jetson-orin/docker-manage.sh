#!/bin/bash
# Docker management script for dreamKIT services
# Replaces kubectl commands with Docker equivalents

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

# Service directory
SERVICES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SERVICES_DIR/docker-compose.yml"
ENV_FILE="$SERVICES_DIR/.env"

# Determine Docker Compose command
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "Error: Neither 'docker compose' nor 'docker-compose' is available" >&2
    exit 1
fi

# Load environment variables
load_environment() {
    export DK_USER="${DK_USER:-$(whoami)}"
    export RUNTIME_NAME="${RUNTIME_NAME:-dreamkit-runtime}"
    export ARCH="${ARCH:-$(uname -m)}"
    export DOCKER_HUB_NAMESPACE="${DOCKER_HUB_NAMESPACE:-eclipseautowrx}"
    export DISPLAY="${DISPLAY:-:0}"
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
    export HOME_DIR="${HOME_DIR:-$HOME}"

    # Recreate .env file if needed
    if [[ ! -f "$ENV_FILE" ]]; then
        cat > "$ENV_FILE" << EOF
DK_USER=$DK_USER
RUNTIME_NAME=$RUNTIME_NAME
ARCH=$ARCH
DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE
DISPLAY=$DISPLAY
XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
HOME_DIR=$HOME_DIR
EOF
    fi
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

# Check if Docker Compose is available
check_compose() {
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        show_error "docker-compose.yml not found in $SERVICES_DIR"
        return 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        show_error "Docker Compose is not available"
        return 1
    fi

    cd "$SERVICES_DIR"
    return 0
}

# Show service status
status() {
    show_info "dreamKIT Service Status:"
    echo

    if ! check_compose; then
        return 1
    fi

    load_environment

    # Docker Compose status
    echo -e "${CYAN}${BOLD}Docker Compose Services:${NC}"
    $COMPOSE_CMD --env-file "$ENV_FILE" ps
    echo

    # Detailed container information
    echo -e "${CYAN}${BOLD}Container Details:${NC}"
    local containers=("dreamkit-mqtt-broker" "dreamkit-sdv-runtime" "dreamkit-dk-manager" "dreamkit-dk-ivi")

    for container in "${containers[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
            local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "N/A")
            local uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container" 2>/dev/null | cut -d'.' -f1)

            echo -e "${GREEN}  ✓ $container${NC} - Status: $status, Health: $health"
            echo -e "${DIM}    Started: $uptime${NC}"
        else
            echo -e "${RED}  ✗ $container${NC} - Not running"
        fi
    done
    echo

    # Service URLs
    echo -e "${CYAN}${BOLD}Service Endpoints:${NC}"
    echo -e "${CYAN}  • MQTT Broker:      mqtt://localhost:1883${NC}"
    echo -e "${CYAN}  • MQTT WebSocket:    ws://localhost:9001${NC}"
    echo -e "${CYAN}  • SDV Runtime:       tcp://localhost:55555${NC}"

    # Check if IVI is running
    if docker ps --format '{{.Names}}' | grep -q "dreamkit-dk-ivi"; then
        echo -e "${CYAN}  • IVI Interface:    http://localhost:8080${NC}"
    fi

    # Check if registry is running
    if docker ps --format '{{.Names}}' | grep -q "dreamkit-local-registry"; then
        echo -e "${CYAN}  • Local Registry:   http://localhost:5000${NC}"
    fi
}

# Show logs for specific service
logs() {
    local service="$1"

    if ! check_compose; then
        return 1
    fi

    load_environment

    if [[ -z "$service" ]]; then
        show_error "Please specify a service (mqtt-broker, sdv-runtime, dk-manager, dk-ivi)"
        echo
        show_info "Usage: $0 logs <service-name>"
        return 1
    fi

    show_info "Showing logs for service: $service"

    # Map service names to container names
    case "$service" in
        "mqtt"|"mqtt-broker")
            container="dreamkit-mqtt-broker"
            ;;
        "sdv"|"sdv-runtime")
            container="dreamkit-sdv-runtime"
            ;;
        "manager"|"dk-manager")
            container="dreamkit-dk-manager"
            ;;
        "ivi"|"dk-ivi")
            container="dreamkit-dk-ivi"
            ;;
        *)
            container="dreamkit-$service"
            ;;
    esac

    # Show logs
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        docker logs -f --tail=100 "$container"
    else
        show_error "Container $container is not running"
        return 1
    fi
}

# Restart services
restart() {
    local service="$1"

    if ! check_compose; then
        return 1
    fi

    load_environment

    if [[ -z "$service" ]]; then
        show_info "Restarting all dreamKIT services..."
        $COMPOSE_CMD --env-file "$ENV_FILE" restart
    else
        show_info "Restarting service: $service"
        $COMPOSE_CMD --env-file "$ENV_FILE" restart "$service"
    fi

    show_success "Services restarted successfully"
}

# Stop services
stop() {
    local service="$1"

    if ! check_compose; then
        return 1
    fi

    load_environment

    if [[ -z "$service" ]]; then
        show_info "Stopping all dreamKIT services..."
        $COMPOSE_CMD --env-file "$ENV_FILE" down
    else
        show_info "Stopping service: $service"
        $COMPOSE_CMD --env-file "$ENV_FILE" stop "$service"
    fi

    show_success "Services stopped successfully"
}

# Start services
start() {
    local service="$1"

    if ! check_compose; then
        return 1
    fi

    load_environment

    if [[ -z "$service" ]]; then
        show_info "Starting all dreamKIT services..."
        $COMPOSE_CMD --env-file "$ENV_FILE" up -d
    else
        show_info "Starting service: $service"
        $COMPOSE_CMD --env-file "$ENV_FILE" up -d "$service"
    fi

    show_success "Services started successfully"
}

# Update services (pull new images and restart)
update() {
    local service="$1"

    if ! check_compose; then
        return 1
    fi

    load_environment

    show_info "Updating dreamKIT services..."

    if [[ -z "$service" ]]; then
        show_info "Pulling latest images for all services..."
        $COMPOSE_CMD --env-file "$ENV_FILE" pull
        show_info "Restarting services with new images..."
        $COMPOSE_CMD --env-file "$ENV_FILE" up -d
    else
        show_info "Pulling latest image for service: $service"
        $COMPOSE_CMD --env-file "$ENV_FILE" pull "$service"
        show_info "Restarting service: $service"
        $COMPOSE_CMD --env-file "$ENV_FILE" up -d "$service"
    fi

    show_success "Services updated successfully"
}

# Clean up (remove all containers and volumes)
clean() {
    if ! check_compose; then
        return 1
    fi

    show_warning "This will remove all dreamKIT containers and data volumes!"
    read -p "Are you sure? [y/N]: " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_info "Removing all dreamKIT containers and volumes..."
        load_environment
        $COMPOSE_CMD --env-file "$ENV_FILE" down -v --remove-orphans
        docker system prune -f
        show_success "Cleanup completed"
    else
        show_info "Cleanup cancelled"
    fi
}

# Show help
show_help() {
    echo -e "${BLUE}${BOLD}dreamKIT Docker Management Script${NC}"
    echo
    echo -e "${WHITE}Usage:${NC}"
    echo -e "${CYAN}  $0 <command> [service-name]${NC}"
    echo
    echo -e "${WHITE}Commands:${NC}"
    echo -e "${CYAN}  status              Show status of all services${NC}"
    echo -e "${CYAN}  logs <service>      Show logs for specific service${NC}"
    echo -e "${CYAN}  start [service]     Start all services or specific service${NC}"
    echo -e "${CYAN}  stop [service]      Stop all services or specific service${NC}"
    echo -e "${CYAN}  restart [service]   Restart all services or specific service${NC}"
    echo -e "${CYAN}  update [service]    Pull latest images and restart services${NC}"
    echo -e "${CYAN}  clean               Remove all containers and volumes${NC}"
    echo -e "${CYAN}  help                Show this help message${NC}"
    echo
    echo -e "${WHITE}Service Names:${NC}"
    echo -e "${CYAN}  mqtt-broker         MQTT message broker${NC}"
    echo -e "${CYAN}  sdv-runtime         Software Defined Vehicle runtime${NC}"
    echo -e "${CYAN}  dk-manager          DreamKit management service${NC}"
    echo -e "${CYAN}  dk-ivi              IVI interface (optional)${NC}"
    echo -e "${CYAN}  local-registry      Local Docker registry (optional)${NC}"
    echo
    echo -e "${WHITE}Examples:${NC}"
    echo -e "${CYAN}  $0 status           Show all service status${NC}"
    echo -e "${CYAN}  $0 logs sdv-runtime Show SDV runtime logs${NC}"
    echo -e "${CYAN}  $0 restart mqtt     Restart MQTT broker${NC}"
    echo -e "${CYAN}  $0 update           Update all services${NC}"
}

# Main command handler
case "${1:-help}" in
    "status")
        status
        ;;
    "logs")
        logs "$2"
        ;;
    "start")
        start "$2"
        ;;
    "stop")
        stop "$2"
        ;;
    "restart")
        restart "$2"
        ;;
    "update")
        update "$2"
        ;;
    "clean")
        clean
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        show_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac