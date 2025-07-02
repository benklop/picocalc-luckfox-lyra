#!/bin/bash -e

# Build script for PicoCalc Lyra Docker container
# This script builds a Docker image that can compile a custom BuildRoot Linux image
# for the LuckFox Lyra, tailored to run on the ClockworkPi PicoCalc.

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS] [BUILD_ARGS...]"
    echo "Options:"
    echo "  --package-set PATH    Apply additional buildroot package set from PATH"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all                           # Standard build"
    echo "  $0 --package-set ./extra-pkgs all # Build with additional packages"
    echo "  $0 --package-set /path/to/pkgs picocalc_luckfox_lyra_buildroot_sdmmc_defconfig"
    exit 1
}

# Parse command line arguments
PACKAGE_SET_PATH=""
BUILD_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --package-set)
            PACKAGE_SET_PATH="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            BUILD_ARGS+=("$1")
            shift
            ;;
    esac
done

# Validate package set path if provided
if [[ -n "$PACKAGE_SET_PATH" ]]; then
    if [[ ! -d "$PACKAGE_SET_PATH" ]]; then
        echo "Error: Package set directory '$PACKAGE_SET_PATH' does not exist"
        exit 1
    fi
    PACKAGE_SET_PATH=$(realpath "$PACKAGE_SET_PATH")
    echo "Using package set: $PACKAGE_SET_PATH"
fi

# Run the Docker container 
echo "Running build container..."
echo "Mounted output directory to /opt/Lyra-SDK/output"
echo "Mounted configs directory to /opt/Lyra-SDK/buildroot/configs"
echo "Mounted buildroot output directory to /opt/Lyra-SDK/buildroot/output"

# Run the container with a name so we can copy files out later
CONTAINER_NAME="picocalc-lyra-build-$(date +%s)"

# Prepare Docker volume mounts
DOCKER_VOLUMES=(
    "-v" "$(pwd)/.ccache:/home/build/.ccache:Z"
    "-v" "$(pwd)/output:/opt/Lyra-SDK/output:Z"
    "-v" "$(pwd)/config:/opt/Lyra-SDK/buildroot/configs:Z"
    "-v" "$(pwd)/buildroot-output:/opt/Lyra-SDK/buildroot/output:Z"
)

# Add package set volume if specified
if [[ -n "$PACKAGE_SET_PATH" ]]; then
    DOCKER_VOLUMES+=("-v" "$PACKAGE_SET_PATH:/opt/package-set:Z")
    # Add the package set flag to the build arguments
    BUILD_ARGS=("--package-set" "/opt/package-set" "${BUILD_ARGS[@]}")
fi

# Prepare environment variables
DOCKER_ENV=(
    "-e" "CCACHE_DIR=/home/build/.ccache"
)

# Run the container
docker run -it --rm --name "$CONTAINER_NAME" \
    "${DOCKER_VOLUMES[@]}" \
    "${DOCKER_ENV[@]}" \
    -w /opt/Lyra-SDK \
    picocalc-lyra-builder "${BUILD_ARGS[@]}"
