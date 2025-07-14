# dk_service_coffee

> Information: 
This docker image provides a service to make the coffee running on dreamOS.  
Supported APIs:
```
Vehicle.BYOD.CoffeeMachine.Brew
```

## Presequisites
dreamOS must be installed first. Refer to this repo (https://github.com/ppa2hc/dk_installation) for dreamOS installation.  

## build docker image
local-arch build  
```
docker build -t dk_service_coffee:latest --file Dockerfile .
```

multi-arch build and push to docker hub  
```
docker buildx create --name dk_service_coffee_multiarch_build --use
docker buildx build --platform linux/amd64,linux/arm64 -t phongbosch/dk_service_coffee:latest --push .
```

## run local built docker container
```
docker stop dk_service_coffee;docker rm dk_service_coffee;docker run -d -it --name dk_service_coffee --network host --restart unless-stopped --log-opt max-size=10m --log-opt max-file=3 dk_service_coffee:latest
```

## run docker container from docker hub
```
docker pull phongbosch/dk_service_coffee:latest
docker stop dk_service_coffee;docker rm dk_service_coffee;docker run -d -it --name dk_service_coffee --network host --restart unless-stopped --log-opt max-size=10m --log-opt max-file=3 phongbosch/dk_service_coffee:latest
```