# Base Overlay for PicoCalc Lyra

This directory contains the base overlay for the PicoCalc Lyra project. It includes:

## Structure

- `buildroot/` - Buildroot modifications including:
  - `package/` - Custom packages and package modifications
  - `board/` - Board-specific configurations and overlays

## Contents

### Custom Packages
- `ceni` - Network configuration utility
- `perl-term-readkey` - Perl module for reading keystrokes (with cross-compilation fixes)

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
