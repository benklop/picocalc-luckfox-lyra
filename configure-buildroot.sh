#!/bin/bash
set -e

# Helper script to save Buildroot configuration from container to host

CONTAINER_NAME="picocalc-lyra-build-$(date +%s)"

echo "Starting container for Buildroot configuration..."

# Start container in background
docker run -d --name "$CONTAINER_NAME" \
    -v "$(pwd)/.ccache:/home/build/.ccache:Z" \
    -v "$(pwd)/output:/opt/Lyra-SDK/output:Z" \
    picocalc-lyra-builder sleep 3600

echo "Container started. You can now run:"
echo "  docker exec -it $CONTAINER_NAME bash"
echo ""
echo "Inside the container, run:"
echo "  cd buildroot"
echo "  make menuconfig    # or any other config target"
echo "  make savedefconfig"
echo "  cp defconfig ../customizations/base/buildroot/configs/rockchip_rk3506_picocalc_luckfox_defconfig"
echo ""
echo "When done, run: docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo ""
echo "Or use the companion save-config.sh script to copy the config automatically."
