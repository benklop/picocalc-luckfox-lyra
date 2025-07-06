# Base Package Set for PicoCalc Lyra

This directory contains the base set of custom Buildroot packages for the PicoCalc Lyra project.

## Contents

This package set includes:

- Custom packages required for the PicoCalc Lyra hardware
- Perl packages with cross-compilation fixes
- Terminal and networking utilities

## Usage

This package set is applied by default when using the build system. It can be excluded using the `--no-base-packages` option if you want to build with only custom package sets.

## Structure

The structure mirrors Buildroot's package directory:
- Each subdirectory contains a package definition
- `Config.in` files define package configuration options
- `.mk` files define build instructions
- `.hash` files contain checksums for source files

## Package List

Key packages new in this set:
- `ceni` - Network configuration interface
- `perl-term-readkey` - Perl terminal input handling (with cross-compilation fixes)
- `perl-expect` - Perl expect functionality
- `perl-curses-ui` - Terminal UI framework
- `load-modules` - Kernel module auto-loading infrastructure
- Various utility packages

## Package Modifications

Various modifications to existing Buildroot packages to support the ARM cross-compilation environment.

## Container-Related Fixes

- `host-tar` - Modified to handle running as a pseudo-root user in Docker containers. The default tar package expects certain root privileges that aren't available in containerized environments, so this package includes fixes to allow proper operation when building inside Docker.

## Module Auto-Loading

The `load-modules` package provides infrastructure for automatically loading kernel modules at boot time:

- **S02modules**: Init script that runs early in the boot process to load modules
- **functions**: Boot messaging library with colored output for init scripts
- **modules**: Configuration file listing modules to load (one per line)

### Configuration

The package includes a Buildroot configuration option `BR2_PACKAGE_LOAD_MODULES_LIST` that allows you to specify which modules should be included in the modules file at build time. This can be configured through `make menuconfig` under:

```
Target packages -> PicoCalc -> load-modules -> List of modules to load at boot
```

You can specify a space-separated list of module names (without parameters), for example:
- `rtl8188fu snd-soc-dummy`
- `rtl8188fu snd-soc-dummy i2c-dev`

For modules requiring parameters, leave this configuration empty and manually edit the modules file on the target system.

### Usage

Edit `/etc/sysconfig/modules` on the target system to specify which modules should be loaded at boot. The format is:

```
# Comments start with #
module_name
module_with_args param1=value1 param2=value2
```

Example modules for PicoCalc Lyra:
- `rtl8188fu` - WiFi driver
- `snd-soc-dummy` - Audio driver
- `i2c-dev` - I2C device interface

