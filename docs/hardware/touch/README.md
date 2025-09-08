# Touch Controller Documentation

## GT911 Touch Controller

This directory contains configuration files for touch controllers used with various display configurations.

**IMPORTANT NOTE**: The current 720x720 DSI display implementation does NOT include touch hardware. The GT911 configuration file is provided for reference only, as the specific display module acquired does not have integrated touch capability. Additionally, the PicoCalc hardware design would require modifications to support touchscreen functionality (The front glass panel would have to be replaced with or bonded to the display itself).

## Files

- `FT040037_GT911_Config_20231103.cfg` - GT911 configuration for 720x720 DSI display (FL7707N) - **REFERENCE ONLY**

## GT911 Configuration

The GT911 is a capacitive touch controller that communicates via I2C. The configuration file contains:

- Touch resolution settings (720x720)
- Sensitivity and filtering parameters
- Multi-touch configuration
- Interrupt and reset timing
- Calibration data

**Note**: This configuration is provided for reference purposes and future hardware iterations that may include touch capability.

## Implementation Notes

**Current Status**: Touch functionality is NOT implemented in the current PicoCalc design.

The GT911 typically requires:
- I2C address: 0x5D or 0x14 (configurable via hardware)
- Interrupt GPIO for touch events
- Reset GPIO for controller initialization
- Configuration upload on startup

**Hardware Modifications Required**: To support touchscreen functionality, the PicoCalc would need:
- The front glass panel would have to be replaced with or bonded to the display itself
- Firmware modifications to handle touch input
- Device tree configuration for touch controller

## Integration

The touch controller configuration is provided for reference only. If implementing touch support in future hardware revisions, the touch controller should be integrated into the device tree alongside the display configuration, ensuring proper GPIO assignments and I2C bus configuration.

**Note**: The current 720x720 DSI display implementation focuses solely on display output without touch input capability.
