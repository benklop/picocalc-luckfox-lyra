#!/bin/bash -e

# Build script for PicoCalc Lyra Docker container
# This script builds a Docker image that can compile a custom BuildRoot Linux image
# for the LuckFox Lyra, tailored to run on the ClockworkPi PicoCalc.

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS] [BUILD_ARGS...]"
    echo "Options:"
    echo "  --package-set PATH    Apply buildroot package set from PATH (can be used multiple times)"
    echo "  --no-base-packages    Skip applying the base package set"
    echo "  --help               Show this help message"
    echo ""
    echo "Package sets are applied in the order specified. The base package set"
    echo "(base-package-set) is applied first by default unless --no-base-packages is used."
    echo ""
    echo "Examples:"
    echo "  $0 all                                    # Standard build with base packages"
    echo "  $0 --package-set ./extra-pkgs all        # Base + additional packages"
    echo "  $0 --no-base-packages --package-set ./custom all  # Only custom packages"
    echo "  $0 --package-set ./set1 --package-set ./set2 all  # Base + set1 + set2"
    exit 1
}

# Parse command line arguments
PACKAGE_SET_PATHS=()
APPLY_BASE_PACKAGES=true
BUILD_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --package-set)
            if [[ -n "$2" && "$2" != --* ]]; then
                PACKAGE_SET_PATHS+=("$2")
                shift 2
            else
                echo "Error: --package-set requires a path argument"
                exit 1
            fi
            ;;
        --no-base-packages)
            APPLY_BASE_PACKAGES=false
            shift
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

# Add base package set if not disabled
if [[ "$APPLY_BASE_PACKAGES" == "true" ]]; then
    BASE_PACKAGE_SET="$(pwd)/base-package-set"
    if [[ -d "$BASE_PACKAGE_SET" ]]; then
        # Prepend base package set to the beginning of the array
        PACKAGE_SET_PATHS=("$BASE_PACKAGE_SET" "${PACKAGE_SET_PATHS[@]}")
        echo "Including base package set: $BASE_PACKAGE_SET"
    else
        echo "Warning: Base package set directory '$BASE_PACKAGE_SET' does not exist"
    fi
fi

# Validate all package set paths
VALIDATED_PACKAGE_SETS=()
for PACKAGE_SET_PATH in "${PACKAGE_SET_PATHS[@]}"; do
    if [[ ! -d "$PACKAGE_SET_PATH" ]]; then
        echo "Error: Package set directory '$PACKAGE_SET_PATH' does not exist"
        exit 1
    fi
    PACKAGE_SET_PATH=$(realpath "$PACKAGE_SET_PATH")
    VALIDATED_PACKAGE_SETS+=("$PACKAGE_SET_PATH")
    echo "Using package set: $PACKAGE_SET_PATH"
done

# Run the Docker container 
echo "Running build container..."
echo "Mounted output directory to /opt/Lyra-SDK/output"
echo "Mounted configs directory to /opt/Lyra-SDK/buildroot/configs"
echo "Mounted buildroot output directory to /opt/Lyra-SDK/buildroot/output"

# Run the container with a name so we can copy files out later
CONTAINER_NAME="picocalc-lyra-build-$(date +%s)"

# Prepare Docker volume mounts
DOCKER_VOLUMES=(
    "-v" "$(pwd)/.ccache:/root/.ccache:Z"
    "-v" "$(pwd)/output:/opt/Lyra-SDK/output:Z"
    "-v" "$(pwd)/config:/opt/Lyra-SDK/buildroot/configs:Z"
    "-v" "$(pwd)/buildroot-output:/opt/Lyra-SDK/buildroot/output:Z"
)

# Add package set volumes if specified
PACKAGE_SET_ARGS=()
for i in "${!VALIDATED_PACKAGE_SETS[@]}"; do
    PACKAGE_SET_PATH="${VALIDATED_PACKAGE_SETS[$i]}"
    PACKAGE_SET_MOUNT="/opt/package-set-$i"
    DOCKER_VOLUMES+=("-v" "$PACKAGE_SET_PATH:$PACKAGE_SET_MOUNT:Z")
    PACKAGE_SET_ARGS+=("--package-set" "$PACKAGE_SET_MOUNT")
done

# Add the package set flags to the build arguments
if [[ ${#PACKAGE_SET_ARGS[@]} -gt 0 ]]; then
    BUILD_ARGS=("${PACKAGE_SET_ARGS[@]}" "${BUILD_ARGS[@]}")
fi

# Prepare environment variables
DOCKER_ENV=(
    "-e" "CCACHE_DIR=/root/.ccache"
)

# Create output directory for build artifacts
mkdir -p "$(pwd)/output"
mkdir -p "$(pwd)/.ccache"
mkdir -p "$(pwd)/buildroot-output"

# Run the container
docker run -it --rm --name "$CONTAINER_NAME" \
    "${DOCKER_VOLUMES[@]}" \
    "${DOCKER_ENV[@]}" \
    -w /opt/Lyra-SDK \
    picocalc-lyra-builder "${BUILD_ARGS[@]}"
