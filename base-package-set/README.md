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
- Various utility packages

## Package Modifications

Various modifications to existing Buildroot packages to support the ARM cross-compilation environment.

## Container-Related Fixes

- `host-tar` - Modified to handle running as a pseudo-root user in Docker containers. The default tar package expects certain root privileges that aren't available in containerized environments, so this package includes fixes to allow proper operation when building inside Docker.

