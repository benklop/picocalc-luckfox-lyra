# Hardware Documentation

This directory contains documentation for various hardware components and modifications supported by the PicoCalc LuckFox Lyra build system.

## Directory Structure

```
hardware/
├── displays/           # Display-related documentation
│   └── 720x720-dsi-fl7707n/  # 720x720 DSI display with FL7707N controller
│       ├── README.md          # Display specifications and implementation guide
│       └── *.txt              # Initialization sequences and timing data
└── touch/              # Touch controller documentation
    ├── README.md       # Touch controller overview
    └── *.cfg           # Touch controller configuration files
```

## Supported Hardware

### Displays
- **720x720 DSI (FL7707N)** - High-resolution DSI display with GT911 touch controller
  - Status: Planned implementation
  - Documentation: `displays/720x720-dsi-fl7707n/`

### Touch Controllers
- **GT911** - Capacitive touch controller for DSI displays
  - Status: Configuration available
  - Documentation: `touch/`

## Adding New Hardware

When adding support for new hardware components:

1. Create appropriate subdirectory under the relevant category
2. Include all configuration files, datasheets, and technical documentation
3. Create a comprehensive README.md with specifications and implementation notes
4. Update the main TODO.md with implementation tasks
5. Add entry to this index file

## Implementation Status

Current hardware implementation status can be found in the main [TODO.md](../../TODO.md) file under the "Additional Hardware Support" section.
