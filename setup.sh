#!/bin/bash -e

# Build the Docker image
echo "Building Docker image..."
docker build --build-arg DOCKER_USER=$USER --build-arg DOCKER_USERID=$UID -t picocalc-lyra-builder .

echo "Downloading and unpacking the SDK..."
# Set up the initial defconfig (replaces ./build.sh lunch)
if [ $# -gt 0 ]; then
    ./build.sh "$@"
else
    ./build.sh lunch
fi
