# TODO List - PicoCalc Lyra Build System

This document tracks known issues, work-in-progress features, and planned improvements for the PicoCalc LuckFox Lyra build system.

## 🚨 Critical Issues (Not Working)

### Audio System
- [ ] **Stereo hardware PWM audio** - Audio output is not yet fully functional
  - Current DTS configuration exists but driver integration incomplete
  - PWM channels configured in device tree: `pwm0_4ch_0` channels 1 & 2
  - Custom sound card driver (`fsl,picocalc-snd-pwm`) needs work
  - **Priority**: High

### WiFi Connectivity  
- [ ] **RTL8188FU WiFi driver** - Driver builds but WiFi not functional
  - Driver package exists in `base/buildroot/package/rtl8188fu/`
  - Firmware installation configured but may need debugging
  - Kernel configuration requirements may need adjustment
  - **Priority**: High

## 🔧 Build System Improvements

### USB Flashing
- [ ] **Automatic ADB reboot for flashing** - Use ADB to automatically reboot device into loader mode
  - Currently users must manually run `reboot loader` or use hardware boot button
  - Could detect ADB-connected device and automatically trigger loader mode
  - Would streamline flashing workflow significantly
  - **Priority**: Medium

## 📦 Package System

### RTL8188FU Driver Package
- [x] ✅ **Package creation** - BuildRoot package exists
- [x] ✅ **Firmware installation** - Configured in package makefile
- [ ] **Driver debugging** - Investigate why WiFi doesn't work
- [ ] **Kernel config validation** - Ensure all required options enabled

### Audio Packages
- [ ] **ALSA utilities** - Add alsa-utils package for audio debugging
- [ ] **Audio testing tools** - Add speaker-test, aplay utilities
- [ ] **Sound card detection** - Verify ALSA can see the PWM sound device

## 🖥️ System Integration

### Device Tree
- [x] ✅ **Basic hardware support** - SD card, USB, I2C, SPI working
- [x] ✅ **Display support** - ILI9488 LCD working
- [x] ✅ **Keyboard support** - PicoCalc keyboard working  
- [x] ✅ **RTC support** - DS3231 RTC working
- [ ] **Audio pinmux** - Verify PWM audio pins are correctly configured
- [ ] **WiFi power management** - May need additional power/reset GPIO config
- [ ] **Serial terminal on top USB port** - Enable serial console access via upper USB-C port
  - Currently only lower port (Lyra) supports flashing/USB OTG
  - Upper port connected through MCU, could provide serial access
  - Would enable easier debugging without opening device
  - **Priority**: Medium
- [ ] **Terminal font size optimization** - Adjust console font for 320x320 display
  - Current font (6x8) may be too small for the display size
  - Need to find optimal balance between readability and screen real estate
  - Consider fonts like 8x16 or custom bitmap fonts
  - **Priority**: Medium

### Boot Configuration
- [ ] **Document Windows flashing process** - I don't use windows so I can't really test this as easily
- [ ] **Separate /home partition** - Split /home into dedicated partition to preserve user data
  - Currently /home is part of rootfs and gets wiped during firmware updates
  - Would allow firmware updates while preserving user files and configurations
  - Requires modifying partition layout and parameter.txt
  - **Priority**: Medium

## 🧪 Testing & Validation

### Hardware Testing
- [ ] **WiFi scanning** - Test if RTL8188FU can at least scan networks
- [ ] **Power management** - Test suspend/resume functionality

### Build Testing
- [ ] **Clean build validation** - Test complete clean builds
- [ ] **Package set testing** - Validate package set overlay system
- [ ] **Cross-platform testing** - Test on different Linux distributions

## 🔌 Power Management Integration

### MCU Power Management
- [ ] **MCU firmware modifications** - Extend MCU firmware for power management
  - Add support for detecting short button press events (vs long press that 
    should still be handled by the MCU directly)
  - Implement power state commands (power off at least)
  - Create communication protocol for power management between MCU and Linux
  - **Priority**: High
- [ ] **Linux power management driver** - Create or extend driver for MCU power features
  - Option 1: Integrate into existing keyboard driver (same MCU device)
  - Option 2: Create separate power management driver
  - Handle button press events and translate to Linux power events
  - Implement power state control interface
  - **Priority**: High

## 📚 Documentation

### User Documentation
- [x] ✅ **Flashing guide** - Comprehensive FLASHING.md
- [x] ✅ **Build instructions** - Clear README.md
- [x] ✅ **Package development** - Detailed ADDING_PACKAGES.md
- [ ] **Troubleshooting guide** - Expand troubleshooting sections
- [ ] **Hardware documentation** - Document GPIO usage, pinout

### Developer Documentation
- [ ] **Device tree reference** - Document custom DT bindings
- [ ] **Performance optimization** - Build optimization tips

## 🔮 Future Enhancements

### Additional Hardware Support
- [ ] **Support LoRA radio** - use a bitbanged SPI interface on the pads below the lyra for this

### Software Features
- [ ] **Package manager** - Add package management for runtime installs

### Build System
- [ ] **Multi-target support** - Support for selecting different hardware variants
    - add/remove RTC from devicetree
    - add/remove Lyra SPI pins from devicetree
    - add/remove/select USB wifi driver
    - add/remove/select PWM audio driver
        - software PWM on one channel
        - hardware pwm on one channel
        - hardware pwm on two channels

## 🚀 Nice to Have

- [ ] **Community packages** - Package repository for community contributions

---

## Notes

- **Priority Levels**: High (blocking basic functionality), Medium (usability), Low (convenience)
- **Status**: ✅ Complete, 🚧 In Progress, ❌ Blocked, 📝 Planning
- **Contributors**: Mark completed items with contributor name and date

## Contributing

When working on items from this list:

1. Move item to "In Progress" section with 🚧 marker
2. Create detailed issue/PR describing the work
3. Update this file when work is completed
4. Add any new discoveries or blockers to relevant sections

For questions about specific TODO items, create an issue referencing this file.
