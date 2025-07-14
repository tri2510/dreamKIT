#!/bin/bash

# Mock Docker script for embedded dk_manager mode
# This prevents crashes when dk_manager tries to run Docker commands

# Don't output to stderr in mock mode to reduce log spam
# echo "Mock Docker mode - command ignored: docker $*" >&2

# Return mock data for Docker operations that expect specific output
case "$1" in
    "ps")
        # Return mock container list that looks like real Docker ps output
        echo "CONTAINER ID   IMAGE                    COMMAND                  CREATED          STATUS          PORTS     NAMES"
        echo "mock12345678   mock-service:latest      \"/bin/sh -c 'service'\"   About a minute   Up 1 minute               mock-service-1"
        echo "mock87654321   another-service:latest   \"/app/start\"             2 minutes ago    Up 2 minutes              mock-service-2"
        echo "dk_ivi_gui     dk-ivi:latest            \"/app/exec/dk_ivi\"       5 minutes ago    Up 5 minutes              dk_ivi_gui"
        echo "appinst12345   dk_appinstallservice:latest  \"/app/install\"      1 minute ago     Up 1 minute               dk_appinstallservice"
        exit 0
        ;;
    "images")
        echo "REPOSITORY          TAG       IMAGE ID       CREATED        SIZE"
        echo "mock-service        latest    mock123456     2 hours ago    100MB"
        echo "dk-ivi              latest    abc123def      1 hour ago     500MB"
        exit 0
        ;;
    "inspect")
        echo '[{"Id":"mock12345678","State":{"Running":true},"Name":"mock-service-1"}]'
        exit 0
        ;;
    "logs")
        echo "Mock service log output"
        echo "Service started successfully"
        echo "$(date): Service is running normally"
        exit 0
        ;;
    "run")
        # Handle specific app installation service
        if [[ "$*" == *"dk_appinstallservice"* ]]; then
            echo "dk_appinstallservice"
            # Simulate app installation in background
            nohup bash -c '
                sleep 3
                echo "$(date): Mock app installation completed successfully" >> /tmp/dk_app_install.log
            ' >/dev/null 2>&1 &
        else
            echo "mock_container_$(date +%s)"
        fi
        exit 0
        ;;
    "stop"|"rm"|"kill")
        # For stop/rm/kill commands, just return success
        exit 0
        ;;
    "pull"|"build")
        echo "mock_container_$(date +%s)"
        exit 0
        ;;
    *)
        # For any other command, just return success
        exit 0
        ;;
esac