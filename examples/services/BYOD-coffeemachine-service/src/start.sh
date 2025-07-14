#!/bin/sh

echo "Start Coffee service"

cd /app/dist/
./main
echo "End Coffee service"

#tail -f /dev/null
