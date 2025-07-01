#!/bin/bash
set -e

# Helper script to save Buildroot configuration from the last container

CONTAINER_NAME=$(docker ps -a --format "table {{.Names}}" | grep "picocalc-lyra-build" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "No picocalc-lyra-build container found."
    echo "Please run configure-buildroot.sh first."
    exit 1
fi

echo "Saving configuration from container: $CONTAINER_NAME"

# Copy the current defconfig from the container
docker exec "$CONTAINER_NAME" bash -c '
    cd buildroot
    make savedefconfig
    cp defconfig ../customizations/base/buildroot/configs/rockchip_rk3506_picocalc_luckfox_defconfig
    echo "Configuration saved to customizations/base/buildroot/configs/rockchip_rk3506_picocalc_luckfox_defconfig"
'

echo "Configuration saved! The new config will be applied on the next build."
