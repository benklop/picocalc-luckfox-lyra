# Flashing the PicoCalc LuckFox Lyra

This document provides comprehensive instructions for flashing custom firmware to the PicoCalc LuckFox Lyra device.

## Overview

The PicoCalc LuckFox Lyra uses Rockchip RK3506 SoC and can be flashed via USB using Rockchip's flashing tools. The device supports flashing to both internal storage and SD card.

## Prerequisites

### Hardware Requirements
- PicoCalc LuckFox Lyra device
- USB-C cable
- MicroSD card (Class 10 or better recommended)
- Computer running Linux

### Software Requirements
- Built firmware (see [README.md](README.md) for build instructions)
- USB access (automated setup available, see [USB Permissions Setup](#usb-permissions-setup))

## Understanding the Hardware

### USB Ports
The PicoCalc (with LuckFox Lyra installed) features **two** USB-C ports:
- **UPPER PORT**: Used for serial communication through the MCU and for charging the device
- **LOWER PORT**: LuckFox Lyra (RK3506) - **USE THIS FOR FLASHING**

⚠️ **CRITICAL**: Always use the **LOWER** USB-C port for flashing the Lyra!

### Boot Button Location
- Located on the LuckFox Lyra board inside the device
- Requires removing the back cover to access
- Used for manual entry into loader mode

## USB Permissions Setup

For the best experience, set up USB permissions to allow flashing without sudo:

### Automatic Setup (Recommended)

Run the provided setup script:

```bash
./scripts/setup_usb_permissions.sh
```

This script will:
- Install the necessary udev rules
- Add your user to the `plugdev` group  
- Allow flashing without sudo privileges

After running the script, **log out and log back in** for the changes to take effect.

### Manual Setup

If you prefer to set up permissions manually:

```bash
# Install udev rule
sudo cp scripts/99-rockchip.rules /etc/udev/rules.d/

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Add user to plugdev group
sudo usermod -a -G plugdev $USER

# Log out and back in for changes to take effect
```

### Verification

To verify the setup is working:

```bash
# Check if your user is in the plugdev group
groups

# With device connected in loader mode, check detection
lsusb | grep Rockchip

# The device should show as: Bus XXX Device XXX: ID 2207:350f Fuzhou Rockchip Electronics Company
```

## Flashing Methods

### Method 1: Using the Flash Script (Recommended)

The provided `flash.sh` script automates the flashing process with proper safety checks.

```bash
# Flash the update image (default)
./flash.sh

# Flash specific image type
./flash.sh update
./flash.sh recovery
./flash.sh firmware
```

The script will:
1. Check prerequisites and USB permissions
2. Offer to set up USB permissions if needed
3. Display detailed instructions
4. Confirm the operation
5. Execute the flash process

### Method 2: Manual Flashing

For advanced users or troubleshooting:

```bash
# Flash update image manually
./scripts/rkflash.sh update

# Flash other image types
./scripts/rkflash.sh recovery
./scripts/rkflash.sh firmware
```

## Entering Loader Mode

The device must be in "loader mode" to accept firmware updates. There are two methods:

### Method A: Software Reboot (Preferred)

If the device is running Linux:

1. Boot the PicoCalc normally
2. Access the Linux shell (SSH, serial console, or direct access)
3. Run the command: `reboot loader`
4. The device will reboot into loader mode
5. Connect USB-C cable to the **LOWER** port

### Method B: Hardware Boot Button

If software access is unavailable:

1. Power off the PicoCalc
2. Remove the back cover to access the LuckFox Lyra board
3. Locate the BOOT button on the board
4. Hold the BOOT button down
5. While holding the button, connect USB-C cable to the **LOWER** port
6. Keep holding the button for 2-3 seconds after connection
7. Release the button - device should be in loader mode

## Step-by-Step Flashing Process

### 1. Prepare the Hardware

1. **Insert SD Card**: Place a microSD card into the SD card slot on the LuckFox Lyra
   - The SD card will receive the flashed firmware
   - Minimum 1GB recommended, 8GB+ for development

2. **Prepare USB Connection**: Have USB-C cable ready but don't connect yet

### 2. Build the Firmware

Ensure you have built the firmware first:

```bash
# Build the complete firmware
./build.sh

# Verify the update image exists
ls -la output/firmware/update.img
```

### 3. Enter Loader Mode

Choose one of the methods described above to put the device in loader mode.

### 4. Connect USB

1. Connect USB-C cable to the **LOWER** USB-C port on the PicoCalc
2. Connect the other end to your computer
3. Verify detection: `lsusb | grep Rockchip` should show the device

### 5. Execute Flash

Run the flash script:

```bash
./flash.sh
```

Follow the on-screen prompts and confirm when ready.

### 6. Complete the Process

1. Wait for flashing to complete (typically 2-5 minutes)
2. Disconnect USB cable
3. Power cycle the PicoCalc
4. The device should boot with the new firmware

## Troubleshooting

### Device Not Detected

**Symptoms**: `lsusb` doesn't show Rockchip device

**Solutions**:
- Verify using the **LOWER** USB-C port
- Try different USB cable
- Ensure device is properly in loader mode
- Check USB permissions: `sudo ./flash.sh`
- Try different USB port on computer

### Flash Process Fails

**Symptoms**: Flash process starts but fails during transfer

**Solutions**:
- Check SD card is properly inserted
- Verify SD card is not write-protected
- Try a different SD card
- Ensure stable USB connection
- Close other applications that might access USB devices

### Permission Errors

**Symptoms**: "Permission denied" errors during flashing

**Solutions**:
- **Recommended**: Run USB permissions setup: `./scripts/setup_usb_permissions.sh`
- **Alternative**: Run with sudo: `sudo ./flash.sh`
- **Manual**: Add user to dialout group: `sudo usermod -a -G dialout $USER`

### Device Won't Boot After Flash

**Symptoms**: Device doesn't boot or shows no display

**Solutions**:
- Verify SD card is properly seated
- Try reflashing with a known-good image
- Check if device enters loader mode (may need recovery)
- Ensure correct firmware was flashed for your hardware revision

## Advanced USB Permissions Setup

The automatic setup script handles most cases, but for advanced users or troubleshooting:

### Manual udev Rule Installation

```bash
# Create udev rule file manually
sudo tee /etc/udev/rules.d/99-rockchip.rules << 'EOF'
# Rockchip RK3506 in loader mode (for flashing)
SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="350f", MODE="0666", GROUP="plugdev", TAG+="uaccess"

# Rockchip RK3506 in maskrom mode (for low-level recovery)
SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="350a", MODE="0666", GROUP="plugdev", TAG+="uaccess"

# Additional Rockchip product IDs that might be used
SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="350*", MODE="0666", GROUP="plugdev", TAG+="uaccess"
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Add user to plugdev group  
sudo usermod -a -G plugdev $USER

# Log out and back in for group changes to take effect
```

### Troubleshooting USB Permissions

```bash
# Check if udev rule is installed
ls -la /etc/udev/rules.d/99-rockchip.rules

# Check group membership
groups

# Check if device is detected
lsusb | grep 2207:350f

# Check device permissions (with device connected)
find /dev/bus/usb -name "*" | xargs ls -la | grep "2207:350f"
```

## Image Types

### Update Image (`update`)
- **File**: `output/firmware/update.img`
- **Description**: Complete firmware package including bootloader, kernel, and rootfs
- **Use Case**: Normal firmware updates, complete system replacement
- **Flash Target**: SD card

### Recovery Image (`recovery`)
- **File**: `output/firmware/recovery.img` (if built)
- **Description**: Minimal recovery system for emergencies
- **Use Case**: Recovery from bad firmware, system rescue
- **Flash Target**: Internal storage recovery partition

### Firmware Only (`firmware`)
- **File**: Individual partition images
- **Description**: Flash specific partitions only
- **Use Case**: Development, partial updates
- **Flash Target**: Specific partitions

## Advanced Topics

### Serial Console Access

For debugging boot issues, connect a serial console:
- **Pins**: Located on LuckFox Lyra board
- **Settings**: 115200 8N1
- **Use**: Monitor boot process, access console if display fails

### Partition Layout

The firmware uses the following partition layout (from `parameter.txt`):
- **uboot**: U-Boot bootloader (4MB @ 0x2000)
- **boot**: Kernel and device tree (12MB @ 0x4000)  
- **amp**: AMP/MCU firmware (2MB @ 0xa000)
- **rootfs**: Root filesystem (grows from 0x10000)

### Custom Configurations

To modify the build configuration:

```bash
# Edit device-specific config
vi base/device/rockchip/.chips/rk3506/picocalc_luckfox_lyra_buildroot_sdmmc_defconfig

# Rebuild after changes
./build.sh clean
./build.sh
```

## Safety Notes

⚠️ **Important Safety Information**:

- Always use the correct USB port (LOWER USB-C)
- Ensure stable power during flashing
- Don't disconnect during flash process
- Keep backups of working firmware
- Test new firmware thoroughly before deploying

## Getting Help

If you encounter issues:

1. Check this troubleshooting section
2. Verify hardware connections and cable
3. Try the alternative loader mode method
4. Check system logs: `dmesg | tail -20`
5. Create an issue with:
   - Error messages
   - Hardware revision
   - Build configuration used
   - Steps taken before the error

## References

- [Rockchip Documentation](https://opensource.rock-chips.com/wiki_Main_Page)
- [LuckFox Lyra Documentation](https://wiki.luckfox.com/)
- [Build Instructions](README.md)
- [Package Management](ADDING_PACKAGES.md)
