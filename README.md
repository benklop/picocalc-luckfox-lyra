# PicoCalc Lyra Build System

This repository provides a Docker-based build system for creating custom BuildRoot Linux images for the LuckFox Lyra, specifically tailored to run on the ClockworkPi PicoCalc.

## ⚠️ Work in Progress

**Known Issues / Not Yet Working:**
- **Stereo hardware PWM audio** - Audio output is not yet functional
- **WiFi with RTL8188FU chip** - WiFi driver integration is in progress but not working

These features are actively being developed. Contributions and testing are welcome!

## Prerequisites

- Docker installed on your system
- Python3 and pip to download the SDK

## Quick Start

1. **Build the Container**: Run the setup script:
   ```
   ./setup.sh
   ```

2. **Run the build**: Execute the build script:
   ```bash
   ./build.sh
   ```

3. **Get the results**: After the build completes, your images will be available in the `./output/` directory:
   - `update.img` - Complete system image (main file to flash)
   - `boot.img` - Kernel image
   - `rootfs.img` - Root filesystem image
   - `uboot.img` - U-Boot bootloader
   - `MiniLoaderAll.bin` - SPL bootloader
   - `parameter.txt` - Partition table information

4. **Flash to hardware**: Deploy the firmware to your PicoCalc LuckFox Lyra:
   ```bash
   ./flash.sh
   ```
   Follow the prompts to flash `update.img` to your device. See [FLASHING.md](FLASHING.md) for detailed instructions.

## What This Build Does

The build system:

1. **Sets up the LuckFox Lyra SDK** in an Ubuntu 22.04 container with all required dependencies
2. **Applies PicoCalc-specific modifications**:
   - Kernel configuration changes for RTC and RTL8188FU WiFi support
   - Device tree updates for the PicoCalc hardware
   - Buildroot configuration for SD card storage
   - RTL8188FU WiFi driver patch
   - Custom package configurations
3. **Builds the complete system** using the configured toolchain
4. **Extracts all build artifacts** to the `./output/` directory for easy access
5. **Provides flashing tools** for easy deployment to hardware

## Manual Docker Usage

If you prefer to run the Docker container manually:

```bash
# Build the Docker image
docker build -t picocalc-lyra-builder .

# Run the container with output volume mount
docker run --rm -v "$(pwd)/config:/opt/Lyra-SDK/buildroot/configs:Z" -v "$(pwd)/output:/opt/Lyra-SDK/output:Z" picocalc-lyra-builder --help
```

## File Structure

- `Dockerfile` - Docker container definition
- `build.sh` - Main build script (run this)
- `flash.sh` - Firmware flashing script with safety checks
- `setup_usb.sh` - Convenience wrapper for USB permissions setup
- `FLASHING.md` - Comprehensive flashing documentation
- `scripts/` - Build and flashing scripts:
  - `rkflash.sh` - Low-level Rockchip flashing tool
  - `setup_usb_permissions.sh` - USB permissions setup script
  - `99-rockchip.rules` - udev rules for USB device access
- `base/` - Source files and configurations:
  - `build.sh` - Internal build script run inside the container
  - `*.config` - Kernel configuration files
  - `*.dts` - Device tree source files
  - `*defconfig` - Buildroot configuration
  - `*.patch` - Patches for the build system
  - `pre-build-picocalc.sh` - Pre-build script for additional customizations

## Build Output

The primary output is `update.img`, which contains the complete system image ready to be flashed to an SD card for use with the PicoCalc. Individual components are also provided for advanced users who need to flash specific partitions.

## Flashing

Once the build is complete, you can flash the firmware to your PicoCalc LuckFox Lyra:

```bash
# Quick flash (recommended)
./flash.sh

# Set up USB permissions for non-root flashing
./scripts/setup_usb_permissions.sh
```

For detailed flashing instructions, troubleshooting, and hardware setup, see **[FLASHING.md](FLASHING.md)**.

**Quick Flashing Steps:**
1. Insert SD card into the PicoCalc
2. Boot to Linux and run `reboot loader` (or use hardware boot button)
3. Connect USB-C cable to the **LOWER** USB-C port
4. Run `./flash.sh` and follow the prompts

## Overlays

The build system supports applying additional overlays to extend functionality:

```bash
# Build with additional packages
./build.sh --overlay ./my-packages all

# Build specific configuration with overlay
./build.sh --overlay ./gaming-packages picocalc_luckfox_lyra_buildroot_sdmmc_defconfig
```

### Creating Overlays

Overlays follow the same directory structure as the base SDK:

```
my-overlay/
├── buildroot/
│   └── package/
│       ├── my-package/
│       │   ├── Config.in
│       │   └── my-package.mk
│       └── Config.in.patch      # Adds package to Buildroot menu
├── kernel-6.1/
│   └── drivers/my-driver/       # Custom kernel modules
└── README.md
```

**File Types:**
- Regular files: Copied directly to the SDK
- `.patch` files: Applied as patches to existing SDK files

See `example-overlay/` for a complete example.

## Customization

To customize the build:

1. Modify files in the `src/` directory
2. Update kernel configurations in `src/*.config`
3. Modify device tree in `src/*.dts`
4. Adjust Buildroot packages in `src/*defconfig`
5. Add additional patches or scripts as needed
6. Create overlays for reusable modifications

## Development and Debugging

The build system provides several useful commands for development and debugging. All commands are available through `./build.sh`:

### Available Commands

Run `./build.sh --help` to see all available options. Key development commands include:

```bash
# Standard build commands
./build.sh all                    # Build complete system
./build.sh buildroot              # Build only BuildRoot components
./build.sh kernel                 # Build only kernel

# Development and debugging commands
./build.sh buildroot-shell        # Open shell in BuildRoot environment
./build.sh shell                  # Open general development shell
./build.sh buildroot-config       # Modify BuildRoot configuration interactively
./build.sh kernel-config          # Modify kernel configuration interactively
```

### BuildRoot Package Development

For working with individual packages (especially useful when developing patches):

```bash
# Clean and rebuild a specific package
./build.sh buildroot-make:<package>-dirclean
./build.sh buildroot-make:<package>

# Example: Working with the RTL8188FU driver
./build.sh buildroot-make:rtl8188fu-dirclean  # Clean package completely
./build.sh buildroot-make:rtl8188fu           # Rebuild package
```

### Interactive Development Shell

The `buildroot-shell` command is particularly useful for development:

```bash
./build.sh buildroot-shell
```

This opens an interactive shell inside the BuildRoot environment where you can:

- **Examine the build environment**: Explore the buildroot
- **Debug package builds**: Check extracted source code and build logs
- **Test manual compilation**: Try compilation steps manually
- **Inspect configurations**: Review BuildRoot and kernel configurations

### BuildRoot Make Commands

Inside the BuildRoot environment (or via `buildroot-make:`), you have access to all standard BuildRoot make targets:

```bash
# Package-specific commands
make <package>-extract     # Extract package source
make <package>-patch       # Apply patches to package
make <package>-configure   # Configure package
make <package>-build       # Build package
make <package>-install     # Install package to staging
make <package>-dirclean    # Clean package completely
make <package>-rebuild     # Clean and rebuild package

# Configuration commands
make menuconfig           # Interactive BuildRoot configuration
make savedefconfig        # Save current config as defconfig

# Cleanup commands
make clean                # Clean build artifacts
make distclean           # Complete cleanup including downloads
```

### Package Development Workflow

When developing or debugging packages (like fixing patches):

1. **Clean the package**: `./build.sh buildroot-make:rtl8188fu-dirclean`
2. **Open development shell**: `./build.sh buildroot-shell`
3. **Extract and examine**: `make rtl8188fu-extract && cd build/rtl8188fu-*/`
4. **Apply patches manually**: `make rtl8188fu-patch` (or apply manually to debug)
5. **Test compilation**: `make rtl8188fu-build`
6. **Exit and rebuild**: `exit` then `./build.sh buildroot-make:rtl8188fu`

### Patch Development Tips

- Use `buildroot-shell` to examine extracted source code structure
- Test patches manually before adding them to the package
- Use `dirclean` to ensure clean rebuilds when testing patches
- Check BuildRoot manual for advanced package development: https://buildroot.org/downloads/manual/manual.html#pkg-build-steps

## Troubleshooting

- Ensure you have the correct LuckFox Lyra SDK tarball in the root directory
- Check that Docker is running and you have sufficient disk space
- Build logs are displayed during the process for debugging
- For flashing issues, see [FLASHING.md](FLASHING.md) troubleshooting section
- Set up USB permissions for non-root flashing: `./scripts/setup_usb_permissions.sh`

## Automated Releases

This project includes automated firmware builds using GitHub Actions. When you create a new release tag:

1. **Tag a release**: Create and push a version tag (e.g., `v1.0.0`)
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Automatic build**: GitHub Actions will automatically:
   - Build the Docker container
   - Run `./setup.sh` to configure the build environment
   - Run `./build.sh all` to build the complete firmware
   - Package all firmware files (`update.img`, `boot.img`, etc.)
   - Create a GitHub release with downloadable firmware files

3. **Download firmware**: Users can download the built firmware directly from the GitHub releases page

The automated builds ensure consistent, reproducible firmware builds and make it easy for users to get the latest firmware without needing to set up the build environment themselves.

## Credits

Based on the work from:
- [PicoCalc-uf2 project](https://github.com/cjstoddard/PicoCalc-uf2)
- [picocalc-luckfox-lyra](https://github.com/nekocharm/picocalc-luckfox-lyra)
- [picocalc_luckfox_lyra](https://github.com/hisptoot/picocalc_luckfox_lyra)
- LuckFox Technology for the Lyra SDK
