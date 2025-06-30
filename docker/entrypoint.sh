#!/bin/bash

# If arguments are provided, pass them to the SDK build script
if [ $# -gt 0 ]; then
    echo "Running SDK build.sh with arguments: $@"
    ./build.sh "$@"
    exit $?
fi
