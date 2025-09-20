#!/bin/bash -e

# Check Gentoo build dependencies

RK_SCRIPTS_DIR="${RK_SCRIPTS_DIR:-$(dirname "$(realpath "$0")")}"

# Source common functions
source "$RK_SCRIPTS_DIR/build-helper"

message "Checking Gentoo build environment..."

# Check for required commands
REQUIRED_COMMANDS="wget tar chroot mount umount"
MISSING_COMMANDS=""

for cmd in $REQUIRED_COMMANDS; do
	if ! command -v $cmd >/dev/null 2>&1; then
		MISSING_COMMANDS="$MISSING_COMMANDS $cmd"
	fi
done

if [ -n "$MISSING_COMMANDS" ]; then
	error "Missing required commands:$MISSING_COMMANDS"
fi

# Check for sudo access
if ! sudo -n true 2>/dev/null; then
	warning "sudo access required for Gentoo build (chroot operations)"
fi

# Check available disk space (need at least 8GB for ARM32)
WORK_DIR="${RK_SDK_DIR:-$(pwd)}/gentoo"
PARENT_DIR="$(dirname "$WORK_DIR")"
AVAILABLE_SPACE=$(df "$PARENT_DIR" | awk 'NR==2 {print $4}')
REQUIRED_SPACE=$((8 * 1024 * 1024)) # 8GB in KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
	warning "Low disk space: $(($AVAILABLE_SPACE / 1024 / 1024))GB available, 8GB+ recommended for ARM32"
fi

# Check for cross-compilation toolchain
if [ -n "$RK_ARCH" ]; then
	if [ "$RK_ARCH" = "arm64" ]; then
		CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
	else
		CROSS_COMPILE="${CROSS_COMPILE:-arm-linux-gnueabihf-}"
	fi
	
	if ! command -v "${CROSS_COMPILE}gcc" >/dev/null 2>&1; then
		warning "Cross-compiler ${CROSS_COMPILE}gcc not found"
		message "Install with: sudo apt-get install gcc-$(echo $CROSS_COMPILE | sed 's/-$//')"
	else
		message "Cross-compiler found: ${CROSS_COMPILE}gcc"
	fi
fi

# Check network connectivity to Gentoo mirrors
if ! wget -q --spider https://distfiles.gentoo.org/ 2>/dev/null; then
	warning "Cannot reach Gentoo mirrors - check network connectivity"
fi

# Check for tools needed for filesystem creation
for tool in mkfs.ext4 mkfs.ext2 mksquashfs; do
	if ! command -v $tool >/dev/null 2>&1; then
		warning "Filesystem tool $tool not found - some rootfs types may not work"
	fi
done

message "Gentoo build environment check completed"