# PicoCalc Lyra Build System

This repository provides a Docker-based build system for creating custom BuildRoot Linux images for the LuckFox Lyra, specifically tailored to run on the ClockworkPi PicoCalc.

## Prerequisites

- Docker installed on your system
- The LuckFox Lyra SDK tarball (`Luckfox_Lyra_SDK_*.tar.gz`) placed in the root directory

## Quick Start

1. **Download the SDK**: Place the LuckFox Lyra SDK tarball in the root directory of this repository.

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

## What This Build Does

The build system:

1. **Sets up the LuckFox Lyra SDK** in an Ubuntu 22.04 container with all required dependencies
2. **Applies PicoCalc-specific modifications**:
   - Kernel configuration changes for RTC and RTL8188FU WiFi support
   - Device tree updates for the PicoCalc hardware
   - Buildroot configuration for SD card storage
   - RTL8188FU WiFi driver patch
3. **Builds the complete system** using the configured toolchain
4. **Extracts all build artifacts** to the `./output/` directory for easy access

## Manual Docker Usage

If you prefer to run the Docker container manually:

```bash
# Build the Docker image
docker build -t picocalc-lyra-builder .

# Run the container with output volume mount
docker run --rm -v "$(pwd)/output:/opt/output" picocalc-lyra-builder
```

## File Structure

- `Dockerfile` - Docker container definition
- `build.sh` - Main build script (run this)
- `src/` - Source files and configurations:
  - `build.sh` - Internal build script run inside the container
  - `*.config` - Kernel configuration files
  - `*.dts` - Device tree source files
  - `*defconfig` - Buildroot configuration
  - `*.patch` - Patches for the build system
  - `pre-build-picocalc.sh` - Pre-build script for additional customizations

## Build Output

The primary output is `update.img`, which contains the complete system image ready to be flashed to an SD card for use with the PicoCalc. Individual components are also provided for advanced users who need to flash specific partitions.

## Package Sets

The build system supports applying additional package sets to extend functionality:

```bash
# Build with additional packages
./build.sh --package-set ./my-packages all

# Build specific configuration with package set
./build.sh --package-set ./gaming-packages picocalc_luckfox_lyra_buildroot_sdmmc_defconfig
```

### Creating Package Sets

Package sets follow the same directory structure as the base SDK:

```
my-package-set/
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

See `example-package-set/` for a complete example.

## Customization

To customize the build:

1. Modify files in the `src/` directory
2. Update kernel configurations in `src/*.config`
3. Modify device tree in `src/*.dts`
4. Adjust Buildroot packages in `src/*defconfig`
5. Add additional patches or scripts as needed
6. Create package sets for reusable modifications

## Troubleshooting

- Ensure you have the correct LuckFox Lyra SDK tarball in the root directory
- Check that Docker is running and you have sufficient disk space
- Build logs are displayed during the process for debugging

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
