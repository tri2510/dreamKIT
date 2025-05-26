#!/bin/sh

echo "Start dk_manager"
# start local mqtt server
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/app/exec/lib:/app/exec/lib/qt6/lib/
export QML2_IMPORT_PATH=/app/exec/lib/qt6/qml
export QT_PLUGIN_PATH=/app/exec/lib/qt6/plugins/
#export QT_QUICK_BACKEND=software
cd /app/exec
./dk_ivi
echo "End dk_manager"

#tail -f /dev/null
