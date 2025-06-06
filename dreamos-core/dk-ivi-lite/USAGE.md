# DK IVI Lite - Usage Guide

## Overview

DK IVI Lite is a lightweight In-Vehicle Infotainment (IVI) system built with Qt6 and designed for containerized deployment. It provides a modern interface for vehicle control systems with CAN bus integration and VSS (Vehicle Signal Specification) support.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Building](#building)
- [Running](#running)
- [CLI Arguments](#cli-arguments)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [API Reference](#api-reference)

## Quick Start

### 1. Prerequisites

- Docker installed and running
- X11 server for GUI (on Linux)
- Git for source code management

### 2. Get Started in 3 Steps

```bash
# 1. Pull pre-built Docker images
./build_optimized.sh images

# 2. Build the application
./build_optimized.sh build

# 3. Run with default configuration
./run_dk_ivi_enhanced.sh run
```

## Installation

### Docker Images

The system uses pre-built Docker images hosted on GitHub Container Registry:

- **Builder Image:** `ghcr.io/tri2510/dk-ivi-builder:latest`
- **Runtime Image:** `ghcr.io/tri2510/dk-ivi-runtime:latest`

Pull images automatically:
```bash
./build_optimized.sh images
```

Or manually:
```bash
docker pull ghcr.io/tri2510/dk-ivi-builder:latest
docker pull ghcr.io/tri2510/dk-ivi-runtime:latest
```

### Build from Source

If you need to build images locally:
```bash
./build_optimized.sh build-images
```

## Configuration

### Configuration System

DK IVI Lite uses a modern YAML-based configuration system with validation and multiple profiles support.

### Configuration Files

#### Main Configuration: `config/dk_ivi.yml`
```yaml
# Application Settings
app:
  name: "dk_ivi"
  version: "1.0.0"
  log_level: "info"  # debug, info, warn, error

# Runtime Configuration
runtime:
  container_name: "dk_ivi"
  restart_policy: "unless-stopped"
  run_mode: "detached"  # detached, interactive

# Display and Graphics
display:
  qt_backend: "software"  # software, opengl, vulkan
  enable_gpu: true
  x11_forwarding: true

# Vehicle Integration
vehicle:
  can_interface: "vcan0"
  vss_mapping: "/app/vss/vss.json"
```

#### Debug Configuration: `config/debug.yml`
```yaml
app:
  log_level: "debug"
runtime:
  container_name: "dk_ivi_debug" 
  run_mode: "interactive"
display:
  enable_gpu: false
```

### Configuration Management

#### Validate Configuration
```bash
./run_dk_ivi_enhanced.sh validate config/dk_ivi.yml
```

#### Show Current Configuration
```bash
./run_dk_ivi_enhanced.sh config
```

#### Use Custom Configuration
```bash
./run_dk_ivi_enhanced.sh run config/debug.yml
```

## Building

### Build Options

#### Standard Build
```bash
./build_optimized.sh build            # Build dk_ivi
./build_optimized.sh build dk-manager # Build dk-manager
./build_optimized.sh build all        # Build both
```

#### Clean Build
```bash
./build_optimized.sh clean            # Clean build cache
./build_optimized.sh clean dk_ivi     # Clean specific target
```

#### Build Status
```bash
./build_optimized.sh status           # Show build status
```

### Build Architecture

The build system uses:
- **Multi-stage Docker builds** for optimal image size
- **Source mounting** for fast incremental builds (~30 seconds)
- **ccache** for compilation speed optimization
- **Build caches** via Docker volumes for persistence

### Build Artifacts

After building, artifacts are located in:
```
output/
├── dk_ivi                    # Main executable
├── dk-manager/
│   └── dk_manager           # Manager executable  
└── library/
    └── libKuksaClient.so    # Required libraries
```

## Running

### Basic Usage

#### Default Run (Background)
```bash
./run_dk_ivi_enhanced.sh run
```

#### Interactive Run (Foreground)
```bash
./run_dk_ivi_enhanced.sh run-fg
```

#### With Custom Configuration
```bash
./run_dk_ivi_enhanced.sh run config/debug.yml
```

### Container Management

#### Check Status
```bash
./run_dk_ivi_enhanced.sh status
```

#### View Logs
```bash
./run_dk_ivi_enhanced.sh logs
```

#### Open Shell
```bash
./run_dk_ivi_enhanced.sh shell
```

#### Stop/Restart
```bash
./run_dk_ivi_enhanced.sh stop
./run_dk_ivi_enhanced.sh restart
```

### Runtime Parameters

The enhanced runner displays runtime parameters:
```
=== Runtime Parameters ===
Container Name:    dk_ivi
Docker Image:      ghcr.io/tri2510/dk-ivi-runtime:latest
Run Mode:          detached
Qt Backend:        software
Log Level:         info
CAN Interface:     vcan0
VAPI Broker:       127.0.0.1:55555
GPU Enabled:       true
X11 Forwarding:    true
```

## CLI Arguments

### Supported Arguments

The dk_ivi executable supports comprehensive CLI arguments:

```bash
dk_ivi [OPTIONS]

Options:
  -c, --config <file>        Configuration file path
  -l, --log-level <level>    Set logging level (debug, info, warn, error)
  -i, --can-interface <name> CAN interface name (e.g., vcan0, can0)
  -v, --vapi-broker <addr>   VAPI data broker endpoint (IP:PORT)
  -s, --system-broker <addr> System data broker endpoint (IP:PORT)
  -b, --qt-backend <backend> Qt Quick backend (software, opengl, vulkan)
  -d, --debug                Enable debug mode with verbose output
  -V, --version              Show version information
  -h, --help                 Show help message
```

### Usage Examples

```bash
# Debug mode with custom CAN interface
dk_ivi --debug --can-interface can0

# Custom data broker endpoints
dk_ivi --vapi-broker 192.168.1.100:55555 --system-broker 192.168.1.100:55569

# OpenGL rendering with info logging
dk_ivi --qt-backend opengl --log-level info

# Load custom configuration
dk_ivi --config /custom/path/config.yml
```

### Environment Variables

CLI arguments can also be set via environment variables:
- `DK_LOG_LEVEL` - Override log level
- `DK_CAN_INTERFACE` - Override CAN interface  
- `QT_QUICK_BACKEND` - Override Qt backend

## Development

### Development Workflow

1. **Setup Development Environment**
   ```bash
   ./build_optimized.sh images    # Pull base images
   ./build_optimized.sh shell     # Open development shell
   ```

2. **Code → Build → Test Cycle**
   ```bash
   # Edit source code in src/
   ./build_optimized.sh build     # Quick rebuild (~30s)
   ./run_dk_ivi_enhanced.sh run-fg config/debug.yml  # Test interactively
   ```

3. **Debug Development**
   ```bash
   # Run with debug configuration
   ./run_dk_ivi_enhanced.sh run config/debug.yml
   
   # View debug logs
   ./run_dk_ivi_enhanced.sh logs
   ```

### Development Tools

#### Configuration Manager
```bash
# Generate Docker arguments from config
./scripts/config-manager.sh docker-args config/debug.yml

# Generate application arguments
./scripts/config-manager.sh app-args config/debug.yml

# Validate configuration
./scripts/config-manager.sh validate config/custom.yml
```

#### Development Shell
```bash
# Open development environment with build tools
./build_optimized.sh shell

# Open runtime environment for testing
./build_optimized.sh runtime
```

### Source Code Structure

```
src/
├── main/
│   ├── main.cpp              # Application entry point
│   ├── config.hpp/cpp        # CLI argument handling
│   └── main.qml              # Main UI interface
├── controls/                 # Vehicle control components
├── digitalauto/              # Digital.auto integration
├── marketplace/              # Application marketplace
├── installedservices/        # Service management
├── installedvapps/           # VAPP management
└── library/vapiclient/       # VAPI communication library
```

### Adding New Features

1. **Add Configuration Options**
   - Update `config/dk_ivi.yml` with new parameters
   - Extend `config.hpp/cpp` for CLI argument support
   - Update validation in `scripts/config-manager.sh`

2. **Add New Components**
   - Create component in appropriate `src/` subdirectory
   - Register QML types in `main.cpp`
   - Update `CMakeLists.txt` build configuration

3. **Testing**
   - Use debug configuration for development
   - Test with multiple configuration profiles
   - Validate configuration changes

## Troubleshooting

### Common Issues

#### Build Failures

**Issue:** CMake configuration fails
```bash
# Solution: Clean and rebuild
./build_optimized.sh clean
./build_optimized.sh build
```

**Issue:** Library not found errors
```bash
# Solution: Check library paths
ls -la output/library/
# Rebuild if missing
./build_optimized.sh build
```

#### Runtime Issues

**Issue:** Container fails to start
```bash
# Check container status
./run_dk_ivi_enhanced.sh status

# View error logs
./run_dk_ivi_enhanced.sh logs

# Validate configuration
./run_dk_ivi_enhanced.sh validate config/dk_ivi.yml
```

**Issue:** GUI not displaying
```bash
# Check X11 setup
echo $DISPLAY
xhost +local:docker

# Test with software rendering
# Edit config: display.qt_backend: "software"
./run_dk_ivi_enhanced.sh run config/debug.yml
```

**Issue:** VAPI connection failed
```bash
# Check data broker endpoints
# Verify network connectivity
# Update config: network.vapi_databroker: "IP:PORT"
```

#### Configuration Issues

**Issue:** Configuration validation fails
```bash
# Show detailed error
./scripts/config-manager.sh validate config/custom.yml

# Check configuration syntax
# Verify all required fields are present
# Ensure valid enum values (log levels, backends, etc.)
```

### Debug Mode

Enable comprehensive debugging:

1. **Use Debug Configuration**
   ```bash
   ./run_dk_ivi_enhanced.sh run config/debug.yml
   ```

2. **Enable CLI Debug**
   ```bash
   dk_ivi --debug --log-level debug
   ```

3. **Check System Requirements**
   ```bash
   ./build_optimized.sh status  # Shows system status
   ```

### Performance Optimization

#### GPU Acceleration
```yaml
# Enable in config
display:
  enable_gpu: true
  qt_backend: "opengl"  # or "vulkan"
```

#### Build Performance
- Use ccache (enabled by default)
- Keep Docker volumes for build cache
- Use source mounting for fast rebuilds

### Logging

#### Log Levels
- **debug**: Verbose output for development
- **info**: General information (default)
- **warn**: Warning messages only  
- **error**: Error messages only

#### Log Categories
- `dk.ivi.main` - Application lifecycle
- `dk.ivi.config` - Configuration management
- `dk.ivi.vapi` - VAPI communication
- `dk.ivi.controls` - Vehicle controls

## API Reference

### Configuration API

#### Config Class
```cpp
class Config {
public:
    bool parseArguments(int argc, char *argv[]);
    QString logLevel() const;
    QString canInterface() const;
    QString vapiDataBroker() const;
    // ... other getters
};
```

### VAPI Integration

#### Connection
```cpp
// Connect to VAPI data broker
VAPI_CLIENT.connectToServer(config.vapiDataBroker().toStdString().c_str());

// Subscribe to vehicle signals
VAPI_CLIENT.subscribeTarget(DK_VAPI_DATABROKER, signalPaths, callback);
```

#### Vehicle Signals
```cpp
// Set vehicle signal values
VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, 
                           VehicleAPI::V_Bo_Lights_Beam_Low_IsOn, 
                           status);
```

### QML Integration

#### Access Configuration in QML
```qml
// Configuration available as dkConfig
Text {
    text: "Log Level: " + dkConfig.logLevel
}

Text {
    text: "CAN Interface: " + dkConfig.canInterface  
}
```

---

## Support

For issues, questions, or contributions:
- Check the troubleshooting section above
- Review configuration validation output
- Examine application logs with debug mode
- Ensure all prerequisites are met

## Version

Current version: **1.0.0**  
Qt version: **6.4.2**  
Architecture: **Multi-platform (amd64, arm64)**