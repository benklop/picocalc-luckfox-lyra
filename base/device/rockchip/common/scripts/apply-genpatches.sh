#!/bin/bash -e

# Apply Gentoo genpatches to kernel if enabled
# This script should be called before kernel compilation

apply_genpatches() {
	# Only apply if Gentoo is enabled and genpatches option is set
	if [ "${RK_GENTOO:-n}" != "y" ] || [ "${RK_GENTOO_KERNEL_GENPATCHES:-n}" != "y" ]; then
		return 0
	fi

	KERNEL_DIR="$RK_SDK_DIR/kernel"
	GENPATCHES_DIR="$KERNEL_DIR/.genpatches"
	
	# Check if genpatches already applied
	if [ -f "$GENPATCHES_DIR/.applied" ]; then
		message "Genpatches already applied"
		return 0
	fi

	# Get kernel version
	KERNEL_VERSION_MAJOR=$(echo "$RK_KERNEL_VERSION" | cut -d. -f1)
	KERNEL_VERSION_MINOR=$(echo "$RK_KERNEL_VERSION" | cut -d. -f2)
	KERNEL_VERSION_SHORT="${KERNEL_VERSION_MAJOR}.${KERNEL_VERSION_MINOR}"

	message "Applying Gentoo genpatches for kernel $KERNEL_VERSION_SHORT..."

	mkdir -p "$GENPATCHES_DIR"
	cd "$GENPATCHES_DIR"

	# Download genpatches for the kernel version
	GENPATCHES_BASE_URL="https://dev.gentoo.org/~mpagano/genpatches/trunk"
	GENPATCHES_VERSION_URL="$GENPATCHES_BASE_URL/$KERNEL_VERSION_SHORT"
	
	# Try to get the latest genpatches version
	message "Checking for available genpatches..."
	
	# Download the experimental tarball which contains the latest patches
	GENPATCHES_TAR="genpatches-${KERNEL_VERSION_SHORT}-1.experimental.tar.xz"
	GENPATCHES_URL="$GENPATCHES_VERSION_URL/$GENPATCHES_TAR"
	
	if wget -q --spider "$GENPATCHES_URL" 2>/dev/null; then
		message "Downloading $GENPATCHES_TAR..."
		wget -c "$GENPATCHES_URL" -O "$GENPATCHES_TAR" || {
			warning "Failed to download genpatches, trying base patches..."
			# Fallback to base patches
			GENPATCHES_TAR="genpatches-${KERNEL_VERSION_SHORT}-1.base.tar.xz"
			GENPATCHES_URL="$GENPATCHES_VERSION_URL/$GENPATCHES_TAR"
			wget -c "$GENPATCHES_URL" -O "$GENPATCHES_TAR" || {
				warning "Could not download genpatches for $KERNEL_VERSION_SHORT"
				return 0
			}
		}
	else
		# Try base patches
		GENPATCHES_TAR="genpatches-${KERNEL_VERSION_SHORT}-1.base.tar.xz"
		GENPATCHES_URL="$GENPATCHES_VERSION_URL/$GENPATCHES_TAR"
		
		if wget -q --spider "$GENPATCHES_URL" 2>/dev/null; then
			message "Downloading base patches $GENPATCHES_TAR..."
			wget -c "$GENPATCHES_URL" -O "$GENPATCHES_TAR" || {
				warning "Could not download genpatches for $KERNEL_VERSION_SHORT"
				return 0
			}
		else
			warning "No genpatches available for kernel $KERNEL_VERSION_SHORT"
			return 0
		fi
	fi

	# Extract genpatches
	message "Extracting genpatches..."
	tar xf "$GENPATCHES_TAR"
	
	# Find the extracted directory
	GENPATCHES_EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "genpatches-*" | head -n1)
	if [ -z "$GENPATCHES_EXTRACTED_DIR" ]; then
		warning "Could not find extracted genpatches directory"
		return 0
	fi

	cd "$GENPATCHES_EXTRACTED_DIR"

	# Apply patches in order
	# First apply base patches, then experimental if available
	for patch_dir in base experimental extras; do
		if [ -d "$patch_dir" ]; then
			message "Applying $patch_dir patches..."
			for patch in "$patch_dir"/*.patch; do
				if [ -f "$patch" ]; then
					message "  Applying $(basename "$patch")..."
					if ! patch -p1 -d "$KERNEL_DIR" -t < "$patch"; then
						warning "Failed to apply patch $(basename "$patch"), skipping..."
						continue
					fi
				fi
			done
		fi
	done

	# Mark as applied
	touch "$GENPATCHES_DIR/.applied"
	echo "Applied genpatches for kernel $KERNEL_VERSION_SHORT on $(date)" > "$GENPATCHES_DIR/.applied"
	
	message "Genpatches applied successfully"
}

# Apply genpatches if this script is called directly
if [ "$BASH_SOURCE" = "$0" ]; then
	# Source build environment if not already sourced
	if [ -z "$RK_SESSION" ]; then
		RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
		source "$RK_SCRIPTS_DIR/build-helper"
		load_config RK_GENTOO RK_GENTOO_KERNEL_GENPATCHES
	fi
	
	apply_genpatches
fi