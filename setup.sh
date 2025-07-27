#!/bin/bash -e

# Build the Docker image
echo "Building Docker image..."
docker build --build-arg DOCKER_USER=$USER --build-arg DOCKER_USERID=$UID -t picocalc-lyra-builder .

echo "Downloading and unpacking the SDK..."
# Set up the initial defconfig (replaces ./build.sh lunch)
./build.sh picocalc_luckfox_lyra_buildroot_sdmmc_defconfig
