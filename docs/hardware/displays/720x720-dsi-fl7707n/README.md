# 720x720 DSI Display (FL7707N Controller)

## Overview

This directory contains documentation and configuration files for supporting a 720x720 DSI display with FL7707N controller.

**Product Link**: [AliExpress - 720x720 DSI Display](https://www.aliexpress.us/item/3256807565141061.html)

**IMPORTANT**: This specific display module does NOT include touch hardware. While GT911 touch controller documentation is provided for reference, the current implementation focuses solely on display output. The PicoCalc hardware would require modifications to support touchscreen functionality.

## Specifications

- **Resolution**: 720x720 pixels
- **Panel Type**: IPS
- **Interface**: 2-lane MIPI DSI
- **Display Controller**: FL7707N
- **Touch Controller**: None (display-only module)

**Note**: While GT911 touch controller configuration is available in the documentation, this specific display module does not include touch hardware.

## Display Timing Parameters

```
Width:  720
Height: 720

Vertical Timing:
- VFP: 20 (Vertical Front Porch)
- VBP: 20 (Vertical Back Porch) 
- VSA: 4  (Vertical Sync Active)

Horizontal Timing:
- HFP: 106 (Horizontal Front Porch)
- HBP: 120 (Horizontal Back Porch)
- HSA: 60  (Horizontal Sync Active)
```

## Files

### Display Controller Documentation
- `2_FL7707N_QV040YNQ-N80_IPS_Code_2Power_V5.5_20230810.txt` - Display initialization sequence and timing configuration
- `FL7707N_DS_V0.2_20230324_Customer.pdf` - FL7707N display controller datasheet and specifications

### Display Module Documentation  
- `HD395003C30-V2 规格书.pdf` - Display module specifications (Chinese language specification sheet)
- `HD395003C30工程图20231023.dwg` - Engineering drawings and mechanical specifications (AutoCAD format)

### Touch Controller Configuration (Reference Only)
- `../../touch/FT040037_GT911_Config_20231103.cfg` - GT911 touch controller configuration (not applicable to current display)

## DSI Configuration

- **DSI Mode**: 2-lane (0x31 in register 0xBA[1])
- **Power Mode**: 2-power configuration
- **Color Format**: RGB888

## Implementation Status

- [ ] Device tree overlay creation
- [ ] Display driver implementation
- [ ] Timing parameter configuration
- [ ] Power sequence setup
- [ ] Testing and validation

**Note**: Touch controller integration is not included in current implementation scope as the display module lacks touch hardware.

## Notes

The initialization sequence includes:
- Power management configuration (B8 register for 2-power mode)
- DSI lane configuration (BA register)
- Gamma correction settings (E0 register)
- GIP (Gate In Panel) timing configuration (E9/EA registers)
- Touch controller I2C configuration

## Related TODO Items

See main TODO.md for current implementation status and detailed task breakdown.
