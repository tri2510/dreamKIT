#!/bin/sh

echo "Start dk_manager"
# start local mqtt server
cd /app/exec
export DKCODE=dreamKIT
./dk_manager
echo "End dk_manager"

#tail -f /dev/null
