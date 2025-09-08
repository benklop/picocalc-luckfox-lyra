#!/bin/bash

unpack_sdk() {
    echo "Checking if SDK is already unpacked..."
    if [ -f /opt/Lyra-SDK/.sdk_initialized ]; then
        echo "SDK is already unpacked and initialized."
        return 0
    fi
    echo "SDK not unpacked, Retrieving..."

    # URL found at https://wiki.luckfox.com/Luckfox-Lyra/Download
    # Update notices: https://forums.luckfox.com/viewtopic.php?t=1420
    # updated URL 2025-08-15
    SDK_URL=https://drive.google.com/file/d/15nq-Fac9q6zmisKZgLDZyoifSkL_48rG/view?usp=drive_link
    sdk_tarball_path="/opt/download/Luckfox_Lyra_SDK.tar.gz"

    # Downloading the SDK
    if [ -f "$sdk_tarball_path" ]; then
        echo "Luckfox_Lyra_SDK.tar.gz already exists, skipping download."
    else
        echo "Downloading the SDK from: $SDK_URL..."
        if [ -t 1 ]; then
            gdown --fuzzy $SDK_URL -O "$sdk_tarball_path"
        else
            gdown --fuzzy --quiet $SDK_URL -O "$sdk_tarball_path"
        fi
    fi

    if [ ! -f "$sdk_tarball_path" ]; then
        echo "Error: SDK tarball not found at $sdk_tarball_path"
        exit 1
    fi

    echo "Unpacking SDK from $sdk_tarball_path..."
    
    # Extract the SDK tarball
    tar -xzf "$sdk_tarball_path" -C /opt/Lyra-SDK

    echo "SDK unpacked successfully"

    echo "Initializing SDK..."
    pushd /opt/Lyra-SDK || exit 1
        ./.repo/repo/repo sync -l

        # Fix issue with running build in docker - the SDK has a whitelist of filesystems
        # but it doesn't recognize overlayfs which is used by docker.
        echo "Patching SDK to support overlayfs..."
        sed -i 's/btrfs/btrfs | overlay/' device/rockchip/common/scripts/check-sdk.sh

        echo "SDK initialized successfully"
        touch /opt/Lyra-SDK/.sdk_initialized

        echo "Extracting image generation tool.."
        pushd tools/linux/programming_image_tool || exit 1
            tar --strip-components=1 -xvf programmer_image_tool*.tar
        popd || exit 1
    popd || exit 1
}

# Apply additional overlay if provided
apply_overlay() {
    local overlay_path="$1"
    local sdk_path="/opt/Lyra-SDK"
    
    echo "Applying overlay from: $overlay_path"
    
    # Function to apply patches with .patch extension
    apply_patches() {
        local src_dir="$1"
        local dst_dir="$2"
        local patch_failed=false
        local applied_patches_dir="$dst_dir/.applied-patches"
        
        # Create the applied patches tracking directory
        mkdir -p "$applied_patches_dir"
        
        # Find all .patch files in the source directory
        while IFS= read -r -d '' patch_file; do
            # Get the relative path from the source directory
            local rel_path="${patch_file#$src_dir/}"
            # Remove the .patch extension to get the target file path
            local target_file="${rel_path%.patch}"
            local target_path="$dst_dir/$target_file"
            
            if [ -f "$target_path" ]; then
                # This is a regular patch file (not a buildroot package patch)
                local applied_patch_path="$applied_patches_dir/$rel_path"
                
                echo "Checking patch: $patch_file -> $target_path"
                
                if [ -f "$applied_patch_path" ] && cmp -s "$patch_file" "$applied_patch_path"; then
                    # Patch is already applied and matches current version
                    echo "  ⚠ Patch already applied and up-to-date, skipping"
                elif [ -f "$applied_patch_path" ]; then
                    # Patch was applied but doesn't match current version - need to update
                    echo "  🔄 Patch has changed, updating..."
                    
                    # Try to unapply the old patch
                    if patch -R -f -p1 -d "$dst_dir" < "$applied_patch_path" >/dev/null 2>&1; then
                        echo "  ✓ Old patch unapplied successfully"
                    else
                        echo "  ⚠ Could not cleanly unapply old patch, proceeding anyway"
                        patch_failed=true
                    fi
                    
                    # Remove old patch from tracking
                    rm -f "$applied_patch_path"
                    
                    # Apply new patch
                    echo "  Applying updated patch: $patch_file -> $target_path"
                    if patch -N -f -p1 -d "$dst_dir" < "$patch_file"; then
                        echo "  ✓ Updated patch applied successfully"
                        # Save the new patch to tracking
                        mkdir -p "$(dirname "$applied_patch_path")"
                        cp "$patch_file" "$applied_patch_path"
                    else
                        patch_exit_code=$?
                        echo "  ✗ Failed to apply updated patch (exit code: $patch_exit_code)"
                        patch_failed=true
                    fi
                else
                    # Patch not applied yet
                    echo "  Applying patch: $patch_file -> $target_path"
                    if patch -N -f -p1 -d "$dst_dir" < "$patch_file"; then
                        echo "  ✓ Patch applied successfully"
                        # Save the patch to tracking
                        mkdir -p "$(dirname "$applied_patch_path")"
                        cp "$patch_file" "$applied_patch_path"
                    else
                        patch_exit_code=$?
                        echo "  ✗ Failed to apply patch (exit code: $patch_exit_code)"
                        patch_failed=true
                    fi
                fi
            else
                # Get the filename without path
                local patch_filename="$(basename "$patch_file")"
                
                # Check if patch filename starts with leading zeroes (buildroot package patch)
                if [[ "$patch_filename" =~ ^[0-9] ]]; then
                    # Suppress warning for buildroot package patches
                    echo "  ℹ Buildroot package patch: $patch_filename"
                    # For buildroot package patches, preserve the original filename
                    local dest_patch_path="$(dirname "$target_path")/$patch_filename"
                    local applied_patch_path="$applied_patches_dir/$rel_path"
                    
                    # Check if this buildroot patch is already copied and up-to-date
                    if [ -f "$dest_patch_path" ] && [ -f "$applied_patch_path" ] && cmp -s "$patch_file" "$applied_patch_path"; then
                        echo "  ✓ Package patch already copied and up-to-date"
                    else
                        mkdir -p "$(dirname "$dest_patch_path")"
                        cp "$patch_file" "$dest_patch_path"
                        echo "  ✓ Package patch copied to: $dest_patch_path"
                        # Track this buildroot patch too
                        mkdir -p "$(dirname "$applied_patch_path")"
                        cp "$patch_file" "$applied_patch_path"
                    fi
                else
                    echo "Warning: Target file $target_path does not exist for patch $patch_file"
                    # Copy the patch file to the corresponding location in the destination directory
                    mkdir -p "$(dirname "$target_path")"
                    cp "$patch_file" "$target_path.patch"
                fi
            fi
        done < <(find "$src_dir" -name "*.patch" -print0)
        
        if [ "$patch_failed" = true ]; then
            echo "Warning: Some patches failed to apply, but continuing with remaining overlays"
            return 1
        fi
        return 0
    }
    
    # Function to copy files, excluding .patch files
    copy_files() {
        local src="$1"
        local dst="$2"
        
        # Use rsync to copy files, excluding .patch files
        rsync -av --exclude="*.patch" "$src/" "$dst/"
    }
    
    # Copy files (excluding .patch files) and then apply patches
    echo "Copying overlay files from $overlay_path to $sdk_path..."
    copy_files "$overlay_path" "$sdk_path"

    echo "Applying overlay patches..."
    if apply_patches "$overlay_path" "$sdk_path"; then
        echo "Overlay applied successfully"
    else
        echo "Overlay applied with some patch failures"
        return 1
    fi
}

unpack_sdk

# Parse command line arguments to extract overlay information
OVERLAY_PATHS=()
FILTERED_ARGS=()

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
        *)
            FILTERED_ARGS+=("$1")
            shift
            ;;
    esac
done

# Apply all overlays in order
for OVERLAY_PATH in "${OVERLAY_PATHS[@]}"; do
    if [ -d "$OVERLAY_PATH" ]; then
        apply_overlay "$OVERLAY_PATH"
    else
        echo "Error: Overlay path '$OVERLAY_PATH' does not exist or is not a directory"
        ls -la "$OVERLAY_PATH" 2>/dev/null || echo "Cannot list contents of $OVERLAY_PATH"
        exit 1
    fi
done

# If arguments are provided (after filtering), pass them to the SDK build script
if [ ${#FILTERED_ARGS[@]} -gt 0 ]; then
    echo "Running SDK build.sh with arguments: ${FILTERED_ARGS[@]}"
    ./build.sh "${FILTERED_ARGS[@]}"
    EXIT_CODE=$?
fi
 
exit $EXIT_CODE
