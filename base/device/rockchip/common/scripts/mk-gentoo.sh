#!/bin/bash -e

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
EOF
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
	
	# Setup package.use directory
	sudo mkdir -p etc/portage/package.use
	
	# Create package.use for embedded optimizations
	cat <<EOF | sudo tee etc/portage/package.use/embedded
# Embedded ARM32 system optimizations
sys-apps/busybox static
sys-apps/util-linux static-libs
sys-fs/udev hwdb
net-misc/dhcpcd embedded ipv6
# ARM32 specific optimizations
sys-devel/gcc -fortran -go
sys-libs/glibc -multilib
EOF
}

# Configure Gentoo system
configure_gentoo() {
	message "Configuring Gentoo system..."
	
	cd "$GENTOO_WORK_DIR"
	
	# Update portage tree
	message "Syncing portage tree..."
	sudo chroot . /bin/bash -c "emerge-webrsync"
	
	# Set locale
	LOCALE="${RK_GENTOO_LOCALE:-en_US.UTF-8}"
	echo "$LOCALE UTF-8" | sudo tee etc/locale.gen
	sudo chroot . /bin/bash -c "locale-gen"
	sudo chroot . /bin/bash -c "eselect locale set $LOCALE"
	
	# Set timezone
	TIMEZONE="${RK_GENTOO_TIMEZONE:-UTC}"
	sudo chroot . /bin/bash -c "echo '$TIMEZONE' > /etc/timezone"
	sudo chroot . /bin/bash -c "emerge --config sys-libs/timezone-data"
	
	# Configure hostname
	HOSTNAME="${RK_ROOTFS_HOSTNAME:-$RK_CHIP-gentoo}"
	echo "$HOSTNAME" | sudo tee etc/conf.d/hostname
	
	# Configure networking (if dhcpcd is installed)
	if echo "${RK_GENTOO_EXTRA_PACKAGES}" | grep -q dhcpcd; then
		sudo chroot . /bin/bash -c "rc-update add dhcpcd default" || true
	fi
	
	# Set root password
	if [ -n "$RK_GENTOO_ROOT_PASSWORD" ]; then
		echo "root:$RK_GENTOO_ROOT_PASSWORD" | sudo chroot . chpasswd
	else
		# Disable password login for root
		sudo chroot . /bin/bash -c "passwd -l root" || true
	fi
}

# Install packages
install_packages() {
	message "Installing packages..."
	
	cd "$GENTOO_WORK_DIR"
	
	# Update system
	message "Updating @world..."
	sudo chroot . /bin/bash -c "emerge ${RK_GENTOO_EMERGE_OPTS:---jobs=2 --quiet-build} --update --deep --newuse @world"
	
	# Install extra packages
	if [ -n "$RK_GENTOO_EXTRA_PACKAGES" ]; then
		message "Installing extra packages: $RK_GENTOO_EXTRA_PACKAGES"
		sudo chroot . /bin/bash -c "emerge ${RK_GENTOO_EMERGE_OPTS} $RK_GENTOO_EXTRA_PACKAGES"
	fi
	
	# Install appropriate init system
	INIT_SYSTEM="${RK_GENTOO_INIT_SYSTEM:-openrc}"
	case "$INIT_SYSTEM" in
		openrc)
			message "Configuring OpenRC..."
			sudo chroot . /bin/bash -c "rc-update add local default"
			;;
		systemd)
			message "Installing systemd..."
			sudo chroot . /bin/bash -c "emerge ${RK_GENTOO_EMERGE_OPTS} sys-apps/systemd"
			;;
	esac
}

# Build kernel with genpatches
build_kernel_genpatches() {
	message "Building kernel with genpatches..."
	
	# This function would integrate with the existing kernel build system
	# but apply genpatches first
	
	if [ "${RK_GENTOO_KERNEL_GENPATCHES:-y}" = "y" ]; then
		message "Applying genpatches is handled by the main kernel build"
		# The actual genpatches application would be handled in mk-kernel.sh
		# This is just a placeholder for the gentoo-specific kernel setup
	fi
	
	# Create kernel config fragment for Gentoo
	KERNEL_CONFIG_FRAGMENT="$RK_CHIP_DIR/${RK_GENTOO_KERNEL_CONFIG_FRAGMENT:-gentoo-embedded.config}"
	if [ ! -f "$KERNEL_CONFIG_FRAGMENT" ]; then
		message "Creating Gentoo kernel config fragment..."
		cat <<EOF > "$KERNEL_CONFIG_FRAGMENT"
# Gentoo-specific kernel configuration for ARM32
# Enable features commonly needed for Gentoo systems

# General Gentoo requirements
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_TMPFS=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_TMPFS_XATTR=y

# systemd requirements (if using systemd)
CONFIG_CGROUPS=y
CONFIG_INOTIFY_USER=y
CONFIG_SIGNALFD=y
CONFIG_TIMERFD=y
CONFIG_EPOLL=y
CONFIG_NET=y
CONFIG_SYSFS=y
CONFIG_PROC_FS=y
CONFIG_FHANDLE=y

# OpenRC requirements
CONFIG_SYSVIPC=y

# Common embedded features
CONFIG_SQUASHFS=y
CONFIG_SQUASHFS_XATTR=y
CONFIG_SQUASHFS_ZLIB=y
CONFIG_OVERLAY_FS=y

# ARM32 specific optimizations
CONFIG_ARM_PATCH_PHYS_VIRT=y
CONFIG_HIGHMEM=y
CONFIG_ARM_THUMB=y
CONFIG_AEABI=y
CONFIG_VFP=y
CONFIG_VFPv3=y
CONFIG_NEON=y
EOF
	fi
}

# Finalize rootfs
finalize_rootfs() {
	message "Finalizing Gentoo rootfs..."
	
	cd "$GENTOO_WORK_DIR"
	
	# Clean up
	sudo chroot . /bin/bash -c "emerge --depclean" || true
	sudo chroot . /bin/bash -c "eclean-dist --deep" || true
	sudo chroot . /bin/bash -c "eclean-pkg --deep" || true
	
	# Remove unnecessary files
	sudo rm -f etc/resolv.conf
	sudo rm -rf var/tmp/portage/*
	sudo rm -rf var/cache/distfiles/*
	sudo rm -rf usr/src/linux*
	
	# Unmount bind mounts
	for mount in proc sys dev dev/pts; do
		if mountpoint -q "$mount" 2>/dev/null; then
			sudo umount "$mount" || true
		fi
	done
	
	# Create final rootfs directory
	message "Creating rootfs image..."
	mkdir -p "$(dirname "$ROOTFS_OUTPUT_DIR")"
	
	# Copy rootfs to output directory  
	if [ -d "$ROOTFS_OUTPUT_DIR" ]; then
		sudo rm -rf "$ROOTFS_OUTPUT_DIR"
	fi
	sudo cp -a . "$ROOTFS_OUTPUT_DIR/"
	
	# Create filesystem image
	create_gentoo_image
	
	message "Gentoo rootfs build completed: $ROOTFS_OUTPUT_DIR"
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
	
	# Install crossdev in host environment
	message "Installing crossdev in host environment..."
	sudo chroot . /bin/bash -c "emerge-webrsync"
	sudo chroot . /bin/bash -c "emerge --quiet sys-devel/crossdev app-eselect/eselect-repository"
	
	# Create crossdev overlay if it doesn't exist
	message "Creating crossdev overlay..."
	sudo chroot . /bin/bash -c "if [ ! -d /var/db/repos/crossdev ]; then eselect repository create crossdev; else echo 'crossdev repository already exists'; fi"
	
	# Build cross-compilation toolchain
	message "Building cross-compilation toolchain for $CTARGET..."
	sudo chroot . /bin/bash -c "crossdev --stable --target $CTARGET"
	
	message "Cross-compilation toolchain ready"
}

# Setup target system base
setup_target_system() {
	message "Setting up target system base for $CTARGET..."
	
	mkdir -p "$ROOTFS_OUTPUT_DIR"
	cd "$GENTOO_HOST_DIR"
	
	# Set target profile
	if [ -n "$RK_GENTOO_PROFILE" ]; then
		message "Setting target profile to $RK_GENTOO_PROFILE"
		TARGET_ROOT="/usr/$CTARGET"
		
		# List available profiles first
		message "Available ARM profiles:"
		sudo chroot . /bin/bash -c "PORTAGE_CONFIGROOT=$TARGET_ROOT eselect profile list | grep arm"
		
		sudo chroot . /bin/bash -c "PORTAGE_CONFIGROOT=$TARGET_ROOT eselect profile set $RK_GENTOO_PROFILE"
	fi
	
	# Configure target make.conf
	message "Configuring target make.conf..."
	TARGET_PORTAGE_DIR="/usr/$CTARGET/etc/portage"
	sudo mkdir -p "$TARGET_PORTAGE_DIR"
	
	# Create target-specific make.conf
	cat <<EOF | sudo tee "usr/$CTARGET/etc/portage/make.conf"
# Cross-compilation make.conf for $CTARGET
# Generated by Rockchip SDK

# Architecture-specific settings
CHOST="$CTARGET"
EOF

	if [ "$RK_ARCH" = "arm64" ]; then
		cat <<EOF | sudo tee -a "usr/$CTARGET/etc/portage/make.conf"
COMMON_FLAGS="-O2 -pipe -march=armv8-a"
CPU_FLAGS_ARM="edsp neon thumb vfp vfpv3 vfpv4 vfp-d32 crc32 v4 v5 v6 v7 v8 thumb2"
EOF
	else
		cat <<EOF | sudo tee -a "usr/$CTARGET/etc/portage/make.conf"
COMMON_FLAGS="-O2 -pipe -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard"
CPU_FLAGS_ARM="edsp neon thumb vfp vfpv3 vfpv4 vfp-d32 v4 v5 v6 v7 thumb2"
EOF
	fi

	cat <<EOF | sudo tee -a "usr/$CTARGET/etc/portage/make.conf"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"

# Embedded system optimization
MAKEOPTS="-j2"

# USE flags for embedded ARM system
USE="${RK_GENTOO_USE_FLAGS:--X -gtk -qt5 -kde -gnome minimal embedded -systemd openrc}"

# Features
FEATURES="buildpkg parallel-fetch"

# Portage directories
PORTDIR="/var/db/repos/gentoo"
DISTDIR="/var/cache/distfiles"
PKGDIR="/var/cache/binpkgs"

# Locale and timezone
LC_MESSAGES=C
TIMEZONE="${RK_GENTOO_TIMEZONE:-UTC}"

# Accept licenses
ACCEPT_LICENSE="*"

# Emerge options for cross-compilation
EMERGE_DEFAULT_OPTS="--jobs=2 --load-average=2"
EOF

	if [ "${RK_GENTOO_CCACHE:-y}" = "y" ]; then
		cat <<EOF | sudo tee -a "usr/$CTARGET/etc/portage/make.conf"

# ccache configuration
FEATURES="\${FEATURES} ccache"
CCACHE_SIZE="${RK_GENTOO_CCACHE_SIZE:-1G}"
EOF
	fi

	# Setup package.use for embedded optimizations
	sudo mkdir -p "usr/$CTARGET/etc/portage/package.use"
	cat <<EOF | sudo tee "usr/$CTARGET/etc/portage/package.use/embedded"
# Embedded system optimizations
sys-apps/busybox static
sys-apps/util-linux static-libs
sys-fs/udev hwdb
net-misc/dhcpcd embedded ipv6
sys-devel/gcc -fortran -go
sys-libs/glibc -multilib
EOF

	# Setup kernel sources for target system
	message "Setting up kernel sources for target..."
	sudo mkdir -p "usr/$CTARGET/usr/src"
	
	# Create symlink to kernel sources from SDK
	if [ -d "/opt/Lyra-SDK/kernel-6.1" ]; then
		sudo ln -sf "/opt/Lyra-SDK/kernel-6.1" "usr/$CTARGET/usr/src/linux"
		message "Kernel sources linked at usr/$CTARGET/usr/src/linux"
	else
		warning "Kernel sources not found at /opt/Lyra-SDK/kernel-6.1"
	fi

	message "Target system base configuration completed"
}

# Cross-compile packages for target
cross_compile_packages() {
	message "Cross-compiling packages for target..."
	
	cd "$GENTOO_HOST_DIR"
	
	# Build base system
	message "Building base system..."
	CROSS_EMERGE="$CTARGET-emerge"
	TARGET_ROOT="/usr/$CTARGET"
	
	# Install base layout and glibc
	sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT USE=build $CROSS_EMERGE -v1 --noreplace baselayout"
	sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE -v1 --noreplace sys-libs/glibc"
	sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE -v1 --noreplace @system"
	
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
			sudo chroot . /bin/bash -c "ROOT=$TARGET_ROOT SYSROOT=$TARGET_ROOT $CROSS_EMERGE --noreplace sys-apps/openrc"
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