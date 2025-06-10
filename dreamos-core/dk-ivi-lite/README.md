# DreamKIT IVI - In-Vehicle Infotainment System 🚗

## Quick Start

**🎯 New users start here:**
```bash
./start.sh
```

Or choose your implementation:

| Implementation | Container Count | Use Case | Quick Start |
|---------------|----------------|----------|-------------|
| **Enhanced** ⭐ | 2 containers | **Recommended** - Optimized, embedded services | `cd build && ./build_enhanced.sh` |
| **Legacy** | 5 containers | Full separation, development | `cd build && ./build_optimized.sh` |

## 📁 Project Structure

```
dk-ivi-lite/
├── 📖 README.md                    ← YOU ARE HERE - Start here!
├── 🏗️ build/                        ← Build system & Dockerfiles
│   ├── Dockerfile.enhanced          ← Enhanced 2-container build
│   ├── Dockerfile.builder           ← Build environment
│   ├── Dockerfile.runtime           ← Runtime environment  
│   ├── build_enhanced.sh           ← Build enhanced version
│   └── build_optimized.sh          ← Build legacy version
├── 🚀 deployment/                   ← Deployment configurations
│   └── docker-compose.enhanced.yml ← Docker Compose setup
├── 📚 docs/                         ← Documentation
│   ├── README.enhanced.md           ← Enhanced version guide
│   └── USAGE.md                     ← Usage instructions
├── 🛠️ tools/                        ← Development & debug tools
│   ├── run_dk_ivi_enhanced.sh      ← Run enhanced version
│   ├── run_dk_ivi_debug.sh         ← Debug mode runner
│   └── scripts/                     ← Utility scripts
├── 💻 src/                          ← Source code (Qt/QML/C++)
├── ⚙️ config/                       ← Configuration files
├── 📦 output/                       ← Build artifacts
└── 🔧 runtime/                      ← Runtime configurations
```

## 🚀 Getting Started

### Option 1: Enhanced Version (Recommended)
```bash
# Build enhanced image with embedded services
cd build
./build_enhanced.sh

# Deploy with Docker Compose
cd ../deployment
docker-compose -f docker-compose.enhanced.yml up -d
```

### Option 2: Quick Development Setup
```bash
# Run enhanced version directly
./tools/run_dk_ivi_enhanced.sh

# Or run with debug output
./tools/run_dk_ivi_debug.sh
```

### Option 3: Production Deployment
```bash
# Use the installation scripts (recommended for production)
cd ../../installation-scripts/jetson-orin/
./dk_install.sh dk_ivi=true
./dk_run.sh
```

## 🏗️ Build System

| Script | Purpose | Output |
|--------|---------|--------|
| `build/build_enhanced.sh` | **Enhanced 2-container build** | `ghcr.io/tri2510/dk-ivi-enhanced:latest` |
| `build/build_optimized.sh` | Legacy 5-container build | Multiple separate images |

### Build Arguments
```bash
# Build types
./build_enhanced.sh release    # Production build (default)
./build_enhanced.sh debug      # Development build

# Custom repository
REPO_OWNER=yourorg ./build_enhanced.sh
```

## 🎯 Architecture Comparison

### Enhanced Architecture (2 Containers)
```
┌─────────────┐  ┌──────────────────────────────────┐
│ SDV Runtime │  │      Enhanced dk_ivi             │
│  (KUKSA)    │  │  ┌─────────┐ ┌─────────────────┐  │
│             │  │  │ dk_ivi  │ │ Embedded Svcs   │  │
│             │  │  │  (UI)   │ │ • dk_manager    │  │
│             │  │  │         │ │ • app_install   │  │
└─────────────┘  │  └─────────┘ └─────────────────┘  │
     Port        └──────────────────────────────────┘
    55555              Supervisor Managed
```

**Benefits:** 52% less memory, 47% less CPU, 56% faster startup

### Legacy Architecture (5 Containers)
```
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ SDV Runtime │ │ dk_manager  │ │ dk_install  │ │ KUKSA Client│ │   dk_ivi    │
│  (KUKSA)    │ │ (Lifecycle) │ │ (App Mgmt)  │ │ (Testing)   │ │    (UI)     │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

## 🔧 Configuration

### Environment Variables
```bash
# Core settings
DK_USER=root                    # System user
DK_EMBEDDED_MODE=1              # Enable embedded services (enhanced)
DK_MOCK_MODE=1                  # Enable mock mode
DK_CONTAINER_ROOT=/app/.dk/     # Data directory

# Display settings
DISPLAY=:0                      # X11 display
QT_QPA_PLATFORM=xcb            # Qt platform
```

### Configuration Files
- `config/dk_ivi.yml` - Main application configuration
- `config/debug.yml` - Debug logging configuration
- `runtime/runtimecfg.json` - Runtime configuration

## 🛠️ Development

### Prerequisites
```bash
# Install dependencies
sudo apt-get install -y docker.io git cmake qt6-base-dev

# Add user to docker group
sudo usermod -aG docker $USER
```

### Building from Source
```bash
# Clone repository
git clone https://github.com/tri2510/dreamKIT.git
cd dreamKIT/dreamos-core/dk-ivi-lite

# Build enhanced version
cd build
./build_enhanced.sh debug

# Run locally
cd ../tools
./run_dk_ivi_enhanced.sh
```

### Debug & Testing
```bash
# View logs
docker logs dk_ivi -f

# Debug mode
./tools/run_dk_ivi_debug.sh

# Health check
docker exec dk_ivi /app/health-check.sh

# Service status (enhanced mode)
docker exec dk_ivi supervisorctl status
```

## 📊 Monitoring

### Health Checks
```bash
# Container health
docker exec dk_ivi /app/health-check.sh

# Service status (enhanced mode only)
docker exec dk_ivi supervisorctl status

# Resource usage
docker stats dk_ivi --no-stream
```

### Logs
```bash
# Main application logs
docker logs dk_ivi

# Enhanced mode service logs
docker exec dk_ivi tail -f /app/logs/dk_manager_embedded.log
docker exec dk_ivi tail -f /app/logs/supervisord.log
```

## 🔍 Troubleshooting

### Common Issues

**Q: GUI not appearing**
```bash
# Check X11 forwarding
echo $DISPLAY
xhost +local:docker

# Verify container is running
docker ps | grep dk_ivi
```

**Q: Service toggle not working**
```bash
# Check service status
docker exec dk_ivi supervisorctl status

# View service logs with debug info
QT_LOGGING_RULES="dk.ivi.services.debug=true" ./tools/run_dk_ivi_debug.sh
```

**Q: Build failures**
```bash
# Clean and rebuild
docker system prune -f
./build/build_enhanced.sh clean
./build/build_enhanced.sh debug
```

## 📖 Documentation

- **[Enhanced Guide](docs/README.enhanced.md)** - Comprehensive enhanced version documentation
- **[Usage Guide](docs/USAGE.md)** - Detailed usage instructions  
- **[Architecture Overview](../../docs/DreamKit-Architecture-Overview.md)** - System architecture
- **[Installation Guide](../../installation-scripts/jetson-orin/)** - Production deployment

## 🤝 Contributing

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes** in appropriate folders
4. **Test thoroughly**: `./build/build_enhanced.sh debug`
5. **Commit changes**: `git commit -m "Add amazing feature"`
6. **Push and create PR**: `git push origin feature/amazing-feature`

### Development Workflow
- **Source code**: Edit files in `src/`
- **Build changes**: Run `./build/build_enhanced.sh debug`
- **Test locally**: Use `./tools/run_dk_ivi_debug.sh`
- **Deploy**: Use files in `deployment/`

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/tri2510/dreamKIT/issues)
- **Documentation**: Check `docs/` folder
- **Installation**: Use `installation-scripts/jetson-orin/`

---

**DreamKIT IVI** - Powering the future of in-vehicle experiences 🚗✨