# Gentoo Linux Support for Rockchip SDK (Base Overlay)

This guide explains how to use the enhanced Rockchip SDK to build Gentoo Linux images for supported ARM devices using the base overlay system.

## Overview

The Gentoo integration is provided as an overlay in the `base/` folder, which allows:

- Cross-compilation from Gentoo stage3 tarballs
- Automatic genpatches application for better hardware support
- OpenRC or systemd init systems
- Customizable portage configuration
- ARM32 hardfp optimization for RK3506 targets
- Base overlay system for easy distribution and Docker builds

## Supported Devices

Currently supported chip families:
- RK3506 (picocalc-luckfox-lyra) - ARM32 hardfp primary target
- RK3566/RK3568
- RK3588
- RK3576  
- RK3399
- RK3328

## Quick Start

### 1. Prerequisites

Install required packages on your build host:

```bash
# Ubuntu/Debian
sudo apt-get install wget tar chroot mount umount gcc-arm-linux-gnueabihf

# Check available disk space (8GB+ recommended for ARM32)
df -h .
```

### 2. Configure for Gentoo

Use the provided Gentoo device configuration:

```bash
cd SDK
./build.sh lunch

# Select: picocalc_luckfox_lyra_gentoo_sdmmc_dsi_720x720_defconfig
```

Or modify an existing configuration:

```bash
cd SDK  
./build.sh menuconfig

# Navigate to: Rootfs system → Select "Gentoo"
# Configure Gentoo options as needed
```

### 3. Build

Build the complete system:

```bash
./build.sh
```

Or build just the Gentoo rootfs:

```bash
./build.sh gentoo
```

## Base Overlay Structure

The Gentoo support is implemented as a base overlay:

```
base/
├── common/
│   ├── configs/Config.in.gentoo          # Gentoo configuration options
│   ├── scripts/
│   │   ├── mk-gentoo.sh                  # Main Gentoo build script
│   │   ├── check-gentoo.sh               # Dependency checker
│   │   └── apply-genpatches.sh           # Genpatches application
│   └── patches/                          # SDK patches for Gentoo support
└── device/rockchip/.chips/rk3506/
    ├── picocalc_luckfox_lyra_gentoo_*.defconfig  # Gentoo device configs
    └── gentoo-embedded.config             # Kernel config for Gentoo
```

## Configuration Options

### Stage3 Variants

Choose appropriate stage3 variant for your target:
- `armv7a_hardfp-openrc` (recommended for RK3506 ARM32 hardfp)
- `armv7a_hardfp-systemd-mergedusr` (ARM32 with systemd)
- `arm64-musl-hardened` (for ARM64 targets)
- `arm64-systemd-mergedusr` (ARM64 with systemd)

### Gentoo Profile

Select a profile that matches your target:
- `default/linux/arm/17.0/armv7a` (RK3506 ARM32 hardfp)
- `default/linux/arm64/23.0/musl/hardened` (ARM64 embedded-friendly)
- `default/linux/arm64/23.0/systemd` (ARM64 for systemd)

### USE Flags

Default embedded USE flags: `-X -gtk -qt5 -kde -gnome minimal embedded -systemd openrc`

Customize based on your needs:
- Add `wifi` for wireless support
- Add `bluetooth` for Bluetooth support  
- Add specific hardware flags

### Init System

Choose between:
- **OpenRC** (recommended for embedded): Lightweight, faster boot
- **systemd**: More features, better for complex systems

## Manual Build Steps

You can also build step-by-step:

```bash
# 1. Download and prepare stage3
./build.sh gentoo stage3

# 2. Configure the system
./build.sh gentoo configure  

# 3. Install packages
./build.sh gentoo packages

# 4. Build kernel with genpatches
./build.sh kernel

# 5. Finalize rootfs
./build.sh gentoo finalize
```

## Customization

### Adding Packages

Edit your device config or set environment variable:

```bash
export RK_GENTOO_EXTRA_PACKAGES="app-editors/vim net-wireless/wireless-tools sys-process/htop"
./build.sh gentoo
```

### Custom Portage Configuration

Create overlay files in `SDK/gentoo-overlay/` directory:
- `make.conf` - Custom make.conf settings
- `package.use/` - Package-specific USE flags
- `package.accept_keywords/` - Package keyword changes

### Kernel Configuration

The Gentoo build applies a kernel config fragment with embedded-friendly settings. You can customize by:

1. Adding to `RK_KERNEL_CFG_FRAGMENTS` in your device config
2. Creating custom config files in `device/rockchip/.chip/`

## Genpatches Integration

The build automatically downloads and applies Gentoo's genpatches for:
- Better hardware support
- Security fixes
- Bug fixes
- Performance improvements

To disable genpatches:
```bash
export RK_GENTOO_KERNEL_GENPATCHES=n
```

## Troubleshooting

### Build Fails During emerge

Check available disk space and memory. Gentoo compilation is resource-intensive.

Try with fewer parallel jobs:
```bash
export RK_GENTOO_EMERGE_OPTS="--jobs=2 --load-average=2"
```

### Network Issues

If stage3 download fails, try a different mirror:
```bash
export RK_GENTOO_STAGE3_URL="https://mirror.example.com/gentoo/releases/arm64/autobuilds/..."
```

### Cross-compilation Issues

Ensure cross-compiler is installed:
```bash
# For ARM64
sudo apt-get install gcc-aarch64-linux-gnu

# For ARM32  
sudo apt-get install gcc-arm-linux-gnueabihf
```

### Permission Issues

The build requires sudo access for chroot operations. Ensure your user can sudo without password for the build.

## Advanced Usage

### Using distcc

Enable distributed compilation:
```bash
export RK_GENTOO_DISTCC=y
export RK_GENTOO_DISTCC_HOSTS="host1/4 host2/8"
```

### Custom Stage3

Use a custom stage3 tarball:
```bash
export RK_GENTOO_STAGE3_URL="https://example.com/custom-stage3.tar.xz"
```

### ccache Configuration

Adjust ccache size for your build environment:
```bash
export RK_GENTOO_CCACHE_SIZE="4G"
```

## Integration with Existing Workflow

The Gentoo integration follows the same patterns as Buildroot and Yocto:

- Configuration through kconfig system
- Same build commands and scripts
- Compatible with existing device configurations
- Supports all existing SDK features (security, fit images, etc.)

## File Layout

```
SDK/
├── common/configs/Config.in.gentoo      # Gentoo configuration options
├── common/scripts/mk-gentoo.sh          # Main Gentoo build script
├── common/scripts/check-gentoo.sh       # Dependency checker
├── common/scripts/apply-genpatches.sh   # Genpatches application
├── device/rockchip/.chip/
│   ├── gentoo-embedded.config           # Kernel config for Gentoo
│   └── *_gentoo_*_defconfig             # Sample Gentoo device configs
└── gentoo/                              # Gentoo work directory (created during build)
```

## Contributing

When adding support for new devices:

1. Create device-specific defconfig with Gentoo options
2. Test the complete build process
3. Verify the generated image boots and works correctly
4. Document any device-specific requirements or limitations