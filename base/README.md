# Base Overlay for PicoCalc Lyra

This directory contains the base overlay for the PicoCalc Lyra project. It includes:

## Structure

- `buildroot/` - Buildroot modifications including:
  - `package/` - Custom packages and package modifications
  - `board/` - Board-specific configurations and overlays
- `common/` - Common SDK enhancements:
  - `configs/` - Configuration files and options
  - `scripts/` - Build scripts and utilities
  - `patches/` - Patches to apply to SDK files
- `device/` - Device-specific configurations:
  - `rockchip/.chips/rk3506/` - RK3506 device configurations

## Contents

### Custom Packages
- `ceni` - Network configuration utility
- `perl-term-readkey` - Perl module for reading keystrokes (with cross-compilation fixes)

### Gentoo Linux Support
- **Gentoo rootfs**: Alternative to Buildroot/Yocto with full package management
- **ARM32 hardfp optimization**: Optimized for RK3506 ARM32 hardfp architecture
- **Stage3 integration**: Automatic download and cross-compilation from Gentoo stage3
- **Genpatches support**: Automatic kernel patching with Gentoo's patches
- **OpenRC/systemd**: Choice of init systems
- **Embedded optimization**: USE flags and configuration tuned for embedded systems

#### Gentoo Files
- `Config.in.gentoo` - Gentoo configuration options
- `mk-gentoo.sh` - Main Gentoo build script  
- `check-gentoo.sh` - Dependency checker
- `apply-genpatches.sh` - Kernel genpatches integration
- Device configs with Gentoo support
- Kernel configuration fragments for Gentoo

### Package Modifications
Various modifications to existing Buildroot packages to support the ARM cross-compilation environment.

## Usage

This overlay is applied by default when using the build system. To build without it:

```bash
./build.sh --no-base-packages all
```

To build with additional overlays:

```bash
./build.sh --overlay ./my-extra-packages all
```

The base overlay will be applied first, followed by any additional overlays in the order specified.
