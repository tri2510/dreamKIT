#!/bin/bash

# DreamKIT KUKSA Docker Management Script
# This script provides easy management of KUKSA Data Broker Docker containers

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
KUKSA_IMAGE="ghcr.io/eclipse/kuksa.val/kuksa-databroker:latest"
CONTAINER_NAME="kuksa-databroker"
HOST_PORT="55555"
CONTAINER_PORT="55555"
HEALTH_PORT="8090"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
}

# Function to check if container exists
container_exists() {
    docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to start KUKSA container
start_kuksa() {
    print_header "Starting KUKSA Data Broker"
    
    check_docker
    
    if container_running; then
        print_warning "KUKSA container is already running"
        show_status
        return 0
    fi
    
    if container_exists; then
        print_status "Starting existing container..."
        docker start ${CONTAINER_NAME}
    else
        print_status "Creating and starting new container..."
        print_status "Image: ${KUKSA_IMAGE}"
        print_status "Port: ${HOST_PORT}:${CONTAINER_PORT}"
        
        docker run -d \
            --name ${CONTAINER_NAME} \
            --network host \
            -p ${HOST_PORT}:${CONTAINER_PORT} \
            -p ${HEALTH_PORT}:${HEALTH_PORT} \
            ${KUKSA_IMAGE} \
            --address 0.0.0.0 \
            --port ${CONTAINER_PORT} \
            --log-level info
    fi
    
    if [ $? -eq 0 ]; then
        print_status "KUKSA Data Broker started successfully"
        sleep 2
        show_status
    else
        print_error "Failed to start KUKSA Data Broker"
        exit 1
    fi
}

# Function to stop KUKSA container
stop_kuksa() {
    print_header "Stopping KUKSA Data Broker"
    
    check_docker
    
    if ! container_running; then
        print_warning "KUKSA container is not running"
        return 0
    fi
    
    print_status "Stopping container..."
    docker stop ${CONTAINER_NAME}
    
    if [ $? -eq 0 ]; then
        print_status "KUKSA Data Broker stopped successfully"
    else
        print_error "Failed to stop KUKSA Data Broker"
        exit 1
    fi
}

# Function to restart KUKSA container
restart_kuksa() {
    print_header "Restarting KUKSA Data Broker"
    stop_kuksa
    sleep 2
    start_kuksa
}

# Function to remove KUKSA container
remove_kuksa() {
    print_header "Removing KUKSA Data Broker Container"
    
    check_docker
    
    if container_running; then
        print_status "Stopping running container first..."
        stop_kuksa
    fi
    
    if container_exists; then
        print_status "Removing container..."
        docker rm ${CONTAINER_NAME}
        
        if [ $? -eq 0 ]; then
            print_status "KUKSA container removed successfully"
        else
            print_error "Failed to remove KUKSA container"
            exit 1
        fi
    else
        print_warning "KUKSA container does not exist"
    fi
}

# Function to show logs
show_logs() {
    print_header "KUKSA Data Broker Logs"
    
    check_docker
    
    if ! container_exists; then
        print_error "KUKSA container does not exist"
        exit 1
    fi
    
    if [ "$1" = "-f" ]; then
        print_status "Following logs (Ctrl+C to exit)..."
        docker logs -f ${CONTAINER_NAME}
    else
        print_status "Showing last 50 lines of logs..."
        docker logs --tail 50 ${CONTAINER_NAME}
    fi
}

# Function to show status
show_status() {
    print_header "KUKSA Data Broker Status"
    
    check_docker
    
    if container_running; then
        print_status "Container Status: ${GREEN}RUNNING${NC}"
        
        # Get container info
        CONTAINER_ID=$(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.ID}}")
        CONTAINER_IMAGE=$(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Image}}")
        CONTAINER_PORTS=$(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Ports}}")
        CONTAINER_CREATED=$(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.CreatedAt}}")
        
        echo "Container ID: ${CONTAINER_ID}"
        echo "Image: ${CONTAINER_IMAGE}"
        echo "Ports: ${CONTAINER_PORTS}"
        echo "Created: ${CONTAINER_CREATED}"
        
        # Test connectivity
        echo ""
        print_status "Testing connectivity..."
        if curl -s -f http://localhost:${HEALTH_PORT}/health > /dev/null 2>&1; then
            print_status "Health check: ${GREEN}HEALTHY${NC}"
        else
            print_warning "Health check: ${YELLOW}NOT RESPONDING${NC}"
        fi
        
    elif container_exists; then
        print_warning "Container Status: ${YELLOW}STOPPED${NC}"
        
        # Get stopped container info
        CONTAINER_ID=$(docker ps -a --filter "name=${CONTAINER_NAME}" --format "{{.ID}}")
        CONTAINER_IMAGE=$(docker ps -a --filter "name=${CONTAINER_NAME}" --format "{{.Image}}")
        
        echo "Container ID: ${CONTAINER_ID}"
        echo "Image: ${CONTAINER_IMAGE}"
        echo "Use 'start' command to start the container"
        
    else
        print_error "Container Status: ${RED}NOT FOUND${NC}"
        echo "Use 'start' command to create and start the container"
    fi
}

# Function to pull latest image
pull_image() {
    print_header "Pulling Latest KUKSA Image"
    
    check_docker
    
    print_status "Pulling image: ${KUKSA_IMAGE}"
    docker pull ${KUKSA_IMAGE}
    
    if [ $? -eq 0 ]; then
        print_status "Image pulled successfully"
    else
        print_error "Failed to pull image"
        exit 1
    fi
}

# Function to inspect container
inspect_container() {
    print_header "KUKSA Container Inspection"
    
    check_docker
    
    if ! container_exists; then
        print_error "KUKSA container does not exist"
        exit 1
    fi
    
    docker inspect ${CONTAINER_NAME}
}

# Function to open shell in container
shell_container() {
    print_header "Opening Shell in KUKSA Container"
    
    check_docker
    
    if ! container_running; then
        print_error "KUKSA container is not running"
        exit 1
    fi
    
    print_status "Opening shell (type 'exit' to leave)..."
    docker exec -it ${CONTAINER_NAME} /bin/sh
}

# Function to show help
show_help() {
    cat << EOF
DreamKIT KUKSA Docker Management Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    start       Start KUKSA Data Broker container
    stop        Stop KUKSA Data Broker container
    restart     Restart KUKSA Data Broker container
    remove      Remove KUKSA Data Broker container
    status      Show container status and health
    logs        Show container logs
                -f  Follow logs in real-time
    pull        Pull latest KUKSA image
    inspect     Inspect container configuration
    shell       Open shell in running container
    help        Show this help message

Configuration:
    Image:      ${KUKSA_IMAGE}
    Container:  ${CONTAINER_NAME}
    Port:       ${HOST_PORT}:${CONTAINER_PORT}
    Health:     ${HEALTH_PORT}

Examples:
    $0 start                    # Start KUKSA container
    $0 logs -f                  # Follow logs in real-time
    $0 status                   # Check status
    $0 restart                  # Restart container

For more information, visit: https://github.com/eclipse/kuksa.val
EOF
}

# Main script logic
case "$1" in
    start)
        start_kuksa
        ;;
    stop)
        stop_kuksa
        ;;
    restart)
        restart_kuksa
        ;;
    remove)
        remove_kuksa
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    pull)
        pull_image
        ;;
    inspect)
        inspect_container
        ;;
    shell)
        shell_container
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        print_error "No command specified"
        echo "Use '$0 help' to see available commands"
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' to see available commands"
        exit 1
        ;;
esac