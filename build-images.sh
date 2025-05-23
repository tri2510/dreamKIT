#!/bin/bash

# Define an array of services and their paths
services=(
  "dk-ivi-lite:./dreamos-core/dk-ivi-lite"
  "dk_appinstallservice:./dreamos-core/dk_appinstallservice"
  "dk-manager:./dreamos-core/dk-manager"
)

# Define additional images to pull
images=(
  "ghcr.io/eclipse/kuksa.val/kuksa-client:0.4.2"
  "ghcr.io/eclipse-autowrx/sdv-runtime:latest"
  "ghcr.io/samtranbosch/dk_manager:latest"
  "phongbosch/dk_vssgeneration_image:vss4.0"
  "ghcr.io/samtranbosch/dk_appinstallservice:latest"
  "ghcr.io/samtranbosch/dk_ivi:latest"
)

# Iterate over each service and build its Docker image
for service in "${services[@]}"; do
  IFS=":" read -r name path <<< "$service"
  echo "Building image for $name from $path"
  docker build -t "$name:latest" "$path"
done

# Pull additional images
for image in "${images[@]}"; do
  echo "Pulling image: $image"
  docker pull "$image"
done

echo "All images have been built or pulled successfully."
