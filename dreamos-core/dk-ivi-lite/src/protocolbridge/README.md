# DreamKIT SDV Protocol Bridge

A professional-grade Software Defined Vehicle (SDV) protocol simulation and translation system integrated into DreamKIT IVI.

## Overview

The Protocol Bridge demonstrates modern automotive SDV architecture by simulating various automotive communication protocols and translating them to VSS (Vehicle Signal Specification) signals through KUKSA data broker integration.

## Features

### 🚗 **Protocol Simulation**
- **CAN Bus**: Real-time simulation with configurable parameters
- **LIN Bus**: Window/mirror controls simulation  
- **FlexRay**: Safety-critical system simulation
- **OBD-II**: Diagnostic protocol simulation

### 📡 **VSS Translation Hub**
- Real-time protocol data translation to VSS signals
- Visual mapping display showing source → VSS transformation
- Live signal monitoring with timestamps and source tracking

### 🐳 **KUKSA Integration**
- Docker container management for KUKSA data broker
- Custom endpoint configuration support
- Connection health monitoring and auto-reconnect
- TLS support for secure connections

### 🖥️ **Professional Terminal**
- Full OS terminal functionality with command history
- Built-in DreamKIT commands (dk-help, kuksa-start, etc.)
- KUKSA CLI integration with quick VSS get/set commands
- Docker management commands (logs, status, inspect)

### 📤 **Output Protocol Generation**
- **SOME/IP**: Service-oriented middleware messages
- **REST API**: JSON payloads for cloud integration
- **Mobile Apps**: Formatted JSON for mobile dashboards

### ⏯️ **Timeline Control**
- Professional playback controls (play/pause/stop/record)
- Variable speed playback (0.1x to 10x)
- Scenario recording and replay
- Multiple driving scenarios (city, highway, parking, diagnostic)

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Protocol Sources│───▶│ VSS Translation  │───▶│ Target Protocols│
│ • CAN Bus       │    │ Hub (KUKSA)      │    │ • SOME/IP       │
│ • LIN Bus       │    │ • Signal Router  │    │ • REST API      │
│ • FlexRay       │    │ • Format Conv.   │    │ • Mobile JSON   │
│ • OBD-II        │    │ • Validation     │    │ • WebSocket     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## File Structure

```
protocolbridge/
├── protocolbridge.h/cpp              # Main integration class
├── protocolbridgemanager.h/cpp       # Core manager and protocol interfaces
├── kuksaconnectionmanager.h/cpp      # KUKSA Docker/endpoint management
├── terminalconsole.h/cpp             # Terminal console implementation
├── ProtocolBridgeDashboard.qml       # Main UI dashboard
├── ProtocolSourcePanel.qml           # Protocol input controls
├── VSSTranslationHub.qml             # VSS signal translation display
├── ProtocolTargetPanel.qml           # Output protocol displays
├── TerminalConsolePanel.qml          # Terminal interface
├── KuksaConfigurationDialog.qml      # KUKSA setup dialog
├── ProtocolInterfaceCard.qml         # Individual protocol cards
└── README.md                         # This file
```

## Classes

### Core Classes
- **ProtocolBridgeManager**: Main orchestrator handling all protocol interfaces
- **KuksaConnectionManager**: KUKSA data broker connection and Docker management
- **TerminalConsole**: Full-featured terminal with DK-specific commands
- **VSSSignalModel**: Qt model for displaying active VSS signals

### Protocol Interfaces
- **ProtocolInterface**: Base class for all protocol implementations
- **CANInterface**: CAN bus simulation with realistic vehicle behavior
- **LINInterface**: LIN bus simulation for body electronics
- **FlexRayInterface**: FlexRay simulation for safety systems
- **OBDInterface**: OBD-II diagnostic simulation

## Integration

The Protocol Bridge integrates seamlessly with DreamKIT IVI:

1. **CMakeLists.txt**: Added Protocol Bridge sources and QML files
2. **main.cpp**: Registered QML types and exposed to context
3. **settings.qml**: Added "Protocol Bridge" tab to main navigation
4. **Qt Dependencies**: Added Qt6::Network for KUKSA communication

## Usage

### Starting the Protocol Bridge
1. Navigate to "Protocol Bridge" tab in DreamKIT IVI
2. Configure KUKSA connection (Docker/Custom endpoint)
3. Select simulation mode (Simulated/Real Hardware/Replay)
4. Choose driving scenario and start simulation

### KUKSA Management
```bash
# Using the Docker manager script
./scripts/kuksa-docker-manager.sh start
./scripts/kuksa-docker-manager.sh status
./scripts/kuksa-docker-manager.sh logs -f
```

### Terminal Commands
- `dk-help` - Show DreamKIT commands
- `kuksa-start` - Start KUKSA container
- `vss-get Vehicle.Speed` - Get VSS signal value
- `vss-set Vehicle.Speed 65.5` - Set VSS signal value
- `docker ps` - Show running containers

### VSS Signal Examples
- `Vehicle.Speed` - Vehicle speed in km/h
- `Vehicle.Powertrain.CombustionEngine.Speed` - Engine RPM
- `Vehicle.Cabin.Door.Row1.DriverSide.IsOpen` - Door status
- `Vehicle.Body.Lights.Beam.Low.IsOn` - Headlight status

## Configuration

### KUKSA Docker Mode
- **Image**: `ghcr.io/eclipse/kuksa.val/kuksa-databroker:latest`
- **Port**: 55555 (configurable)
- **Auto-start**: Automatic container startup
- **Health Check**: Built-in connection monitoring

### Custom Endpoint Mode
- **Host**: IP address or hostname
- **Port**: Custom port number
- **TLS**: Optional secure connection
- **Certificate**: Custom TLS certificate support

## Development

### Adding New Protocols
1. Inherit from `ProtocolInterface`
2. Implement required virtual methods
3. Add to `ProtocolBridgeManager::initializeProtocolInterfaces()`
4. Create QML interface card

### Adding VSS Mappings
1. Update protocol data parsing in `handleProtocolData()`
2. Add VSS path mappings in translation logic
3. Update output protocol generation

### Custom Commands
1. Add to `TerminalConsole::executeBuiltinCommand()`
2. Update help text in `dk-help` command
3. Add to builtin commands list

## Dependencies

- **Qt6**: Core, Quick, Network
- **KUKSA**: Data broker (Docker container)
- **Docker**: Container management
- **libKuksaClient**: VSS communication library

## Professional Features

- **Realistic Simulation**: Physics-based vehicle behavior modeling
- **Professional UI**: Dark theme with animations and status indicators
- **Error Handling**: Comprehensive error reporting and recovery
- **Logging**: Detailed logging with configurable levels
- **Configuration**: Persistent settings and scenario management
- **Documentation**: Complete inline documentation and help system

This implementation provides a complete, professional-grade SDV protocol bridge that demonstrates the full power of software-defined vehicle architecture within the DreamKIT ecosystem.