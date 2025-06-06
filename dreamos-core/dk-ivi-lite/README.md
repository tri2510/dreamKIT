# DK IVI Lite

**Modern In-Vehicle Infotainment System with Enhanced Configuration Management**

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/tri2510/dreamKIT)
[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://github.com/tri2510/dreamKIT/pkgs/container/dk-ivi-builder)
[![Qt](https://img.shields.io/badge/Qt-6.4.2-green)](https://www.qt.io/)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## 🚀 Quick Start

```bash
# 1. Get pre-built images
./build_optimized.sh images

# 2. Build application
./build_optimized.sh build

# 3. Run with default config
./run_dk_ivi_enhanced.sh run

# 4. Or run in debug mode
./run_dk_ivi_enhanced.sh run config/debug.yml
```

## ✨ Features

### 🎛️ **Modern IVI Interface**
- **Qt6-based** responsive UI with QML
- **Vehicle controls** for lights, climate, and systems
- **Digital.auto integration** for remote control
- **Marketplace** for application management
- **Service management** for installed services

### ⚙️ **Enhanced Configuration System**
- **YAML-based configuration** with validation
- **Multiple profiles** (production, debug, custom)
- **CLI argument support** with comprehensive help
- **Real-time validation** and error reporting
- **Environment variable override** support

### 🐳 **Container-Optimized**
- **Multi-stage Docker builds** for optimal size
- **Pre-built GHCR images** for instant setup
- **Source mounting** for ultra-fast development (~30s builds)
- **GPU acceleration** support with fallback rendering
- **X11 forwarding** for GUI applications

### 🚗 **Vehicle Integration**
- **CAN bus support** with configurable interfaces
- **VSS (Vehicle Signal Specification)** compliance
- **VAPI data broker** integration
- **Real-time signal processing** and updates
- **DBC file support** for CAN message mapping

## 📋 Requirements

- **Docker** (latest version recommended)
- **X11 server** (for GUI on Linux)
- **8GB RAM** minimum for building
- **2GB disk space** for images and cache

## 🛠️ Installation

### Option 1: Pre-built Images (Recommended)
```bash
# Pull from GitHub Container Registry
./build_optimized.sh images
```

### Option 2: Build Locally
```bash
# Build Docker images locally
./build_optimized.sh build-images
```

## 📖 Usage

### Basic Operations

```bash
# Build the application
./build_optimized.sh build

# Run with default configuration
./run_dk_ivi_enhanced.sh run

# Run in foreground (interactive)
./run_dk_ivi_enhanced.sh run-fg

# Stop the application
./run_dk_ivi_enhanced.sh stop

# View logs
./run_dk_ivi_enhanced.sh logs

# Check status
./run_dk_ivi_enhanced.sh status
```

### Configuration Management

```bash
# Show current configuration
./run_dk_ivi_enhanced.sh config

# Validate configuration file
./run_dk_ivi_enhanced.sh validate config/debug.yml

# Run with custom configuration
./run_dk_ivi_enhanced.sh run config/debug.yml
```

### CLI Arguments

The dk_ivi executable supports comprehensive command-line arguments:

```bash
dk_ivi --help                                    # Show help
dk_ivi --version                                 # Show version
dk_ivi --log-level debug                         # Set log level
dk_ivi --can-interface can0                      # Set CAN interface
dk_ivi --vapi-broker 192.168.1.100:55555        # Set VAPI endpoint
dk_ivi --debug                                   # Enable debug mode
```

## 📁 Project Structure

```
dk-ivi-lite/
├── src/                          # Source code
│   ├── main/                     # Application entry point
│   ├── controls/                 # Vehicle control components
│   ├── digitalauto/              # Digital.auto integration
│   ├── marketplace/              # Application marketplace
│   └── library/vapiclient/       # VAPI communication
├── config/                       # Configuration files
│   ├── dk_ivi.yml               # Production configuration
│   └── debug.yml                # Debug configuration
├── scripts/                      # Utility scripts
│   └── config-manager.sh        # Configuration management
├── Dockerfile.builder            # Builder image definition
├── Dockerfile.runtime            # Runtime image definition
├── build_optimized.sh           # Build system
└── run_dk_ivi_enhanced.sh       # Enhanced runner
```

## ⚙️ Configuration

### YAML Configuration Example

```yaml
# config/dk_ivi.yml
app:
  name: "dk_ivi"
  log_level: "info"

runtime:
  container_name: "dk_ivi"
  run_mode: "detached"

display:
  qt_backend: "software"
  enable_gpu: true
  x11_forwarding: true

network:
  vapi_databroker: "127.0.0.1:55555"
  system_databroker: "127.0.0.1:55569"

vehicle:
  can_interface: "vcan0"
  dbc_file: "/app/runtime/package/Model3CAN.dbc"
```

### Multiple Profiles

- **`config/dk_ivi.yml`** - Production configuration
- **`config/debug.yml`** - Debug with verbose logging
- **Custom configs** - Create your own profiles

## 🔧 Development

### Development Workflow

1. **Setup Development Environment**
   ```bash
   ./build_optimized.sh shell     # Open development shell
   ```

2. **Code → Build → Test Cycle**
   ```bash
   # Edit source code
   ./build_optimized.sh build     # Quick rebuild (~30s)
   ./run_dk_ivi_enhanced.sh run-fg config/debug.yml
   ```

### Build Performance

- ⚡ **Ultra-fast builds** (~30 seconds) with source mounting
- 🔄 **Build caching** via Docker volumes and ccache
- 📦 **Pre-built base images** eliminate dependency building
- 🎯 **Incremental compilation** for development efficiency

### Debug Features

```bash
# Debug configuration
./run_dk_ivi_enhanced.sh run config/debug.yml

# Interactive mode with full output
./run_dk_ivi_enhanced.sh run-fg config/debug.yml

# Configuration validation
./scripts/config-manager.sh validate config/custom.yml
```

## 🏗️ Architecture

### Container Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Builder Image  │    │  Runtime Image  │    │  Application    │
│                 │    │                 │    │                 │
│ • Build tools   │───▶│ • Qt6 runtime   │───▶│ • dk_ivi        │
│ • Dependencies  │    │ • Libraries     │    │ • Configuration │
│ • Compilation   │    │ • Minimal OS    │    │ • Vehicle Data  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Configuration Flow
```
YAML Config → Validation → CLI Args → dk_ivi Executable
     ↓              ↓           ↓            ↓
config.yml → config-manager.sh → --args → Enhanced App
```

## 🌐 Vehicle Integration

### Supported Protocols
- **CAN Bus** - Controller Area Network communication
- **VSS** - Vehicle Signal Specification compliance
- **VAPI** - Vehicle API for real-time data exchange
- **DBC** - Database CAN for message definition

### Signal Processing
```cpp
// Real-time vehicle signal updates
VAPI_CLIENT.subscribeTarget(DK_VAPI_DATABROKER, signalPaths, 
    [this](const std::string &path, const std::string &value) {
        this->handleVehicleSignal(path, value);
    }
);
```

## 🎯 Production Deployment

### Docker Compose Example
```yaml
version: '3.8'
services:
  dk-ivi:
    image: ghcr.io/tri2510/dk-ivi-runtime:latest
    container_name: dk_ivi
    network_mode: host
    volumes:
      - ./config:/app/config:ro
      - ./output:/app/exec:ro
      - /tmp/.X11-unix:/tmp/.X11-unix
    environment:
      - DISPLAY=${DISPLAY}
      - QT_QUICK_BACKEND=software
    command: /app/exec/dk_ivi --config=/app/config/production.yml
```

### Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dk-ivi
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dk-ivi
  template:
    spec:
      containers:
      - name: dk-ivi
        image: ghcr.io/tri2510/dk-ivi-runtime:latest
        args: ["/app/exec/dk_ivi", "--log-level=info"]
```

## 🔍 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Build fails** | `./build_optimized.sh clean && ./build_optimized.sh build` |
| **Container won't start** | Check `./run_dk_ivi_enhanced.sh status` and logs |
| **GUI not showing** | Verify X11: `echo $DISPLAY && xhost +local:docker` |
| **Config validation fails** | Run `./run_dk_ivi_enhanced.sh validate config/file.yml` |

### Debug Commands
```bash
# System check
./build_optimized.sh status

# Configuration debug
./run_dk_ivi_enhanced.sh config

# Runtime debug  
./run_dk_ivi_enhanced.sh logs

# Container inspection
docker exec -it dk_ivi /bin/bash
```

## 📊 Performance

### Build Performance
- **Initial build**: ~3-5 minutes (with image download)
- **Incremental build**: ~30 seconds (source changes only)
- **Clean build**: ~2 minutes (with cached images)

### Runtime Performance
- **Memory usage**: ~200MB (runtime container)
- **Startup time**: ~2-3 seconds
- **GUI responsiveness**: 60 FPS with GPU acceleration

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test: `./run_dk_ivi_enhanced.sh run config/debug.yml`
4. Commit changes: `git commit -m 'Add amazing feature'`
5. Push to branch: `git push origin feature/amazing-feature`
6. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Qt Framework** for the excellent GUI toolkit
- **COVESA VSS** for vehicle signal standardization
- **Eclipse Kuksa** for VAPI implementation
- **Docker** for containerization technology

## 📞 Support

- **Documentation**: See [USAGE.md](USAGE.md) for detailed usage guide
- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Join GitHub Discussions for questions

---

**Built with ❤️ for the automotive industry**