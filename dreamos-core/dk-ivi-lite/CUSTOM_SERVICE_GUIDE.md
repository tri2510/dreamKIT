# DreamKIT IVI Custom Service Development Guide

This guide explains how to create custom services that can be installed and managed through the DreamKIT IVI interface.

## Overview

DreamKIT IVI supports custom vehicle services that can be installed through the marketplace and controlled via the Vehicle Services tab. Services run as Docker containers and integrate with the DreamKIT ecosystem.

## Required Service Definition Components

### 1. Marketplace Entry (for installation)
Create a marketplace entry JSON with these required fields:
```json
{
  "_id": "your_unique_service_id",
  "name": "Your Service Name", 
  "category": "vehicle-service",
  "dashboardConfig": "{\"DockerImageURL\":\"your_docker_image:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"your_config_key\":\"your_config_value\"}}"
}
```

### 2. Docker Image Requirements
Your Docker image must:
- **Have an executable entry point** (usually `/app/start.sh`)
- **Read runtime config** from `/app/runtime/runtimecfg.json`
- **Be published to a Docker registry** (Docker Hub, GHCR, etc.)
- **Run as a long-running process** (don't exit immediately)

### 3. Service Installation Structure
When installed, dk_ivi creates this structure:
```
/app/.dk/dk_installedservices/{service_id}/
├── runtimecfg.json          # Runtime configuration
├── deployment_status.json   # Installation metadata
└── package/                 # Optional: additional files (DBC, etc.)
```

### 4. Runtime Configuration Contract
Your service must read `/app/runtime/runtimecfg.json` which contains:
```json
{
  "your_config_key": "your_config_value"
}
```

### 5. Docker Run Command Contract
dk_ivi will run your service with this command pattern:
```bash
docker run -d -it --name {service_id} \
  --log-opt max-size=10m --log-opt max-file=3 \
  -v /home/{user}/.dk/dk_installedservices/{service_id}:/app/runtime \
  --network host \
  -v /home/{user}/.dk/dk_manager/vssmapping/dbc_default_values.json:/app/vss/dbc_default_values.json:ro \
  -v /home/{user}/.dk/dk_vssgeneration/vss.json:/app/vss/vss.json:ro \
  {your_docker_image}
```

## Step-by-Step Service Creation Guide

### Step 1: Create Your Service Docker Image

**Dockerfile**:
```dockerfile
FROM ubuntu:22.04

# Install your dependencies
RUN apt-get update && apt-get install -y python3 python3-pip

# Copy your application
COPY . /app
WORKDIR /app

# Install dependencies
RUN pip3 install -r requirements.txt

# Make start script executable
RUN chmod +x /app/start.sh

# Entry point
CMD ["/app/start.sh"]
```

### Step 2: Create Service Application

**main.py** (example):
```python
import json
import time
import os

def main():
    print("Starting Your Service")
    
    # Read runtime configuration
    config_path = "/app/runtime/runtimecfg.json"
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            config = json.load(f)
        print(f"Config: {config}")
    else:
        print("No runtime config found")
        config = {}
    
    # Your service logic here
    while True:
        print("Service running...")
        time.sleep(10)

if __name__ == "__main__":
    main()
```

**start.sh**:
```bash
#!/bin/bash
echo "Starting Your Service"
python3 /app/main.py
```

**requirements.txt**:
```
# Add your Python dependencies here
requests
```

### Step 3: Build and Push Docker Image
```bash
# Build your Docker image
docker build -t your_username/your_service:latest .

# Push to Docker registry
docker push your_username/your_service:latest
```

### Step 4: Create Installation Config
Create `{service_id}_installcfg.json`:
```json
{
  "_id": "your_service_12345",
  "name": "Your Service Name",
  "category": "vehicle-service", 
  "dashboardConfig": "{\"DockerImageURL\":\"your_username/your_service:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"param1\":\"value1\",\"param2\":\"value2\"}}"
}
```

### Step 5: Install Through dk_ivi
1. Copy the `_installcfg.json` to `/app/.dk/dk_marketplace/`
2. Use the marketplace to install the service
3. The service will appear in the Vehicle Services tab

## Critical Requirements Summary

| Component | Requirement | Example |
|-----------|-------------|---------|
| **Service ID** | Unique identifier | `"my_custom_service_001"` |
| **Category** | Must be `"vehicle-service"` | `"vehicle-service"` |
| **Docker Image** | Publicly accessible | `"username/service:latest"` |
| **Entry Point** | Executable start script | `"/app/start.sh"` |
| **Runtime Config** | Read from `/app/runtime/runtimecfg.json` | `{"param": "value"}` |
| **Process Type** | Long-running (doesn't exit) | Infinite loop or daemon |
| **Target** | Deployment target | `"xip"` (for local) |

## Optional Enhancements

### Volume Mounts
If your service needs additional files:
- **DBC files**: Available at `/app/vss/dbc_default_values.json`
- **VSS mapping**: Available at `/app/vss/vss.json`
- **Custom files**: Put in `/app/runtime/package/`

### Health Monitoring
Your service should:
- **Log meaningful output** (dk_ivi shows container logs)
- **Handle graceful shutdown** (respond to SIGTERM)
- **Use exit codes properly** (0 = success, non-zero = error)

### Service Communication
- **KUKSA Data Broker**: Available at `127.0.0.1:55555` (if needed)
- **Host Network**: Your service runs in host network mode
- **Environment Variables**: Access via `os.getenv()`

## Example: Complete Hello World Service

### Directory Structure
```
my-hello-service/
├── Dockerfile
├── start.sh
├── main.py
├── requirements.txt
└── hello_service_001_installcfg.json
```

### main.py
```python
import json
import time
import os
from datetime import datetime

def main():
    print("=== Hello World Service Starting ===")
    
    # Read runtime configuration
    config_path = "/app/runtime/runtimecfg.json"
    config = {}
    
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            config = json.load(f)
        print(f"Loaded config: {config}")
    else:
        print("No runtime config found, using defaults")
    
    # Get configuration parameters
    greeting = config.get("greeting", "Hello")
    interval = config.get("interval_seconds", 30)
    
    print(f"Service configured with greeting='{greeting}', interval={interval}s")
    
    # Main service loop
    counter = 0
    while True:
        counter += 1
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {greeting} from DreamKIT service! (count: {counter})")
        time.sleep(interval)

if __name__ == "__main__":
    main()
```

### start.sh
```bash
#!/bin/bash
echo "Starting Hello World Service"
cd /app
python3 main.py
```

### Dockerfile
```dockerfile
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy application files
COPY main.py /app/
COPY start.sh /app/
COPY requirements.txt /app/

# Install dependencies
RUN pip install -r requirements.txt

# Make start script executable
RUN chmod +x /app/start.sh

# Entry point
CMD ["/app/start.sh"]
```

### hello_service_001_installcfg.json
```json
{
  "_id": "hello_service_001",
  "name": "Hello World Service",
  "category": "vehicle-service",
  "dashboardConfig": "{\"DockerImageURL\":\"your_username/hello-world-service:latest\",\"Target\":\"xip\",\"Platform\":\"linux/amd64\",\"RuntimeCfg\":{\"greeting\":\"Hello DreamKIT\",\"interval_seconds\":10}}"
}
```

### Build and Deploy
```bash
# Build the image
docker build -t your_username/hello-world-service:latest .

# Push to registry
docker push your_username/hello-world-service:latest

# Copy install config to DreamKIT
cp hello_service_001_installcfg.json ~/.dk/dk_marketplace/
```

## Troubleshooting

### Service Fails to Start
1. **Check Docker logs**: `docker logs {service_id}`
2. **Verify image accessibility**: `docker pull your_image:tag`
3. **Test locally**: `docker run -it your_image:tag`

### Service Not Appearing in UI
1. **Check installation config**: Verify JSON syntax
2. **Check service category**: Must be `"vehicle-service"`
3. **Refresh marketplace**: Navigate away and back to Vehicle Services

### Service Starts But Stops Immediately
1. **Ensure long-running process**: Don't let main process exit
2. **Check runtime config path**: Service must read `/app/runtime/runtimecfg.json`
3. **Handle errors gracefully**: Don't crash on configuration issues

### Volume Mount Issues
1. **Check file permissions**: Ensure files are readable
2. **Verify mount paths**: Files mounted at `/app/vss/` and `/app/runtime/`
3. **Test without volumes**: Start with minimal configuration

## Best Practices

1. **Always handle missing configuration gracefully**
2. **Log meaningful messages for debugging**
3. **Use semantic versioning for your Docker images**
4. **Test your service locally before deploying**
5. **Include health checks in your service**
6. **Follow container best practices (single process, proper signals)**

This guide ensures your custom service will integrate properly with DreamKIT IVI's service management system and can be started/stopped through the Vehicle Services tab.