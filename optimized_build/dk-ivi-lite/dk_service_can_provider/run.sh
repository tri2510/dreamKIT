#!/bin/bash

# Create runtime directory and copy required files from dist
mkdir -p runtime/package
cp dist/Model3CAN.dbc runtime/package/
cp dist/dbc_default_values.json vss/ 2>/dev/null || mkdir -p vss && cp dist/dbc_default_values.json vss/

# Use proper VSS mapping files from dist
mkdir -p vss
cp dist/mapping/vss_4.2/vss_dbc.json vss/vss.json

# Create runtime config to use CAN dump file instead of live interface
echo '{"can_channel": "candump"}' > runtime/runtimecfg.json

# Run with Docker using candump.log file
docker run --rm -it --privileged --network host \
  -v "$(pwd)/app:/app" \
  -v "$(pwd)/dist:/dist" \
  -v "$(pwd)/runtime:/app/runtime" \
  -v "$(pwd)/vss:/app/vss" \
  -w /app \
  python:3.9-slim \
  bash -c "
    cd /dist && ./dbcfeeder --dbc2val \
    --dumpfile /dist/candump.log \
    --dbcfile /app/runtime/package/Model3CAN.dbc \
    --dbc-default /app/vss/dbc_default_values.json \
    --mapping /app/vss/vss.json
  "