#!/bin/bash
# Test script for DreamKIT black box examination

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== DreamKIT Testing =====${NC}"

# Function to check if container is running
check_container() {
    echo -n "Checking $1... "
    if docker ps | grep -q $1; then
        echo -e "${GREEN}Running${NC}"
        return 0
    else
        echo -e "${RED}Not running${NC}"
        return 1
    fi
}

# Check all containers
check_container "dreamos-core"
check_container "dm-manager"
check_container "vehicle-api"
check_container "hvac-service"
check_container "ivi-system"
check_container "can-simulator"
check_container "ecu-simulator"

# Test DM Manager API
echo -e "\n${BOLD}${BLUE}Testing DM Manager API:${NC}"
curl -s http://localhost:5000/api/v1/status | python3 -m json.tool || echo -e "${RED}Failed to connect to DM Manager${NC}"

# Test Vehicle API
echo -e "\n${BOLD}${BLUE}Testing Vehicle API:${NC}"
curl -s http://localhost:9000/api/v1/vehicle/info | python3 -m json.tool || echo -e "${RED}Failed to connect to Vehicle API${NC}"

# Test HVAC Service
echo -e "\n${BOLD}${BLUE}Testing HVAC Service:${NC}"
curl -s http://localhost:8080/api/v1/hvac | python3 -m json.tool || echo -e "${RED}Failed to connect to HVAC Service${NC}"

# Test setting HVAC temperature
echo -e "\n${BOLD}${BLUE}Setting HVAC temperature to 24°C:${NC}"
curl -s -X POST -H "Content-Type: application/json" -d '{"targetTemperature": 24}' http://localhost:8080/api/v1/hvac | python3 -m json.tool || echo -e "${RED}Failed to set HVAC temperature${NC}"

# Check IVI System
echo -e "\n${BOLD}${BLUE}Checking IVI System:${NC}"
curl -s http://localhost:8000/api/system-status | python3 -m json.tool || echo -e "${RED}Failed to connect to IVI System${NC}"

echo -e "\n${BOLD}${GREEN}Testing complete!${NC}"
echo -e "${YELLOW}Access the IVI web interface at http://localhost:8000${NC}"
echo -e "${YELLOW}View container logs with: docker logs <container-name>${NC}"
echo -e "${YELLOW}View application logs in the ./logs directory${NC}"
