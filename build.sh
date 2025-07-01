#!/bin/bash -e

# Build script for PicoCalc Lyra Docker container
# This script builds a Docker image that can compile a custom BuildRoot Linux image
# for the LuckFox Lyra, tailored to run on the ClockworkPi PicoCalc.

# Run the Docker container 
echo "Running build container..."

# Run the container with a name so we can copy files out later
CONTAINER_NAME="picocalc-lyra-build-$(date +%s)"

# Pass any arguments to the container entrypoint
docker run -it --name "$CONTAINER_NAME" \
    --user "$(id -u):$(id -g)" \
    -v "$(pwd)/.ccache:/tmp/.ccache:Z" \
    -v "$(pwd)/output:/tmp/output:Z" \
    -v "$(pwd)/config:/tmp/config:Z" \
    -e CCACHE_DIR=/tmp/.ccache \
    -w /opt/Lyra-SDK \
    picocalc-lyra-builder "$@"
