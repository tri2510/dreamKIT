#!/bin/bash

# ==============================================
# DK Embedded Service Runner
# ==============================================
# Manages embedded mode services without Docker

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[SERVICE]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
ACTION=$1
SERVICE_ID=$2
SERVICE_NAME=$3

if [ $# -ne 3 ]; then
    print_error "Usage: $0 <start|stop> <service_id> <service_name>"
    print_info "Example: $0 start 683932d514dac7289703b035 'DreamPACK'"
    exit 1
fi

# Environment setup
DK_USER="${DK_USER:-$(whoami)}"
DK_BASE_DIR="/home/$DK_USER/.dk"
SERVICE_DIR="$DK_BASE_DIR/dk_installedservices/$SERVICE_ID"
PID_FILE="$SERVICE_DIR/service.pid"
LOG_FILE="$SERVICE_DIR/service.log"

print_info "🔧 EMBEDDED SERVICE MANAGER - NO DOCKER MODE"
print_info "=========================================="
print_info "⚠️  IMPORTANT: This is NOT starting Docker containers!"
print_info "⚠️  This is embedded mode - simulating services with background processes"
print_info "⚠️  You will NOT see this in 'docker ps' because no Docker is used!"
print_info "=========================================="
print_info "Action: $ACTION"
print_info "Service ID: $SERVICE_ID"
print_info "Service Name: $SERVICE_NAME"
print_info "Service Directory: $SERVICE_DIR"

# Ensure service directory exists
mkdir -p "$SERVICE_DIR"

case "$ACTION" in
    "start")
        print_status "🚀 STARTING EMBEDDED SERVICE (NOT DOCKER): $SERVICE_NAME"
        print_info "📁 Creating background process simulation..."
        print_info "📋 This creates a simple bash process - NO container involved"
        
        # Check if service is already running
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                print_warning "Service $SERVICE_NAME is already running (PID: $PID)"
                exit 0
            else
                print_info "Removing stale PID file"
                rm -f "$PID_FILE"
            fi
        fi
        
        # Create service status file
        cat > "$SERVICE_DIR/service_status.json" << EOF
{
    "service_id": "$SERVICE_ID",
    "service_name": "$SERVICE_NAME",
    "status": "running",
    "started_timestamp": $(date +%s),
    "mode": "embedded",
    "pid_file": "$PID_FILE",
    "log_file": "$LOG_FILE"
}
EOF
        
        print_info "🔄 Creating background bash process (instead of Docker container)..."
        
        # Start a simple background process to simulate the service
        # This creates a long-running process that can be monitored
        (
            echo "$(date): [EMBEDDED MODE] Starting service $SERVICE_NAME ($SERVICE_ID)" >> "$LOG_FILE"
            echo "$(date): [EMBEDDED MODE] Running as background bash process - NOT Docker" >> "$LOG_FILE"
            echo "$(date): [EMBEDDED MODE] Service simulation started" >> "$LOG_FILE"
            
            # Simple service simulation - just keep running and log periodically
            while true; do
                echo "$(date): [EMBEDDED MODE] Service $SERVICE_NAME heartbeat - still running" >> "$LOG_FILE"
                sleep 30
            done
        ) &
        
        # Save the PID
        echo $! > "$PID_FILE"
        
        print_status "✅ EMBEDDED SERVICE STARTED SUCCESSFULLY (NO DOCKER)"
        print_info "🔢 Process PID: $(cat "$PID_FILE")"
        print_info "📄 Service Log: $LOG_FILE"
        print_info "🔍 To verify: ps aux | grep $(cat "$PID_FILE")"
        print_info "❌ Will NOT appear in: docker ps (because it's not Docker!)"
        ;;
        
    "stop")
        print_status "🛑 STOPPING EMBEDDED SERVICE (NOT DOCKER): $SERVICE_NAME"
        print_info "🔍 Looking for background bash process to kill..."
        
        # Check if PID file exists
        if [ ! -f "$PID_FILE" ]; then
            print_warning "Service $SERVICE_NAME is not running (no PID file)"
            exit 0
        fi
        
        # Read PID and kill the process
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            print_info "Stopping process with PID: $PID"
            kill "$PID"
            
            # Wait for process to stop
            for i in {1..10}; do
                if ! kill -0 "$PID" 2>/dev/null; then
                    break
                fi
                sleep 1
            done
            
            # Force kill if still running
            if kill -0 "$PID" 2>/dev/null; then
                print_warning "Force killing stubborn process"
                kill -9 "$PID" 2>/dev/null || true
            fi
            
            print_status "✅ Service $SERVICE_NAME stopped successfully"
        else
            print_warning "Process with PID $PID not found (already stopped)"
        fi
        
        # Clean up files
        rm -f "$PID_FILE"
        rm -f "$SERVICE_DIR/service_status.json"
        
        # Log the stop
        echo "$(date): Service $SERVICE_NAME stopped" >> "$LOG_FILE"
        ;;
        
    *)
        print_error "Unknown action: $ACTION"
        print_info "Valid actions: start, stop"
        exit 1
        ;;
esac

print_info "Embedded service operation completed"