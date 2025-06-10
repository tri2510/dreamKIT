#!/bin/bash

# DreamKIT IVI Quick Start Script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║                     🚗 DreamKIT IVI Quick Start 🚗                   ║
    ║                                                                      ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_menu() {
    echo -e "${YELLOW}Choose your action:${NC}"
    echo
    echo -e "${BLUE}1)${NC} Build Enhanced Version (Recommended)"
    echo -e "${BLUE}2)${NC} Build Legacy Version"
    echo -e "${BLUE}3)${NC} Quick Run Enhanced"
    echo -e "${BLUE}4)${NC} Deploy with Docker Compose"
    echo -e "${BLUE}5)${NC} Production Installation"
    echo -e "${BLUE}6)${NC} Show Documentation"
    echo -e "${BLUE}7)${NC} Show Status"
    echo -e "${BLUE}8)${NC} Stop Services"
    echo -e "${BLUE}q)${NC} Quit"
    echo
}

build_enhanced() {
    echo -e "${GREEN}Building Enhanced DreamKIT IVI...${NC}"
    if ! (cd build && ./build_enhanced.sh); then
        echo -e "${YELLOW}❌ Build failed. Check the output above for details.${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ Enhanced version built successfully!${NC}"
    echo -e "${CYAN}Next: Run './start.sh' and choose option 3 to test${NC}"
}

build_legacy() {
    echo -e "${GREEN}Building Legacy DreamKIT IVI...${NC}"
    if ! (cd build && ./build_optimized.sh images && ./build_optimized.sh build); then
        echo -e "${YELLOW}❌ Build failed. Check the output above for details.${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ Legacy version built successfully!${NC}"
}

quick_run() {
    echo -e "${GREEN}Running Enhanced DreamKIT IVI...${NC}"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}❌ Docker is required but not installed${NC}"
        return 1
    fi
    
    # Use similar logic to the enhanced dk_run.sh installation script
    echo -e "${BLUE}Starting core services...${NC}"
    
    # Start SDV Runtime if not running
    if ! docker ps --format "{{.Names}}" | grep -q "^sdv-runtime$"; then
        echo -e "${BLUE}Starting SDV Runtime...${NC}"
        docker run -d -it --name sdv-runtime --restart unless-stopped \
            -e USER="$USER" \
            -e RUNTIME_NAME="DreamKIT_BGSV" \
            -p 55555:55555 \
            -e ARCH="amd64" \
            ghcr.io/tri2510/sdv-runtime:latest >/dev/null 2>&1 || {
                echo -e "${YELLOW}⚠ Failed to start SDV Runtime (may need to pull image first)${NC}"
            }
    else
        echo -e "${GREEN}✓ SDV Runtime already running${NC}"
    fi
    
    # Check if enhanced image exists locally
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^ghcr.io/tri2510/dk-ivi-enhanced:latest$"; then
        echo -e "${YELLOW}Enhanced image not found locally. Building first...${NC}"
        build_enhanced || return 1
    fi
    
    # Enable X11 forwarding
    xhost +local:docker >/dev/null 2>&1 || echo -e "${YELLOW}⚠ X11 forwarding setup may have failed${NC}"
    
    # Stop existing IVI container if running
    docker stop dk_ivi >/dev/null 2>&1 || true
    docker rm dk_ivi >/dev/null 2>&1 || true
    
    echo -e "${BLUE}Starting Enhanced dk_ivi with embedded services...${NC}"
    
    # Create .dk directory structure
    mkdir -p "$HOME/.dk/dk_manager" "$HOME/.dk/dk_installedservices" "$HOME/.dk/dk_installedapps"
    
    # Start enhanced dk_ivi (similar to enhanced dk_run.sh)
    docker run -d -it --name dk_ivi \
        --network host \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY="$DISPLAY" \
        -e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
        -e QT_QUICK_BACKEND=software \
        --restart unless-stopped \
        --log-opt max-size=10m --log-opt max-file=3 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$HOME/.dk:/app/.dk" \
        -e DKCODE=dreamKIT \
        -e DK_USER="$USER" \
        -e DK_DOCKER_HUB_NAMESPACE="ghcr.io/tri2510" \
        -e DK_ARCH="amd64" \
        -e DK_CONTAINER_ROOT="/app/.dk/" \
        -e DK_EMBEDDED_MODE="1" \
        -e DK_MOCK_MODE="1" \
        ghcr.io/tri2510/dk-ivi-enhanced:latest >/dev/null 2>&1
    
    # Verify container started
    sleep 2
    if docker ps --format "{{.Names}}" | grep -q "^dk_ivi$"; then
        echo -e "${GREEN}✅ Enhanced DreamKIT IVI started successfully!${NC}"
        echo -e "${CYAN}Dashboard should appear on your display${NC}"
        echo -e "${BLUE}View logs: docker logs -f dk_ivi${NC}"
        echo -e "${BLUE}Stop: docker stop dk_ivi${NC}"
    else
        echo -e "${YELLOW}❌ Failed to start enhanced IVI interface${NC}"
        echo -e "${BLUE}Check logs: docker logs dk_ivi${NC}"
        return 1
    fi
}

deploy_compose() {
    echo -e "${GREEN}Deploying with Docker Compose...${NC}"
    if ! (cd deployment && docker-compose -f docker-compose.enhanced.yml up -d); then
        echo -e "${YELLOW}❌ Deployment failed. Check the output above for details.${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ Deployed successfully!${NC}"
    echo -e "${CYAN}View logs: docker-compose -f deployment/docker-compose.enhanced.yml logs -f${NC}"
}

production_install() {
    echo -e "${GREEN}Running Production Installation...${NC}"
    echo -e "${YELLOW}This will navigate to installation scripts${NC}"
    cd ../../installation-scripts/jetson-orin/
    echo -e "${CYAN}Run: ./dk_install.sh dk_ivi=true${NC}"
    echo -e "${CYAN}Then: ./dk_run.sh${NC}"
}

show_docs() {
    echo -e "${GREEN}📖 Documentation Guide:${NC}"
    echo
    echo -e "${BLUE}Main Documentation:${NC}"
    echo -e "  • README.md (You are here)"
    echo -e "  • docs/README.enhanced.md - Enhanced version guide"
    echo -e "  • docs/USAGE.md - Detailed usage"
    echo
    echo -e "${BLUE}Key Directories:${NC}"
    echo -e "  • build/ - Build scripts and Dockerfiles"
    echo -e "  • deployment/ - Docker Compose configurations" 
    echo -e "  • tools/ - Development and debug utilities"
    echo -e "  • src/ - Source code (Qt/QML/C++)"
    echo
    echo -e "${BLUE}Quick Commands:${NC}"
    echo -e "  • Build Enhanced: cd build && ./build_enhanced.sh"
    echo -e "  • Quick Run: ./tools/run_dk_ivi_enhanced.sh"
    echo -e "  • Debug Mode: ./tools/run_dk_ivi_debug.sh"
    echo
}

show_status() {
    echo -e "${GREEN}📊 Enhanced DreamKIT Service Status:${NC}"
    echo
    
    local services=("sdv-runtime" "dk_ivi")
    
    for service in "${services[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^$service$"; then
            local status=$(docker ps --format "{{.Status}}" --filter "name=^$service$")
            echo -e "${GREEN} ✓ $service: ${BLUE}Running${NC} ${CYAN}($status)${NC}"
        else
            echo -e "${YELLOW} ✗ $service: ${YELLOW}Stopped${NC}"
        fi
    done
    
    echo
    echo -e "${CYAN}Enhanced Mode Features:${NC}"
    echo -e "${BLUE} → Embedded dk_manager (no separate container)${NC}"
    echo -e "${BLUE} → Embedded app install service (no separate container)${NC}"
    echo -e "${BLUE} → Integrated service management in dk_ivi${NC}"
    echo
}

stop_services() {
    echo -e "${GREEN}Stopping Enhanced DreamKIT Services...${NC}"
    
    local services=("dk_ivi" "sdv-runtime")
    
    for service in "${services[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^$service$"; then
            echo -e "${BLUE}Stopping $service...${NC}"
            docker stop "$service" >/dev/null 2>&1
            echo -e "${GREEN} ✓ $service stopped${NC}"
        else
            echo -e "${YELLOW} • $service was not running${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ All services stopped${NC}"
}

main() {
    print_banner
    
    while true; do
        show_menu
        read -p "Enter your choice [1-8, q]: " choice
        echo
        
        case $choice in
            1)
                build_enhanced
                ;;
            2)
                build_legacy
                ;;
            3)
                quick_run
                ;;
            4)
                deploy_compose
                ;;
            5)
                production_install
                return
                ;;
            6)
                show_docs
                ;;
            7)
                show_status
                ;;
            8)
                stop_services
                ;;
            q|Q)
                echo -e "${GREEN}Thanks for using DreamKIT IVI! 🚗✨${NC}"
                exit 0
                ;;
            *)
                echo -e "${YELLOW}Invalid option. Please try again.${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
        echo
    done
}

# Check if running from correct directory
if [ ! -f "README.md" ]; then
    echo -e "${YELLOW}Please run this script from the dk-ivi-lite directory${NC}"
    exit 1
fi

main "$@"