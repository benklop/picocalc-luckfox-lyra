#!/bin/bash -e

# Build script for PicoCalc Lyra Docker container
# This script builds a Docker image that can compile a custom BuildRoot Linux image
# for the LuckFox Lyra, tailored to run on the ClockworkPi PicoCalc.

# Create output directory for build artifacts
mkdir -p "$(pwd)/output"
mkdir -p "$(pwd)/.ccache"
chmod o+rwx "$(pwd)/output"
chmod o+rwx "$(pwd)/.ccache"

# Build the Docker image
echo "Building Docker image..."
docker build -t picocalc-lyra-builder .

# Run the Docker container 
echo "Running build container..."

# Run the container with a name so we can copy files out later
CONTAINER_NAME="picocalc-lyra-build-$(date +%s)"

# Pass any arguments to the container entrypoint
docker run -it --name "$CONTAINER_NAME" \
    -v "$(pwd)/.ccache:/home/build/.ccache:Z" \
    -v "$(pwd)/output:/opt/Lyra-SDK/output:Z" \
    picocalc-lyra-builder "$@"
