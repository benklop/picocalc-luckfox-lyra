#!/bin/bash

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

# Function to resolve symlinks in firmware directory
resolve_firmware_symlinks() {
    local firmware_dir="/opt/Lyra-SDK/output/firmware"
    
    if [ ! -d "$firmware_dir" ]; then
        echo "No firmware directory found at $firmware_dir"
        return 0
    fi
    
    echo "Resolving symlinks in firmware directory..."
    
    # Find all symlinks in the firmware directory and resolve them
    find "$firmware_dir" -type l | while read -r symlink; do
        local filename=$(basename "$symlink")
        
        # Skip if the symlink target doesn't exist
        if [ ! -e "$symlink" ]; then
            echo "  Skipping $filename (target not found)"
            continue
        fi
        
        echo "  Resolving $filename"
        # Copy the target file to a temporary location, then move it to replace the symlink
        cp -L "$symlink" "$symlink.tmp" && mv "$symlink.tmp" "$symlink"
    done
    
    echo "Firmware symlinks resolved"
}

copy_upgrade_utility() {
    local upgrade_utility_path="/opt/Lyra-SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool"
    
    if [ -f "$upgrade_utility_path" ]; then
        echo "Copying upgrade utility to output directory..."
        cp "$upgrade_utility_path" /opt/Lyra-SDK/output/
        echo "Upgrade utility copied successfully"
    else
        echo "Warning: Upgrade utility not found at $upgrade_utility_path"
    fi
}

copy_misc_files() {
    local kconfig_path="/opt/Lyra-SDK/kernel/.config"

    if [ -f "$kconfig_path" ]; then
        echo "Copying kernel config to output directory..."
        cp "$kconfig_path" /opt/Lyra-SDK/output/kernel-config
        echo "Kernel config copied successfully"
    else
        echo "Warning: Kernel config not found at $kconfig_path"
    fi
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
    EXIT_CODE=$?
    
    # After build completes, resolve firmware symlinks so they persist outside the container
    if [ $EXIT_CODE -eq 0 ]; then
        resolve_firmware_symlinks
    fi

    if [ $EXIT_CODE -eq 0 ]; then
        echo "SDK build completed successfully"

        copy_upgrade_utility
        copy_misc_files
    else
        echo "Error: SDK build failed with exit code $EXIT_CODE"
    fi
fi
 
exit $EXIT_CODE
