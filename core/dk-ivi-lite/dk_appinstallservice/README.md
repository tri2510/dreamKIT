# dk_appinstallservice

> Information: 
This docker image provides the service to install vehicle apps and services.  

## Presequisites
dreamOS must be installed first. Refer to this repo (https://github.com/ppa2hc/dk_installation) for dreamOS installation.  

## build docker image
local-arch build  
```
docker build -t dk_appinstallservice:latest --file Dockerfile .
```

multi-arch build and push to docker hub  
```
docker buildx create --name dk_appinstallservice_multiarch_build --use
docker buildx use dk_appinstallservice_multiarch_build
docker buildx build --platform linux/amd64,linux/arm64 -t phongbosch/dk_appinstallservice:latest --push .
```

## run local built docker container
```
docker stop dk_appinstallservice;docker rm dk_appinstallservice;docker run -d -it --name dk_appinstallservice -v ~/.dk:/app/.dk -v /var/run/docker.sock:/var/run/docker.sock --log-opt max-size=10m --log-opt max-file=3 -v ~/.dk/dk_installapps/tmp/appCfg.json:/app/installCfg.json dk_appinstallservice:latest
```

## run docker container from docker hub
```
docker pull phongbosch/dk_appinstallservice:latest
docker stop dk_appinstallservice;docker rm dk_appinstallservice;docker run -d -it --name dk_appinstallservice -v ~/.dk:/app/.dk -v /var/run/docker.sock:/var/run/docker.sock --log-opt max-size=10m --log-opt max-file=3 -v ~/.dk/dk_installapps/tmp/appCfg.json:/app/installCfg.json phongbosch/dk_appinstallservice:latest
```

## examples to install app and service
```
docker stop dk_appinstallservice;docker rm dk_appinstallservice;docker run -d -it --name dk_appinstallservice -v ~/.dk:/app/.dk -v /var/run/docker.sock:/var/run/docker.sock --log-opt max-size=10m --log-opt max-file=3 -v /home/sdv/working/repos/dk_appinstallservice/scripts/appCfg.json:/app/installCfg.json dk_appinstallservice:latest

docker stop dk_appinstallservice;docker rm dk_appinstallservice;docker run -d -it --name dk_appinstallservice -v ~/.dk:/app/.dk -v /var/run/docker.sock:/var/run/docker.sock --log-opt max-size=10m --log-opt max-file=3 -v /home/developer/working/repos/dk_appinstallservice/scripts/serviceCfg.json:/app/installCfg.json dk_appinstallservice:latest
```
