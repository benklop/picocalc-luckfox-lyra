#!/bin/bash

# Set up symlinks to the mounted directories (which are owned by the host user)
# This allows the build process to work regardless of the user ID
if [ -d "/tmp/output" ]; then
    rm -rf /opt/Lyra-SDK/output
    ln -sf /tmp/output /opt/Lyra-SDK/output
fi

if [ -d "/tmp/config" ]; then
    rm -rf /opt/Lyra-SDK/buildroot/configs
    ln -sf /tmp/config /opt/Lyra-SDK/buildroot/configs
fi

if [ -d "/tmp/buildroot-output" ]; then
    rm -rf /opt/Lyra-SDK/buildroot/output
    ln -sf /tmp/buildroot-output /opt/Lyra-SDK/buildroot/output
fi

# If arguments are provided, pass them to the SDK build script
if [ $# -gt 0 ]; then
    echo "Running SDK build.sh with arguments: $@"
    ./build.sh "$@"
    exit $?
fi
