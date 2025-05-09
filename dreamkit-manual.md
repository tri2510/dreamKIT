# DreamKIT Virtual Environment Manual

This guide explains how to set up, run, and examine the virtual DreamKIT environment on your local machine using Docker.

## Prerequisites

Before you begin, make sure you have the following installed:
- Docker
- Docker Compose
- curl
- Python 3

## Setup Instructions

The setup is divided into four parts to make it easier to understand and manage:

### Part 1: Check Prerequisites and Create Network

1. Run the first setup script:
   ```bash
   ./dreamkit-part1.sh
   ```

   This script will:
   - Check if all required software is installed
   - Create a Docker network for DreamKIT components
   - Create the necessary directory structure

### Part 2: Create Docker Compose Configuration (Base Components)

1. Run the second setup script:
   ```bash
   ./dreamkit-part2.sh
   ```

   This script will create the Docker Compose configuration with the following components:
   - DreamOS Core: The core system management component
   - DM Manager: The system orchestration component
   - Vehicle API: The core vehicle signal provider

### Part 3: Add HVAC Service and IVI System

1. Run the third setup script and its continuation:
   ```bash
   ./dreamkit-part3.sh
   ./dreamkit-part3-continued.sh
   ```

   This script will add the following components to the Docker Compose configuration:
   - HVAC Service: The climate control provider
   - IVI System: The user interface system

### Part 4: Add Simulators and Complete Setup

1. Run the fourth setup script:
   ```bash
   ./dreamkit-part4.sh
   ```

   This script will:
   - Add CAN Bus Simulator and ECU Simulator to Docker Compose
   - Create test script to verify the environment
   - Create run and stop scripts for easy management

## Running the Environment

After completing the setup, you can start the DreamKIT virtual environment:

```bash
./run-dreamkit.sh
```

This will:
1. Start all Docker containers
2. Run tests to verify the environment is working
3. Provide instructions on how to access the IVI web interface

## Examining the Environment

You can examine the DreamKIT components using various methods:

### Web Interfaces

- IVI System: http://localhost:8000
  - This is the main user interface for the system
  - You can interact with the vehicle's HVAC controls
  - You can view the vehicle status and system status

### API Endpoints

- DM Manager: http://localhost:5000
  - `/api/v1/status`: Get the system status
  - `/api/v1/services`: Get a list of available services

- Vehicle API: http://localhost:9000
  - `/api/v1/vehicle/info`: Get all vehicle information
  - `/api/v1/vehicle/<signal>`: Get a specific vehicle signal
  
- HVAC Service: http://localhost:8080
  - `/api/v1/status`: Get the HVAC service status
  - `/api/v1/hvac`: Get the current HVAC state

### Logs

- Container logs:
  ```bash
  docker logs dreamos-core
  docker logs dm-manager
  docker logs vehicle-api
  docker logs hvac-service
  docker logs ivi-system
  docker logs can-simulator
  docker logs ecu-simulator
  ```

- Application logs are also available in the `./logs` directory

### Testing

You can run the test script at any time to verify the environment:

```bash
./test-dreamkit.sh
```

## Component Interaction

The virtual DreamKIT environment simulates a complete Software-Defined Vehicle (SDV) architecture:

1. **Vehicle Signals**: The Vehicle API provides vehicle signals (speed, temperature, etc.).
2. **Climate Control**: The HVAC Service manages climate control functions.
3. **User Interface**: The IVI System provides a web interface for interacting with the vehicle.
4. **CAN Bus**: The CAN Bus Simulator simulates CAN messages.
5. **ECUs**: The ECU Simulator simulates various Electronic Control Units.

When you interact with the IVI web interface:
1. The IVI System sends requests to the HVAC Service.
2. The HVAC Service updates its state and notifies the Vehicle API.
3. The Vehicle API updates its signals.
4. The IVI System polls the services to display the current state.

This simulates the full stack of the DreamKIT architecture without requiring the physical hardware.

## Stopping the Environment

When you're done, you can stop the environment:

```bash
./stop-dreamkit.sh
```

This will stop and remove all Docker containers.

## Troubleshooting

- **Containers not starting**: Check Docker and Docker Compose installations
- **Services not connecting**: Check the Docker network and container logs
- **Web interface not loading**: Ensure port 8000 is not in use by another application