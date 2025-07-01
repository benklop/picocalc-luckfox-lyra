#!/bin/bash
# Wrapper script for tar to make --no-same-owner default when running as root
# This prevents ownership issues in containerized build environments

# Get the original tar binary path
TAR_ORIG="$0.orig"

# If running as root and no explicit ownership flags are set, add --no-same-owner
if [ "$(id -u)" = "0" ]; then
    # Check if any ownership-related flags are already present
    OWNERSHIP_FLAGS_PRESENT=0
    for arg in "$@"; do
        case "$arg" in
            --same-owner|--no-same-owner|--same-permissions|--no-same-permissions)
                OWNERSHIP_FLAGS_PRESENT=1
                break
                ;;
        esac
    done
    
    # If no ownership flags are present, add --no-same-owner
    if [ "$OWNERSHIP_FLAGS_PRESENT" = "0" ]; then
        # Check if this is an extract operation (contains -x or --extract)
        EXTRACT_OPERATION=0
        for arg in "$@"; do
            case "$arg" in
                -x|--extract|--get|-*x*)
                    EXTRACT_OPERATION=1
                    break
                    ;;
            esac
        done
        
        if [ "$EXTRACT_OPERATION" = "1" ]; then
            exec "$TAR_ORIG" --no-same-owner "$@"
        fi
    fi
fi

# Default behavior: just call the original tar
exec "$TAR_ORIG" "$@"
