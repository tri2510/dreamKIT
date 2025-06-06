# dk_app_python_template

> Info: This repo provides a guideline to build image for dk_manager app. dk_manager is the core app to manage the operation of dreamkit system.

## Prerequisites:
Git clone dk-manger repo into src folder before run docker build.  
```
cd src
git clone https://github.com/ppa2hc/dk-manager.git
```

## Build docker image
Local-arch build:  
```
docker build -t dk_manager:latest --file Dockerfile .
```
Run local:  
```
docker stop dk_manager; docker rm dk_manager; docker run -d -it --name dk_manager -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker  dk_manager:latest
```

Multi-arch build and push to docker hub:  
```
docker buildx create --name dk_multiarch_build_dk_manager --use
docker buildx use dk_multiarch_build_dk_manager
docker buildx build --platform linux/amd64,linux/arm64 -t phongbosch/dk_manager:latest --push -f Dockerfile .
```

Use Dockerfile.Fast to build faster. This uses prebuilt socketio client.  
```
docker buildx build --platform linux/amd64,linux/arm64 -t phongbosch/dk_manager:latest --push -f Dockerfile.Fast .
```

Run from docker hub
```
docker pull phongbosch/dk_manager:latest
docker stop dk_manager; docker rm dk_manager; docker run -d -it --name dk_manager -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker  phongbosch/dk_manager:latest
```

## Result after bootup
```shell
Start dk_manager
dk-manager verion 1.0.0 !!!
DkManger 96  : setup socket.io
InitDigitalautoFolder 163
InitDigitalautoFolder 207  cmd =  "mkdir -p /app/.dk/dk_manager/log/cmd/ /app/.dk/dk_manager/prototypes/ /app/.dk/dk_manager/download/ /app/.dk/dk_manager/vssmapping/ /app/.dk/dk_manager/vssmapping/ /app/.dk/dk_marketplace/ /app/.dk/dk_installedservices/ /app/.dk/dk_installedapps/;rm /app/.dk/dk_manager/log/cmd/*;touch /app/.dk/dk_manager/vssmapping/stop_kuksa_feeder_script.sh;touch /app/.dk/dk_manager/vssmapping/start_kuksa_feeder_script.sh;echo \"[]\" > /app/.dk/dk_installedservices/installedservices.json;echo \"[]\" > /app/.dk/dk_installedapps/installedapps.json;echo 'Vehicle:\n  type: branch\n\n' > /app/.dk/dk_manager/vssmapping/vssmapping_overlay.vspec;echo \"[]\" > /app/.dk/dk_manager/prototypes/supportedvssapi.json;echo \"[]\" > /app/.dk/dk_manager/vssmapping/vssmapping_dbc_can_channels.json;echo \"{}\" > /app/.dk/dk_manager/vssmapping/dbc_default_values.json;touch /app/.dk/dk_manager/prototypes/prototypes.json;chmod 777 /app/.dk/dk_manager/prototypes/prototypes.json;chmod 777 -R /app/.dk/dk_manager/prototypes/;chmod 777 -R /app/.dk/dk_manager/vssmapping/;"
rm: cannot remove '/app/.dk/dk_manager/log/cmd/*': No such file or directory
InitUserInfo 158  : DK_VCU_USERNAME =  "sdv-orin"
URL:  https://kit.digitalauto.tech
[2025-05-21 02:40:58] [connect] Successful connection
[2025-05-21 02:40:58] [connect] WebSocket Connection 168.63.44.238:443 v-2 "WebSocket++/0.8.2" /socket.io/?EIO=4&transport=websocket&t=1747795257 101
get_dreamkit_code 79 create DreamkitID in hex:  "f1ae5bb05afc0cfc"
get_dreamkit_code 92 serialNo:  "5afc0cfc"
```
