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
    if [ ! -f "tools/run_dk_ivi_enhanced.sh" ]; then
        echo -e "${YELLOW}Enhanced runner not found. Building first...${NC}"
        build_enhanced
    fi
    ./tools/run_dk_ivi_enhanced.sh
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

main() {
    print_banner
    
    while true; do
        show_menu
        read -p "Enter your choice [1-6, q]: " choice
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