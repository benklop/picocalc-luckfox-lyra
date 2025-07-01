#!/bin/bash -e

# Create output directory for build artifacts
mkdir -p "$(pwd)/output"
mkdir -p "$(pwd)/.ccache"
mkdir -p "$(pwd)/buildroot-output"

# Build the Docker image
echo "Building Docker image..."
docker build -t picocalc-lyra-builder .

# Set up the initial defconfig (replaces ./build.sh lunch)
./build.sh picocalc_luckfox_lyra_buildroot_sdmmc_defconfig