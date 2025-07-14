#!/bin/sh

echo "Start dk service can provider"

# Wait time for can network up
sleep 0.1

# cd /app/
# python main.py
# cd /dist/
./dbcfeeder --val2dbc --dbc2val --use-socketcan --mapping mapping/vss_4.0/vss_dbc.json

echo "End dk service can provider"

#tail -f /dev/null
