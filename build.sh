#!/bin/bash -e

# Build script for PicoCalc Lyra Docker container
# This script builds a Docker image that can compile a custom BuildRoot Linux image
# for the LuckFox Lyra, tailored to run on the ClockworkPi PicoCalc.

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS] [BUILD_ARGS...]"
    echo "Options:"
    echo "  --overlay PATH    Apply buildroot overlay from PATH (can be used multiple times)"
    echo "  --no-base-packages    Skip applying the base overlay"
    echo "  --help               Show this help message"
    echo ""
    echo "Overlays are applied in the order specified. The base overlay"
    echo "(base-overlay) is applied first by default unless --no-base-packages is used."
    echo ""
    echo "Examples:"
    echo "  $0 all                                    # Standard build with base packages"
    echo "  $0 --overlay ./extra-pkgs all        # Base + additional packages"
    echo "  $0 --no-base-packages --overlay ./custom all  # Only custom packages"
    echo "  $0 --overlay ./set1 --overlay ./set2 all  # Base + set1 + set2"
    exit 1
}

# Parse command line arguments
OVERLAY_PATHS=()
APPLY_BASE_PACKAGES=true
BUILD_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --overlay)
            if [[ -n "$2" && "$2" != --* ]]; then
                OVERLAY_PATHS+=("$2")
                shift 2
            else
                echo "Error: --overlay requires a path argument"
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

# Add base overlay if not disabled
if [[ "$APPLY_BASE_PACKAGES" == "true" ]]; then
    BASE_OVERLAY="$(pwd)/base"
    if [[ -d "$BASE_OVERLAY" ]]; then
        # Prepend base overlay to the beginning of the array
        OVERLAY_PATHS=("$BASE_OVERLAY" "${OVERLAY_PATHS[@]}")
        echo "Including base overlay: $BASE_OVERLAY"
    else
        echo "Warning: Base overlay directory '$BASE_OVERLAY' does not exist"
    fi
fi

# Validate all overlay paths
VALIDATED_OVERLAYS=()
for OVERLAY_PATH in "${OVERLAY_PATHS[@]}"; do
    if [[ ! -d "$OVERLAY_PATH" ]]; then
        echo "Error: Overlay directory '$OVERLAY_PATH' does not exist"
        exit 1
    fi
    OVERLAY_PATH=$(realpath "$OVERLAY_PATH")
    VALIDATED_OVERLAYS+=("$OVERLAY_PATH")
    echo "Using overlay: $OVERLAY_PATH"
done

# Run the Docker container 
echo "Running build container..."
echo "Mounting SDK directory to /opt/Lyra-SDK"

mkdir -p "$(pwd)/SDK"

# Run the container with a name so we can copy files out later
CONTAINER_NAME="picocalc-lyra-build-$(date +%s)"

# Prepare Docker volume mounts
DOCKER_VOLUMES=(
    "-v" "$(pwd)/.ccache:/root/.ccache:Z"
    "-v" "$(pwd)/SDK:/opt/Lyra-SDK:Z"
)

# Add overlay volumes if specified
OVERLAY_ARGS=()
for i in "${!VALIDATED_OVERLAYS[@]}"; do
    OVERLAY_PATH="${VALIDATED_OVERLAYS[$i]}"
    OVERLAY_MOUNT="/opt/overlay-$i"
    DOCKER_VOLUMES+=("-v" "$OVERLAY_PATH:$OVERLAY_MOUNT:Z")
    OVERLAY_ARGS+=("--overlay" "$OVERLAY_MOUNT")
done

# Add the overlay flags to the build arguments
if [[ ${#OVERLAY_ARGS[@]} -gt 0 ]]; then
    BUILD_ARGS=("${OVERLAY_ARGS[@]}" "${BUILD_ARGS[@]}")
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
