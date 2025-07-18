#!/bin/bash
# Wra        # Check for extract operations
        if [[ "$arg" =~ ^-[^-]*x ]] || [[ "$arg" == "--extract" ]] || [[ "$arg" == "--get" ]] || [[ "$arg" == "-x" ]]; then
            IS_EXTRACT=1
        fi script for tar to make --no-same-owner default when running as root
# This prevents ownership issues in containerized build environments

# Get the original tar binary path
TAR_ORIG="$0.orig"

# Basic logging for troubleshooting (can be disabled by commenting out)
# echo "tar wrapper: $@" >> /opt/Lyra-SDK/output/sessions/tar-wrapper.log

# If running as root, check if we should add --no-same-owner
if [ "$(id -u)" = "0" ]; then
    # Check arguments for extract operation and existing ownership flags
    IS_EXTRACT=0
    HAS_OWNERSHIP_FLAG=0
    
    for arg in "$@"; do
        # Check for extract operations
        if [[ "$arg" =~ ^-[^-]*x || "$arg" == "--extract" || "$arg" == "--get" ]]; then
            IS_EXTRACT=1
        fi
        
        # Check for existing ownership flags
        case "$arg" in
            --same-owner|--no-same-owner|--same-permissions|--no-same-permissions)
                HAS_OWNERSHIP_FLAG=1
                ;;
        esac
    done
    
    # Add --no-same-owner only for extract operations without existing ownership flags
    if [ "$IS_EXTRACT" = "1" ] && [ "$HAS_OWNERSHIP_FLAG" = "0" ]; then
        exec "$TAR_ORIG" --no-same-owner "$@"
    fi
fi

# Default behavior: just call the original tar with all arguments preserved
exec "$TAR_ORIG" "$@"
