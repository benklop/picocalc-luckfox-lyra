# Base Package Set for PicoCalc Lyra

This directory contains the base package set for the PicoCalc Lyra project. It includes:

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

This package set is applied by default when using the build system. To build without it:

```bash
./build.sh --no-base-packages all
```

To build with additional package sets:

```bash
./build.sh --package-set ./my-extra-packages all
```

The base package set will be applied first, followed by any additional package sets in the order specified.
