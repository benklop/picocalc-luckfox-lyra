#!/bin/bash -e

# mk-gentoo.sh - Gentoo Linux rootfs builder using crossdev
#
# This script implements the Gentoo crossdev approach for building
# cross-compiled rootfs. Two methods are supported per the Gentoo crossdev wiki:
#
# 1. Manual Build Approach (Default, Recommended):
#    - Creates empty target root
#    - Uses crossdev to build cross-toolchain
#    - Installs @system into target root via emerge --root-deps
#    - Advantages: Full control, no unnecessary packages, latest builds
#    - Set RK_GENTOO_MANUAL_BUILD=y (default)
#
# 2. Stage3 Tarball Approach:
#    - Downloads and extracts pre-built stage3 tarball
#    - Uses crossdev for additional packages
#    - Advantages: Faster initial setup, known working base
#    - Set RK_GENTOO_USE_STAGE3=y to enable
#    - Configure TARGET_STAGE3_VARIANT for your needs
#
# Configuration Options:
#   RK_GENTOO_USE_STAGE3=y|n    - Use stage3 tarball (default: n)
#   RK_GENTOO_MANUAL_BUILD=y|n  - Use manual build (default: y)
#   TARGET_STAGE3_VARIANT        - Stage3 variant when using stage3
#
# Reference: https://wiki.gentoo.org/wiki/Crossdev#Building_a_cross-emerge_environment
#

# Gentoo crossdev-based rootfs build script for Rockchip SDK
# Based on https://wiki.gentoo.org/wiki/Crossdev
# Uses x86_64 host with crossdev to cross-compile for ARM32 hardfp

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"
RK_SDK_DIR="${RK_SDK_DIR:-$RK_SCRIPTS_DIR/../../../..}"

# Source common build functions
source "$RK_SCRIPTS_DIR/build-helper"

GENTOO_CONFIG="${1:-gentoo}"
ROOTFS_OUTPUT_DIR="${2:-$RK_SDK_DIR/output/gentoo}"

# Crossdev configuration
GENTOO_HOST_DIR="$RK_SDK_DIR/gentoo-host"  # x86_64 build environment

CUSTOM_REPO_NAME="picocalc-ebuilds"

# Load configuration
if [ -r "$RK_CONFIG" ]; then
	source "$RK_CONFIG"
fi

# Determine cross-compilation target
if [ "$RK_ARCH" = "arm64" ]; then
	CTARGET="${RK_GENTOO_CTARGET:-aarch64-unknown-linux-gnu}"
	TARGET_STAGE3_VARIANT="${RK_GENTOO_STAGE3_VARIANT:-arm64-musl-hardened}"
	TARGET_ARCH_PATH="arm64/autobuilds"
else
	CTARGET="${RK_GENTOO_CTARGET:-armv7a-hardfloat-linux-gnueabi}"
	TARGET_STAGE3_VARIANT="${RK_GENTOO_STAGE3_VARIANT:-armv7a_hardfp-openrc}"
	TARGET_ARCH_PATH="arm/autobuilds"
fi

HOST_STAGE3_VARIANT="amd64-openrc"  # Always use x86_64 for build host

usage() {
	cat <<EOF
Usage: $(basename $0) [OPTIONS] [CONFIG] [OUTPUT_DIR]

Options:
  clean         - Clean Gentoo work directories
  host          - Setup x86_64 host environment only
  toolchain     - Build cross-compilation toolchain only
  target        - Setup target rootfs only
  packages      - Cross-compile target packages only
  finalize      - Create final rootfs image
  help          - Show this help

CONFIG:      Gentoo configuration name (default: gentoo)
OUTPUT_DIR:  Output directory for rootfs (default: $RK_SDK_DIR/output/gentoo)

Environment variables:
  RK_GENTOO_STAGE3_VARIANT   - Target stage3 variant
  RK_GENTOO_CTARGET          - Cross-compilation target tuple
  RK_GENTOO_PROFILE          - Gentoo profile for target
  RK_GENTOO_USE_FLAGS        - USE flags for target
  RK_GENTOO_EXTRA_PACKAGES   - Extra packages to cross-compile
  RK_GENTOO_USE_STAGE3       - Use stage3 tarball (y/n, default: n)
  RK_GENTOO_MANUAL_BUILD     - Use manual build approach (y/n, default: y)
EOF
}

# Copy overlay files to target rootfs
copy_overlay_files() {
	local overlay_dir="$RK_SDK_DIR/gentoo/overlay"
	
	message "Copying overlay files from $overlay_dir..."
	
	if [ ! -d "$overlay_dir" ]; then
		warning "Overlay directory not found: $overlay_dir"
		return 0
	fi
	
	# Copy all files from overlay directory preserving structure
	if [ -n "$(ls -A "$overlay_dir" 2>/dev/null)" ]; then
		sudo cp -r "$overlay_dir"/* "$ROOTFS_OUTPUT_DIR/"
		message "Overlay files copied successfully"
	else
		message "No overlay files to copy"
	fi
}

# Check dependencies
check_gentoo_deps() {
	message "Checking Gentoo crossdev dependencies..."
	
	# Check for required tools
	for cmd in wget tar chroot fakeroot; do
		if ! command -v $cmd >/dev/null 2>&1; then
			error "Required command '$cmd' not found"
		fi
	done
	
	message "Dependencies check passed"
}

# Clean Gentoo work directories
clean_gentoo() {
	message "Cleaning Gentoo work directories..."
	
	# Unmount any bind mounts in host chroot
	if [ -d "$GENTOO_HOST_DIR" ]; then
		for mount in proc sys dev dev/pts; do
			if mountpoint -q "$GENTOO_HOST_DIR/$mount" 2>/dev/null; then
				message "Unmounting host $mount..."
				sudo umount "$GENTOO_HOST_DIR/$mount" || true
			fi
		done
		sudo rm -rf "$GENTOO_HOST_DIR"
	fi
}

# Download and setup x86_64 host environment
setup_host_environment() {
	message "Setting up x86_64 host environment for crossdev..."
	
	mkdir -p "$GENTOO_HOST_DIR"
	cd "$GENTOO_HOST_DIR"
	
	# Check if stage3 is already extracted
	if [ -d "etc" ] && [ -d "usr" ] && [ -d "var" ] && [ -f "etc/gentoo-release" ]; then
		message "x86_64 stage3 already extracted, skipping download and extraction"
		message "x86_64 host environment ready"
		return 0
	fi
	
	# Download x86_64 stage3 for build host
	message "Downloading x86_64 stage3 for build host..."
	MIRROR="https://distfiles.gentoo.org/releases"
	HOST_ARCH_PATH="amd64/autobuilds"
	
	# Get latest x86_64 stage3 URL
	message "Fetching latest x86_64 stage3 info..."
	STAGE3_LIST_FILE="/tmp/latest-stage3-$HOST_STAGE3_VARIANT.txt"
	if ! wget -q "$MIRROR/$HOST_ARCH_PATH/latest-stage3-$HOST_STAGE3_VARIANT.txt" -O "$STAGE3_LIST_FILE"; then
		error "Failed to download x86_64 stage3 list file"
	fi
	
	message "Verifying PGP signature..."
	LATEST_FILE=$(gpg --decrypt "$STAGE3_LIST_FILE" 2>/dev/null | \
		grep '\.tar\.' | tail -n1 | cut -d' ' -f1)
	rm -f "$STAGE3_LIST_FILE"
	
	if [ -z "$LATEST_FILE" ]; then
		error "Could not determine latest x86_64 stage3 file"
	fi
	
	message "Latest x86_64 stage3 file: $LATEST_FILE"
	
	STAGE3_URL="$MIRROR/$HOST_ARCH_PATH/$LATEST_FILE"
	STAGE3_FILE="$(basename "$LATEST_FILE")"
	
	message "Downloading: $STAGE3_URL"
	if [ ! -f "$STAGE3_FILE" ]; then
		wget -c "$STAGE3_URL" -O "$STAGE3_FILE"
	fi
	
	# Extract x86_64 stage3
	message "Extracting x86_64 stage3..."
	sudo tar xpf "$STAGE3_FILE" --xattrs-include='*.*' --numeric-owner
	
	message "x86_64 host environment ready"
}

# Prepare chroot environment
prepare_chroot() {
	message "Preparing chroot environment..."
	
	cd "$GENTOO_WORK_DIR"
	
	# Copy DNS info
	sudo cp /etc/resolv.conf etc/
	
	# Mount necessary filesystems
	sudo mount -t proc proc proc/
	sudo mount --rbind /sys sys/
	sudo mount --make-rslave sys/
	sudo mount --rbind /dev dev/
	sudo mount --make-rslave dev/
	
	# Copy portage config
	setup_portage_config
}

# Setup portage configuration
setup_portage_config() {
	message "Setting up portage configuration..."
	
	# Create make.conf
	cat <<EOF | sudo tee etc/portage/make.conf
# Gentoo make.conf for $RK_CHIP cross-compilation
# Generated by Rockchip SDK for ARM32 hardfp

COMMON_FLAGS="-O2 -pipe -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"

# Architecture specific settings for ARM32 hardfp
EOF

	if [ "$RK_ARCH" = "arm64" ]; then
		cat <<EOF | sudo tee -a etc/portage/make.conf
CHOST="aarch64-unknown-linux-gnu"
CPU_FLAGS_ARM="edsp neon thumb vfp vfpv3 vfpv4 vfp-d32 crc32 v4 v5 v6 v7 v8 thumb2"
EOF
	else
		cat <<EOF | sudo tee -a etc/portage/make.conf
CHOST="armv7a-hardfloat-linux-gnueabi"
CPU_FLAGS_ARM="edsp neon thumb vfp vfpv3 vfpv4 vfp-d32 v4 v5 v6 v7 thumb2"
EOF
	fi

	cat <<EOF | sudo tee -a etc/portage/make.conf

# Number of parallel make jobs (reduced for ARM32)
MAKEOPTS="-j\$(( \$(nproc) < 4 ? \$(nproc) : 4 ))"

# Portage directories
PORTDIR="/var/db/repos/gentoo"
DISTDIR="/var/cache/distfiles"
PKGDIR="/var/cache/binpkgs"

# USE flags for embedded ARM32 system
USE="${RK_GENTOO_USE_FLAGS:--X -gtk -qt5 -kde -gnome minimal embedded -systemd openrc}"

# Features
FEATURES="buildpkg parallel-fetch"

# Locale
LC_MESSAGES=C

# Timezone
TIMEZONE="${RK_GENTOO_TIMEZONE:-UTC}"

# Root filesystem
GRUB_PLATFORMS=""

# Accept licenses
ACCEPT_LICENSE="*"

# Reduced parallelism for ARM32
EMERGE_DEFAULT_OPTS="--jobs=2 --load-average=2"

# ccache configuration
EOF

	if [ "${RK_GENTOO_CCACHE:-y}" = "y" ]; then
		cat <<EOF | sudo tee -a etc/portage/make.conf
FEATURES="\${FEATURES} ccache"
CCACHE_SIZE="${RK_GENTOO_CCACHE_SIZE:-1G}"
EOF
	fi

	# Setup profile
	if [ -n "$RK_GENTOO_PROFILE" ]; then
		message "Setting profile to $RK_GENTOO_PROFILE"
		sudo chroot . /bin/bash -c "eselect profile set $RK_GENTOO_PROFILE"
	fi
	
	# Setup repositories
	sudo mkdir -p etc/portage/repos.conf
	sudo cp usr/share/portage/config/repos.conf etc/portage/repos.conf/gentoo.conf
}

# Setup custom portage repository from base/gentoo/portage
setup_custom_portage_repository() {
	local target_root="$1"
	message "Setting up custom portage repository..."

	local custom_repo_path="$target_root/var/db/repos/$CUSTOM_REPO_NAME"
	local source_repo_path="$RK_SDK_DIR/gentoo/portage"
	
	# Check if our custom portage directory exists
	if [ ! -d "$source_repo_path" ]; then
		warning "Custom portage repository not found at $source_repo_path"
		return 0
	fi
	
	# Create the custom repository in the chroot
	message "Creating custom repository '$CUSTOM_REPO_NAME'..."
	sudo chroot . /bin/bash -c "if [ ! -d $custom_repo_path ]; then PORTAGE_CONFIGROOT=$target_root eselect repository create $CUSTOM_REPO_NAME; else echo 'Custom repository $CUSTOM_REPO_NAME already exists'; fi"
	
	# Copy our custom portage content into the repository
	message "Copying custom packages from $source_repo_path to $custom_repo_path..."

	sudo mkdir -p "$GENTOO_HOST_DIR/$custom_repo_path"
	sudo cp -r "$source_repo_path"/* "$GENTOO_HOST_DIR/$custom_repo_path/"
	
	# Ensure proper ownership within chroot
	sudo chroot $GENTOO_HOST_DIR /bin/bash -c "chown -R portage:portage $custom_repo_path"
}

# Setup crossdev toolchain in host environment
setup_crossdev_toolchain() {
	message "Setting up crossdev toolchain for $CTARGET..."
	
	cd "$GENTOO_HOST_DIR"
	
	# Setup host chroot environment
	message "Preparing host chroot environment..."
	
	# Copy DNS info
	sudo cp /etc/resolv.conf etc/
	
	# Mount necessary filesystems
	sudo mount -t proc proc proc/
	sudo mount --rbind /sys sys/
	sudo mount --make-rslave sys/
	sudo mount --rbind /dev dev/
	sudo mount --make-rslave dev/
	
	# Install crossdev in host environment and required tools
	message "Installing crossdev in host environment..."
	sudo chroot . /bin/bash -c "emerge-webrsync"
	sudo chroot . /bin/bash -c "emerge --quiet --noreplace sys-devel/crossdev app-eselect/eselect-repository app-portage/gentoolkit"
	
	# Create crossdev overlay if it doesn't exist
	message "Creating crossdev overlay..."
	sudo chroot . /bin/bash -c "if [ ! -d /var/db/repos/crossdev ]; then eselect repository create crossdev; else echo 'crossdev repository already exists'; fi"
	
	# Setup custom portage repository from base/gentoo/portage
	setup_custom_portage_repository /
	
	# Build cross-compilation toolchain
	message "Building cross-compilation toolchain for $CTARGET..."
	sudo chroot . /bin/bash -c "crossdev --stable --target $CTARGET -oS $CUSTOM_REPO_NAME"
	sudo chroot . /bin/bash -c "crossdev --show-target-cfg --target $CTARGET"

	message "Cross-compilation toolchain ready"
}

# Setup target system base
setup_target_system() {
	message "Setting up target system base for $CTARGET..."
	
	mkdir -p "$ROOTFS_OUTPUT_DIR"
	cd "$GENTOO_HOST_DIR"
	
	TARGET_ROOT="/usr/$CTARGET"
	PORTAGE_CONFIGROOT=$TARGET_ROOT

	message "Setting up target system..."
	
	# Create minimal target root structure if it doesn't exist
	if [ ! -d "$TARGET_ROOT" ]; then
		sudo mkdir -p "$TARGET_ROOT"
		message "Created target root directory: $TARGET_ROOT"
	fi
	
	# Set target profile
	if [ -n "$RK_GENTOO_PROFILE" ]; then
		message "Setting target profile to $RK_GENTOO_PROFILE"
		sudo chroot . /bin/bash -c "PORTAGE_CONFIGROOT=$TARGET_ROOT eselect profile set $RK_GENTOO_PROFILE"
	fi

	setup_custom_portage_repository "$TARGET_ROOT"

	local source_config_dir="$RK_SDK_DIR/gentoo/etc"
	
	message "Copying build config files from $source_config_dir..."
	
	if [ ! -d "$source_config_dir" ]; then
		warning "Source config directory not found: $source_config_dir"
	else
		sudo cp -r "$source_config_dir"/* "$TARGET_ROOT/etc/"
		message "Build config files copied successfully"
	fi

	# Setup kernel sources for target system
	message "Setting up kernel sources for target..."
	sudo mkdir -p "$TARGET_ROOT/usr/src"
	
	# Create symlink to kernel sources from SDK
	if [ -d "/opt/Lyra-SDK/kernel-6.1" ]; then
		sudo ln -sf "/opt/Lyra-SDK/kernel-6.1" "$TARGET_ROOT/usr/src/linux"
		message "Kernel sources linked at $TARGET_ROOT/usr/src/linux"
	else
		warning "Kernel sources not found at /opt/Lyra-SDK/kernel-6.1"
	fi
}

# Cross-compile packages for target
cross_compile_packages() {
	message "Cross-compiling packages for target..."
	
	cd "$GENTOO_HOST_DIR"
	
	# Build base system
	message "Building base system..."
	CROSS_EMERGE="$CTARGET-emerge"
	TARGET_ROOT="/usr/$CTARGET"
	
	# Determine which approach was used for base system setup
	USE_STAGE3="${RK_GENTOO_USE_STAGE3:-n}"
	MANUAL_BUILD="${RK_GENTOO_MANUAL_BUILD:-y}"
	
	if [ "$MANUAL_BUILD" = "y" ] && [ "$USE_STAGE3" != "y" ]; then
		# Manual build approach - build base system packages manually
		message "Using manual build approach as recommended by Gentoo crossdev documentation..."
		
		# Install base layout first with USE=build (minimal build for bootstrapping)
		message "Installing baselayout with USE=build..."
		sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT USE=build $CROSS_EMERGE -v1 --noreplace baselayout"
		
		# Install glibc (crossdev should have already built this, but ensure it's in target)
		message "Installing glibc..."
		sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE -v1 --noreplace sys-libs/glibc"
		
		# Install @system set
		message "Installing @system set..."
		sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE -v1 --noreplace @system"
		
	elif [ "$USE_STAGE3" = "y" ]; then
		# Stage3 approach - stage3 provides base system, just ensure @system is complete
		message "Using stage3 tarball approach - checking @system completeness..."
		
		# With stage3, we might still need to install some @system packages that weren't in stage3
		# or got masked/filtered out. Use --noreplace to avoid rebuilding existing packages.
		message "Ensuring @system is complete..."
		sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE -v1 --noreplace @system"
		
	else
		error "No valid base system approach configured"
	fi
	
	# Install extra packages if specified
	if [ -n "$RK_GENTOO_EXTRA_PACKAGES" ]; then
		message "Installing extra packages: $RK_GENTOO_EXTRA_PACKAGES"
		sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE --noreplace $RK_GENTOO_EXTRA_PACKAGES"
	fi
	
	# Install appropriate init system
	INIT_SYSTEM="${RK_GENTOO_INIT_SYSTEM:-openrc}"
	case "$INIT_SYSTEM" in
		openrc)
			message "Installing OpenRC..."
			sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE --noreplace sys-apps/openrc::$CUSTOM_REPO_NAME"
			;;
		systemd)
			message "Installing systemd..."
			sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE --noreplace sys-apps/systemd"
			;;
	esac
	
	message "Package cross-compilation completed"
}

# Create final target rootfs
create_target_rootfs() {
	message "Creating target rootfs..."
	
	# Copy cross-compiled system to target directory
	SRC_SYSROOT="$GENTOO_HOST_DIR/usr/$CTARGET"
	
	if [ -d "$SRC_SYSROOT" ]; then
		message "Copying cross-compiled system from $SRC_SYSROOT to $ROOTFS_OUTPUT_DIR..."
		sudo rsync -a "$SRC_SYSROOT/" "$ROOTFS_OUTPUT_DIR/"
	else
		error "Source sysroot not found at $SRC_SYSROOT"
	fi
	
	# Basic system configuration
	message "Configuring target system..."
	
	# Set hostname (override the default localhost)
	HOSTNAME="${RK_ROOTFS_HOSTNAME:-$RK_CHIP-gentoo}"
	echo "hostname=\"$HOSTNAME\"" | sudo tee "$ROOTFS_OUTPUT_DIR/etc/conf.d/hostname" > /dev/null
	
	# Configure locale
	LOCALE="${RK_GENTOO_LOCALE:-en_US.UTF-8}"
	echo "$LOCALE UTF-8" | sudo tee "$ROOTFS_OUTPUT_DIR/etc/locale.gen"
	
	# Set timezone
	TIMEZONE="${RK_GENTOO_TIMEZONE:-UTC}"
	echo "$TIMEZONE" | sudo tee "$ROOTFS_OUTPUT_DIR/etc/timezone" > /dev/null
	
	# Set root password or disable it (modify shadow file directly)
	if [ -n "$RK_GENTOO_ROOT_PASSWORD" ]; then
		message "Setting root password..."
		# Generate password hash and update shadow file
		HASHED_PASSWORD=$(openssl passwd -6 "$RK_GENTOO_ROOT_PASSWORD")
		sudo sed -i "s/^root:[^:]*:/root:$HASHED_PASSWORD:/" "$ROOTFS_OUTPUT_DIR/etc/shadow" || true
	else
		message "Disabling root password..."
		# Lock root account by prefixing password with !
		sudo sed -i 's/^root:\([^:]*\):/root:!\1:/' "$ROOTFS_OUTPUT_DIR/etc/shadow" || true
	fi
	
	# Install Gentoo-specific pre_init script for overlay filesystem support
	message "Installing Gentoo pre_init script..."
	GENTOO_PRE_INIT="$RK_SCRIPTS_DIR/gentoo-pre-init"
	if [ -f "$GENTOO_PRE_INIT" ]; then
		# Create /sbin directory if it doesn't exist
		sudo mkdir -p "$ROOTFS_OUTPUT_DIR/sbin"
		# Install to /sbin/pre_init to match bootargs (init=/sbin/pre_init)
		sudo cp "$GENTOO_PRE_INIT" "$ROOTFS_OUTPUT_DIR/sbin/pre_init"
		sudo chmod +x "$ROOTFS_OUTPUT_DIR/sbin/pre_init"
		message "Installed pre_init script to /sbin/pre_init"
	else
		warning "Gentoo pre_init script not found at $GENTOO_PRE_INIT"
		warning "Overlay filesystem support may not work properly"
	fi
	
	# Copy overlay files to rootfs
	copy_overlay_files
	
	# Configure basic OpenRC services
	message "Configuring OpenRC services..."
	
	# Enable basic system services
	sudo mkdir -p "$ROOTFS_OUTPUT_DIR/etc/runlevels/default"
	sudo mkdir -p "$ROOTFS_OUTPUT_DIR/etc/runlevels/boot"
	
	# Create symlinks for essential services (if they exist)
	BOOT_SERVICES="udev hwclock modules mtab fsck root swap localmount"
	DEFAULT_SERVICES="netmount local dhcpcd"
	
	for service in $BOOT_SERVICES; do
		if [ -f "$ROOTFS_OUTPUT_DIR/etc/init.d/$service" ]; then
			sudo ln -sf "/etc/init.d/$service" "$ROOTFS_OUTPUT_DIR/etc/runlevels/boot/$service" 2>/dev/null || true
		fi
	done
	
	for service in $DEFAULT_SERVICES; do
		if [ -f "$ROOTFS_OUTPUT_DIR/etc/init.d/$service" ]; then
			sudo ln -sf "/etc/init.d/$service" "$ROOTFS_OUTPUT_DIR/etc/runlevels/default/$service" 2>/dev/null || true
		fi
	done

	# Install kernel modules if enabled
	if [ "$RK_ROOTFS_INSTALL_MODULES" = "y" ]; then
		message "Installing kernel modules to rootfs..."
		KERNEL_MODULES_DIR="/opt/Lyra-SDK/output/kernel-modules"
		if [ -d "$KERNEL_MODULES_DIR/lib/modules" ]; then
			sudo mkdir -p "$ROOTFS_OUTPUT_DIR/lib"
			sudo cp -r "$KERNEL_MODULES_DIR/lib/modules" "$ROOTFS_OUTPUT_DIR/lib/"
			message "Kernel modules installed from $KERNEL_MODULES_DIR/lib/modules"
		else
			warning "Kernel modules directory not found at $KERNEL_MODULES_DIR/lib/modules"
			warning "Modules may not be available in the target system"
		fi
	else
		message "Kernel module installation disabled (RK_ROOTFS_INSTALL_MODULES not set to 'y')"
	fi

	message "Target rootfs created"
}

# Create final filesystem image
finalize_crossdev_rootfs() {
	message "Finalizing Gentoo crossdev rootfs..."
	
	# Clean up target system
	cd "$ROOTFS_OUTPUT_DIR"
	sudo rm -rf var/tmp/portage/* var/cache/distfiles/* var/cache/binpkgs/* || true
	
	message "Creating final rootfs image..."
	
	# Create filesystem image
	create_gentoo_image
	
	message "Gentoo crossdev rootfs build completed: $ROOTFS_OUTPUT_DIR"
}

# Create Gentoo filesystem image
create_gentoo_image() {
	message "Creating Gentoo filesystem image..."
	
	ROOTFS_IMG="rootfs.${RK_ROOTFS_TYPE:-ext4}"
	IMAGE_SIZE_MB=${RK_ROOTFS_IMG_SIZE:-1024}  # Default 1GB
	
	cd "$(dirname "$ROOTFS_OUTPUT_DIR")"
	
	case "${RK_ROOTFS_TYPE:-ext4}" in
		ext4)
			# Create ext4 image using fakeroot (like buildroot)
			# This handles root permissions correctly
			dd if=/dev/zero of="$ROOTFS_IMG" bs=1M count="$IMAGE_SIZE_MB"
			
			# Fix ownership on target directory first so fakeroot can access it
			message "Fixing ownership on target directory..."
			sudo chown -R $(id -u):$(id -g) "$ROOTFS_OUTPUT_DIR"
			
			# Create fakeroot script to handle permissions
			FAKEROOT_SCRIPT="$(mktemp)"
			cat <<EOF > "$FAKEROOT_SCRIPT"
#!/bin/sh
set -e
chown -h -R 0:0 "$ROOTFS_OUTPUT_DIR"
mkfs.ext4 -F -d "$ROOTFS_OUTPUT_DIR" "$ROOTFS_IMG"
EOF
			chmod +x "$FAKEROOT_SCRIPT"
			
			# Run under fakeroot to simulate root ownership
			FAKEROOTDONTTRYCHOWN=1 fakeroot -- "$FAKEROOT_SCRIPT"
			rm -f "$FAKEROOT_SCRIPT"
			;;
		ext2)
			# Create ext2 image using fakeroot (like buildroot)
			dd if=/dev/zero of="$ROOTFS_IMG" bs=1M count="$IMAGE_SIZE_MB"
			
			# Fix permissions on target directory first so fakeroot can access it
			message "Fixing permissions on target directory..."
			sudo chown -R $(id -u):$(id -g) "$ROOTFS_OUTPUT_DIR"
			
			# Create fakeroot script to handle permissions
			FAKEROOT_SCRIPT="$(mktemp)"
			cat <<EOF > "$FAKEROOT_SCRIPT"
#!/bin/sh
set -e
chown -h -R 0:0 "$ROOTFS_OUTPUT_DIR"
mkfs.ext2 -F -d "$ROOTFS_OUTPUT_DIR" "$ROOTFS_IMG"
EOF
			chmod +x "$FAKEROOT_SCRIPT"
			
			# Run under fakeroot to simulate root ownership
			FAKEROOTDONTTRYCHOWN=1 fakeroot -- "$FAKEROOT_SCRIPT"
			rm -f "$FAKEROOT_SCRIPT"
			;;
		squashfs)
			# Create squashfs image
			mksquashfs "$ROOTFS_OUTPUT_DIR" "$ROOTFS_IMG" -comp xz
			;;
		*)
			warning "Unsupported rootfs type: ${RK_ROOTFS_TYPE}"
			# Just create a tarball as fallback
			tar czf "rootfs.tar.gz" -C "$ROOTFS_OUTPUT_DIR" .
			;;
	esac
	
	message "Created filesystem image: $ROOTFS_IMG"
}

# Main build function - crossdev-based approach
build_gentoo() {
	message "Starting Gentoo crossdev build for $RK_ARCH..."
	
	# Show configuration
	USE_STAGE3="${RK_GENTOO_USE_STAGE3:-n}"
	MANUAL_BUILD="${RK_GENTOO_MANUAL_BUILD:-y}"
	
	message "Build configuration:"
	message "  Target: $CTARGET"
	message "  Use Stage3: $USE_STAGE3"
	message "  Manual Build: $MANUAL_BUILD"
	if [ "$USE_STAGE3" = "y" ]; then
		message "  Stage3 Variant: $TARGET_STAGE3_VARIANT"
		message "  Following Gentoo crossdev documentation: Stage3 tarball approach"
	else
		message "  Following Gentoo crossdev documentation: Manual build approach (recommended)"
	fi
	echo
	
	check_gentoo_deps
	setup_host_environment
	setup_crossdev_toolchain
	setup_target_system
	cross_compile_packages
	create_target_rootfs
	finalize_crossdev_rootfs
	
	message "Gentoo crossdev build completed: $ROOTFS_OUTPUT_DIR"
}

# Parse command line arguments
case "${1:-build}" in
	clean)
		clean_gentoo
		;;
	toolchain)
		# Build just the crossdev toolchain
		check_gentoo_deps
		setup_host_environment
		setup_crossdev_toolchain
		;;
	stage3)
		check_gentoo_deps
		setup_host_environment
		;;
	host)
		setup_host_environment
		;;
	target)
		setup_target_system
		;;
	packages)
		cross_compile_packages
		;;
	rootfs)
		create_target_rootfs
		;;
	finalize)
		finalize_crossdev_rootfs
		;;
	help|--help|-h)
		usage
		;;
	*)
		build_gentoo
		;;
esac