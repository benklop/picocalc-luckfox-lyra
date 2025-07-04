#!/bin/bash
set -e

CUR_PATH=$(cd "$(dirname $0)";pwd)
SRC_PATH=$CUR_PATH/base
SDK_PATH=$CUR_PATH
IFS=$'\n'

echo "SRC_PATH: $SRC_PATH"
echo "SDK_PATH: $SDK_PATH" 

# remove old overlay to delete files that might not be needed anymore
rm -rf $SDK_PATH/buildroot/board/rockchip/rk3506/picocalc-overlay

# check SDK path
if [ -e $SRC_PATH ]
then
    for file in `ls $SRC_PATH`
    do
        if [ -d $SRC_PATH"/"$file ]
        then
            if [ ! -d $SDK_PATH"/"$file ]
            then
                echo "error: not a SDK path!"
                exit
            fi
        fi
    done
else
    echo "error: not a source path!"
    exit
fi

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
echo "Copying files from $SRC_PATH to $SDK_PATH..."
copy_files "$SRC_PATH" "$SDK_PATH"

echo "Applying patches..."
apply_patches "$SRC_PATH" "$SDK_PATH"

# Fix issue with running build in docker
sed -i 's/btrfs/btrfs | overlay/' $SDK_PATH/device/rockchip/common/scripts/check-sdk.sh