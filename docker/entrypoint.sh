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

# Apply additional package set if provided
apply_package_set() {
    local package_set_path="$1"
    local sdk_path="/opt/Lyra-SDK"
    
    echo "Applying package set from: $package_set_path"
    
    # Function to apply patches with .patch extension
    apply_patches() {
        local src_dir="$1"
        local dst_dir="$2"
        
        # Find all .patch files in the source directory
        find "$src_dir" -name "*.patch" | while read patch_file; do
            # Get the relative path from the source directory
            local rel_path="${patch_file#$src_dir/}"
            # Remove the .patch extension to get the target file path
            local target_file="${rel_path%.patch}"
            local target_path="$dst_dir/$target_file"
            
            if [ -f "$target_path" ]; then
                echo "Applying patch: $patch_file -> $target_path"
                if patch -p1 -d "$dst_dir" < "$patch_file"; then
                    echo "  ✓ Patch applied successfully"
                else
                    echo "  ✗ Failed to apply patch"
                    exit 1
                fi
            else
                echo "Warning: Target file $target_path does not exist for patch $patch_file"
                # Copy the patch file to the corresponding location in the destination directory
                mkdir -p "$(dirname "$target_path")"
                cp "$patch_file" "$target_path.patch"
            fi
        done
    }
    
    # Function to copy files, excluding .patch files
    copy_files() {
        local src="$1"
        local dst="$2"
        
        # Use rsync to copy files, excluding .patch files
        rsync -av --exclude="*.patch" "$src/" "$dst/"
    }
    
    # Copy files (excluding .patch files) and then apply patches
    echo "Copying package set files from $package_set_path to $sdk_path..."
    copy_files "$package_set_path" "$sdk_path"
    
    echo "Applying package set patches..."
    apply_patches "$package_set_path" "$sdk_path"
    
    echo "Package set applied successfully"
}

# Parse command line arguments to extract package set information
PACKAGE_SET_PATH=""
FILTERED_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --package-set)
            if [[ -n "$2" && "$2" != --* ]]; then
                PACKAGE_SET_PATH="$2"
                shift 2
            else
                echo "Error: --package-set requires a path argument"
                exit 1
            fi
            ;;
        *)
            FILTERED_ARGS+=("$1")
            shift
            ;;
    esac
done

# Check if a package set should be applied
if [ -n "$PACKAGE_SET_PATH" ]; then
    if [ -d "$PACKAGE_SET_PATH" ]; then
        apply_package_set "$PACKAGE_SET_PATH"
    else
        echo "Error: Package set path '$PACKAGE_SET_PATH' does not exist or is not a directory"
        ls -la "$PACKAGE_SET_PATH" 2>/dev/null || echo "Cannot list contents of $PACKAGE_SET_PATH"
        exit 1
    fi
fi

# If arguments are provided (after filtering), pass them to the SDK build script
if [ ${#FILTERED_ARGS[@]} -gt 0 ]; then
    echo "Running SDK build.sh with arguments: ${FILTERED_ARGS[@]}"
    ./build.sh "${FILTERED_ARGS[@]}"
    exit $?
fi
