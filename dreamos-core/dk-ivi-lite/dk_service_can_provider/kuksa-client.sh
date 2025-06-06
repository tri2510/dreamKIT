#!/bin/bash

cat << 'EOF'
================================================================================
                        KUKSA Client - Tesla Model 3 VSS Monitor
================================================================================

SETUP:
1. Make sure your dbcfeeder is running first: ./run.sh
2. Wait until you see: "Update datapoint requests sent to kuksa.val so far: XXX"

VERIFICATION COMMANDS (use these once connected):

📊 LIST ALL SIGNALS:
   getValue Vehicle.*

🚗 CHECK SPECIFIC TESLA SIGNALS:
   getValue Vehicle.Speed
   getValue Vehicle.Powertrain.Battery.StateOfCharge.Current
   getValue Vehicle.Powertrain.Battery.Voltage.Current
   getValue Vehicle.Body.Lights.Hazard.IsSignaling
   getValue Vehicle.Cabin.HVAC.Station.Row1.Left.Temperature

🔄 SUBSCRIBE TO LIVE UPDATES:
   subscribe Vehicle.Speed
   subscribe Vehicle.Powertrain.Battery.StateOfCharge.Current
   subscribe Vehicle.Speed Vehicle.Powertrain.Battery.Voltage.Current

🔍 BROWSE SIGNAL CATEGORIES:
   getValue Vehicle.Powertrain.*
   getValue Vehicle.Body.*
   getValue Vehicle.Cabin.*

EXPECTED RESULTS:
✅ Vehicle.Speed: 65.5
✅ Vehicle.Powertrain.Battery.StateOfCharge.Current: 78.2
✅ Vehicle.Powertrain.Battery.Voltage.Current: 398.4
✅ Real-time updates when subscribed

TROUBLESHOOTING:
- "No data": Check dbcfeeder is running and showing update counts
- "Connection refused": Ensure port 55555 is available
- "Signal not found": Use getValue Vehicle.* to see available signals

Press ENTER to start KUKSA client...
================================================================================
EOF

read -p ""

echo "🚀 Starting KUKSA Client to monitor Tesla Model 3 VSS data..."
echo ""

# Run KUKSA client with correct URI format
docker run --rm -it --network host \
  ghcr.io/eclipse-kuksa/kuksa-python-sdk/kuksa-client:latest \
  grpc://127.0.0.1:55555