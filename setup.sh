#!/bin/bash -e

# URL found at https://wiki.luckfox.com/Luckfox-Lyra/Download
SDK_URL=https://drive.google.com/file/d/1bQrszU23AyFWGS9-mnIetGobsmtvg13W/view?usp=drive_link

# Create output directory for build artifacts
mkdir -p "$(pwd)/output"
mkdir -p "$(pwd)/.ccache"
mkdir -p "$(pwd)/buildroot-output"

# Ensure gdown is installed
if ! python3 -c "import gdown" 2>/dev/null; then
    echo "gdown not found, installing..."
    pip3 install --user gdown
    export PATH="$HOME/.local/bin:$PATH"
fi

# Downloading the SDK
if [ -f Luckfox_Lyra_SDK.tar.gz ]; then
    echo "Luckfox_Lyra_SDK.tar.gz already exists, skipping download."
else
    gdown --fuzzy $SDK_URL -O Luckfox_Lyra_SDK.tar.gz
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t picocalc-lyra-builder .

# Set up the initial defconfig (replaces ./build.sh lunch)
./build.sh picocalc_luckfox_lyra_buildroot_sdmmc_defconfig