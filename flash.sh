#!/bin/bash
#
# Flash script for PicoCalc LuckFox Lyra
# Uses rkflash.sh to flash the update image via USB
#

set -e

# Default flash type and options
FLASH_TYPE="${1:-update}"
AUTO_YES=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} PicoCalc LuckFox Lyra Flash Tool${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

print_instructions() {
    echo -e "${YELLOW}📋 FLASHING INSTRUCTIONS:${NC}"
    echo
    echo -e "${GREEN}1. Prepare the PicoCalc:${NC}"
    echo "   • Insert SD card into the LuckFox Lyra SD card slot"
    echo "   • Boot the PicoCalc to Linux"
    echo -e "   • Log in and run: ${BLUE}reboot loader${NC}"
    echo "   • The device will reboot into loader mode"
    echo
    echo -e "${GREEN}2. Connect USB:${NC}"
    echo -e "   • Connect USB-C cable to the ${YELLOW}LOWER${NC} USB-C port (LuckFox Lyra)"
    echo "   • Connect other end to your computer"
    echo "   • The device should be detected in loader mode"
    echo
    echo -e "${GREEN}3. Alternative method (if Linux access unavailable):${NC}"
    echo "   • Remove back cover of PicoCalc"
    echo "   • Hold BOOT button while plugging in USB cable"
    echo "   • Keep holding until device is detected"
    echo
    echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
    echo "   • Use the LOWER USB-C port (LuckFox Lyra), not the upper one"
    echo "   • SD card must be inserted before flashing"
    echo "   • Ensure update image has been built first"
    echo
}

get_target_group() {
    # Check if plugdev group exists, fall back to dialout
    if getent group plugdev >/dev/null 2>&1; then
        echo "plugdev"
    elif getent group dialout >/dev/null 2>&1; then
        echo "dialout"
    else
        echo ""
    fi
}

check_usb_permissions() {
    echo -e "${BLUE}🔍 Checking USB permissions...${NC}"
    
    local needs_setup=false
    local udev_rule_installed=false
    local user_in_group=false
    local target_group
    target_group=$(get_target_group)
    
    if [ -z "$target_group" ]; then
        echo -e "${RED}❌ Error: Neither 'plugdev' nor 'dialout' group exists${NC}"
        echo "Cannot determine which group to use for USB device access"
        exit 1
    fi
    
    echo -e "${BLUE}ℹ️  Using group: $target_group${NC}"
    
    # Check if udev rule is installed
    if [ -f "/etc/udev/rules.d/99-rockchip.rules" ]; then
        udev_rule_installed=true
        echo -e "${GREEN}✅ udev rule installed${NC}"
    else
        echo -e "${YELLOW}⚠️  udev rule not installed${NC}"
        needs_setup=true
    fi
    
    # Check if user is in target group
    if groups "$USER" | grep -q "\b$target_group\b"; then
        user_in_group=true
        echo -e "${GREEN}✅ User in $target_group group${NC}"
    else
        echo -e "${YELLOW}⚠️  User not in $target_group group${NC}"
        needs_setup=true
    fi
    
    if [ "$needs_setup" = true ]; then
        echo -e "${YELLOW}⚠️  USB permissions not set up for non-root flashing${NC}"
        echo
        echo -e "${BLUE}ℹ️  Options:${NC}"
        echo -e "1. Run: ${BLUE}./scripts/setup_usb_permissions.sh${NC} (recommended)"
        echo -e "2. Flash with sudo: ${BLUE}sudo ./flash.sh${NC}"
        echo
        read -p "Would you like to set up USB permissions now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Running USB permissions setup...${NC}"
            if ./scripts/setup_usb_permissions.sh; then
                echo -e "${GREEN}✅ USB permissions setup completed${NC}"
                echo -e "${YELLOW}⚠️  Please log out and back in for changes to take effect${NC}"
                echo "Then re-run this script."
                exit 0
            else
                echo -e "${RED}❌ USB permissions setup failed${NC}"
                echo "You can still flash with sudo."
            fi
        else
            echo -e "${YELLOW}⚠️  Continuing without USB permissions setup${NC}"
            echo "If flashing fails, try running with sudo or set up permissions."
        fi
        echo
    else
        echo -e "${GREEN}✅ USB permissions configured${NC}"
    fi
}

check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if rkflash.sh exists
    if [ ! -f "scripts/rkflash.sh" ]; then
        echo -e "${RED}❌ Error: scripts/rkflash.sh not found${NC}"
        echo "Make sure you're running this from the project root directory"
        exit 1
    fi
    
    # Check if output directory exists
    if [ ! -d "output" ]; then
        echo -e "${RED}❌ Error: output directory not found${NC}"
        echo "Please build the firmware first using: ./build.sh"
        exit 1
    fi
    
    # Check if update image exists
    UPDATE_IMG="output/firmware/update.img"
    if [ ! -f "$UPDATE_IMG" ]; then
        echo -e "${RED}❌ Error: $UPDATE_IMG not found${NC}"
        echo "Please build the firmware first using: ./build.sh"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
    echo "   • rkflash.sh found"
    echo "   • Output directory exists"
    echo "   • Update image exists ($(du -h "$UPDATE_IMG" | cut -f1))"
    echo
    
    # Check USB permissions
    check_usb_permissions
}

confirm_flash() {
    if [ "$AUTO_YES" = true ]; then
        echo -e "${YELLOW}⚡ Auto-flashing '$FLASH_TYPE' image (--yes mode)${NC}"
        echo -e "${RED}⚠️  WARNING: This will overwrite the firmware on your PicoCalc!${NC}"
        echo
        return
    fi
    
    echo -e "${YELLOW}⚡ Ready to flash '$FLASH_TYPE' image${NC}"
    echo
    echo -e "${RED}⚠️  WARNING: This will overwrite the firmware on your PicoCalc!${NC}"
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Flash cancelled by user${NC}"
        exit 0
    fi
    echo
}

flash_device() {
    echo -e "${BLUE}🚀 Starting flash process...${NC}"
    echo
    echo -e "${YELLOW}Make sure your PicoCalc is in loader mode and connected via USB-C!${NC}"
    echo
    
    if [ "$AUTO_YES" = false ]; then
        read -p "Press Enter when ready to flash, or Ctrl+C to cancel..."
        echo
    fi
    
    # Change to project directory to ensure rkflash.sh can find relative paths
    cd "$(dirname "$0")"
    
    echo -e "${GREEN}Executing: ./scripts/rkflash.sh $FLASH_TYPE${NC}"
    echo
    
    # Run the actual flash command
    if ./scripts/rkflash.sh "$FLASH_TYPE"; then
        echo
        echo -e "${GREEN}✅ Flash completed successfully!${NC}"
        echo
        echo -e "${BLUE}📱 Next steps:${NC}"
        echo "   • The device should now be booting from the new firmware"
        echo
    else
        echo
        echo -e "${RED}❌ Flash failed!${NC}"
        echo
        echo -e "${YELLOW}Troubleshooting:${NC}"
        echo "   • Check USB connection to LOWER USB-C port"
        echo "   • Verify device is in loader mode"
        echo "   • Try 'lsusb | grep Rockchip' to see if device is detected"
        echo "   • Run USB permissions setup: ./scripts/setup_usb_permissions.sh"
        echo "   • Or try with sudo: sudo ./flash.sh"
        echo
        exit 1
    fi
}

show_usage() {
    echo "Usage: $0 [options] [flash_type]"
    echo
    echo "Options:"
    echo "  -y, --yes     Skip confirmation prompts and flash automatically"
    echo "  -h, --help    Show this help message"
    echo
    echo "Flash types:"
    echo "  update    - Flash complete update image (default)"
    echo "  recovery  - Flash recovery image"
    echo "  firmware  - Flash firmware only"
    echo
    echo "Examples:"
    echo "  $0              # Flash update image with prompts"
    echo "  $0 -y           # Flash update image automatically"
    echo "  $0 -y update    # Flash update image automatically"
    echo "  $0 recovery     # Flash recovery image with prompts"
    echo
}

# Main script
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Error: Unknown option '$1'${NC}"
                show_usage
                exit 1
                ;;
            *)
                FLASH_TYPE="$1"
                shift
                ;;
        esac
    done
    
    # Set default flash type if not specified
    if [ -z "$FLASH_TYPE" ]; then
        FLASH_TYPE="update"
    fi
    
    print_header
    print_instructions
    check_prerequisites
    confirm_flash
    flash_device
}

# Run main function
main "$@"
