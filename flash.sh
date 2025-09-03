#!/bin/bash
#
# Flash script for PicoCalc LuckFox Lyra
# Uses rkflash.sh to flash the update image via USB
#

set -e

# Default flash type and options
AUTO_YES=false
UPDATE_IMG="SDK/output/firmware/update.img"

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
    echo "   • ⚠️  EJECT any external SD card before running reboot command"
    echo -e "   • Log in and run: ${BLUE}reboot loader${NC} (device may hang if SD card is inserted)"
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
    
    # Check if we're using direct file flashing or rkflash.sh
    if [ "$FLASH_TYPE" = "file" ]; then
        # Direct flashing mode - check upgrade_tool and specified file
        if [ ! -f "SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool" ]; then
            echo -e "${RED}❌ Error: SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool not found${NC}"
            echo "Please build the firmware first using: ./build.sh"
            exit 1
        fi
        
        if [ ! -f "$UPDATE_IMG" ]; then
            echo -e "${RED}❌ Error: Specified image file '$UPDATE_IMG' not found${NC}"
            echo "Please check the path to your image file"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Prerequisites check passed${NC}"
        echo "   • upgrade_tool found"
        echo "   • Image file exists: $UPDATE_IMG ($(du -h "$UPDATE_IMG" | cut -f1))"
        echo
    else
        # Using upgrade_tool directly instead of rkflash.sh wrapper
        if [ ! -f "SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool" ]; then
            echo -e "${RED}❌ Error: SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool not found${NC}"
            echo "Please build the firmware first using: ./build.sh"
            exit 1
        fi
        
        # Check if update image exists (for update flash type)
        if [ "$FLASH_TYPE" = "update" ] && [ ! -f "$UPDATE_IMG" ]; then
            echo -e "${RED}❌ Error: $UPDATE_IMG not found${NC}"
            echo "Please build the firmware first using: ./build.sh"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Prerequisites check passed${NC}"
        echo "   • upgrade_tool found"
        if [ "$FLASH_TYPE" = "update" ]; then
            echo "   • Update image exists ($(du -h "$UPDATE_IMG" | cut -f1))"
        fi
        echo
    fi
    
    # Check USB permissions for both methods
    check_usb_permissions
}

confirm_flash() {
    local flash_method_desc
    if [ "$FLASH_TYPE" = "file" ]; then
        flash_method_desc="custom image file: $(basename "$UPDATE_IMG")"
    else
        flash_method_desc="'$FLASH_TYPE' image"
    fi
    
    if [ "$AUTO_YES" = true ]; then
        echo -e "${YELLOW}⚡ Auto-flashing $flash_method_desc (--yes mode)${NC}"
        echo -e "${RED}⚠️  WARNING: This will overwrite the firmware on your PicoCalc!${NC}"
        echo
        return
    fi
    
    echo -e "${YELLOW}⚡ Ready to flash $flash_method_desc${NC}"
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
    
    # Change to project directory to ensure paths work correctly
    cd "$(dirname "$0")"
    
    local flash_success=false
    local upgrade_tool="./SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool"
    
    # Function to run upgrade_tool and check exit code
    run_upgrade_tool() {
        local cmd="$@"
        echo -e "${BLUE}Running: $upgrade_tool $cmd${NC}"
        
        if $upgrade_tool $cmd; then
            return 0
        else
            echo -e "${RED}ERROR: upgrade_tool failed with exit code $?${NC}"
            return 1
        fi
    }
    
    if [ "$FLASH_TYPE" = "file" ]; then
        # Direct flashing with upgrade_tool
        echo -e "${GREEN}Flashing user-specified image: $UPDATE_IMG${NC}"
        echo
        if run_upgrade_tool uf "$UPDATE_IMG"; then
            flash_success=true
        fi
    else
        # Call upgrade_tool directly based on flash type
        case "$FLASH_TYPE" in
            "update")
                echo -e "${GREEN}Flashing update image: SDK/rockdev/update.img${NC}"
                echo
                if run_upgrade_tool uf "SDK/rockdev/update.img"; then
                    flash_success=true
                fi
                ;;
            "recovery")
                echo -e "${GREEN}Flashing recovery image: SDK/rockdev/recovery.img${NC}"
                echo
                if run_upgrade_tool di -r "SDK/rockdev/recovery.img"; then
                    flash_success=true
                fi
                ;;
            "firmware")
                echo -e "${GREEN}Flashing firmware components${NC}"
                echo
                # Flash multiple components for firmware
                if run_upgrade_tool ul -noreset "SDK/rockdev/MiniLoaderAll.bin" && \
                   run_upgrade_tool di -p "SDK/rockdev/parameter.txt" && \
                   run_upgrade_tool di -uboot "SDK/rockdev/uboot.img" && \
                   run_upgrade_tool di -trust "SDK/rockdev/trust.img" && \
                   run_upgrade_tool di -b "SDK/rockdev/boot.img" && \
                   run_upgrade_tool di -rootfs "SDK/rockdev/rootfs.img" && \
                   run_upgrade_tool rd; then
                    flash_success=true
                fi
                ;;
            *)
                echo -e "${RED}❌ Error: Unsupported flash type '$FLASH_TYPE'${NC}"
                echo "Supported types: update, recovery, firmware, or use -f for custom files"
                exit 1
                ;;
        esac
    fi
    
    # Handle results
    if [ "$flash_success" = true ]; then
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

check_erase_prerequisites() {
    echo -e "${BLUE}🔍 Checking erase prerequisites...${NC}"
    
    # Check upgrade_tool
    if [ ! -f "SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool" ]; then
        echo -e "${RED}❌ Error: SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool not found${NC}"
        echo "Please build the firmware first using: ./build.sh"
        exit 1
    fi
    
    # Check for loader file (required for erase operation)
    if [ ! -f "SDK/rockdev/MiniLoaderAll.bin" ]; then
        echo -e "${RED}❌ Error: SDK/rockdev/MiniLoaderAll.bin not found${NC}"
        echo "The erase operation requires a loader file to be present."
        echo "Please build the firmware first using: ./build.sh"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
    echo "   • upgrade_tool found"
    echo "   • Loader file exists: SDK/rockdev/MiniLoaderAll.bin"
    echo "   • Erase operation ready"
    echo
    
    # Check USB permissions
    check_usb_permissions
}

confirm_erase() {
    echo -e "${RED}🚨 DANGER: Ready to ERASE FLASH MEMORY${NC}"
    echo
    echo -e "${RED}⚠️  CRITICAL WARNING: This will COMPLETELY ERASE all flash memory!${NC}"
    echo -e "${RED}⚠️  Your device will be unbootable until you flash new firmware!${NC}"
    echo -e "${RED}⚠️  Make sure you have a way to recover your device!${NC}"
    echo
    read -p "Type 'ERASE' in uppercase to confirm this destructive operation: " -r
    echo
    if [[ "$REPLY" != "ERASE" ]]; then
        echo -e "${YELLOW}Erase operation cancelled (confirmation failed)${NC}"
        exit 0
    fi
    echo
}

erase_device() {
    echo -e "${RED}🚨 Starting ERASE process...${NC}"
    echo
    echo -e "${YELLOW}Make sure your PicoCalc is in loader mode and connected via USB-C!${NC}"
    echo -e "${RED}⚠️  This will COMPLETELY ERASE the flash memory!${NC}"
    echo
    
    # Change to project directory to ensure paths work correctly
    cd "$(dirname "$0")"
    
    local upgrade_tool="./SDK/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool"
    
    echo -e "${RED}Executing: $upgrade_tool EF SDK/rockdev/MiniLoaderAll.bin${NC}"
    echo
    
    if $upgrade_tool EF "SDK/rockdev/MiniLoaderAll.bin"; then
        echo
        echo -e "${GREEN}✅ Flash erase completed successfully!${NC}"
        echo
        echo -e "${RED}🚨 IMPORTANT: Your device flash has been erased!${NC}"
        echo -e "${BLUE}📱 Next steps:${NC}"
        echo "   • The device will NOT boot until you flash new firmware"
        echo "   • Flash a firmware image using: ./flash.sh update"
        echo "   • Or flash a custom image using: ./flash.sh -f your_image.img"
        echo
    else
        echo
        echo -e "${RED}❌ Flash erase failed!${NC}"
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
    echo "  -y, --yes        Skip confirmation prompts and flash automatically"
    echo "  -f, --file FILE  Flash a specific image file directly with upgrade_tool"
    echo "  -h, --help       Show this help message"
    echo
    echo "Flash types (when not using --file):"
    echo "  update    - Flash complete update image (default)"
    echo "  recovery  - Flash recovery image"
    echo "  firmware  - Flash firmware only"
    echo "  erase     - Erase the flash memory (WARNING: destructive!)"
    echo
    echo "Examples:"
    echo "  $0                        # Flash update image with prompts"
    echo "  $0 -y                     # Flash update image automatically"
    echo "  $0 -y update              # Flash update image automatically"
    echo "  $0 recovery               # Flash recovery image with prompts"
    echo "  $0 erase                  # Erase flash memory (with confirmation)"
    echo "  $0 -f custom.img          # Flash custom image file directly"
    echo "  $0 -y -f custom.img       # Flash custom image file automatically"
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
            -f|--file)
                FLASH_TYPE='file'
                shift
                if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                    UPDATE_IMG="$1"
                    shift
                else
                    echo -e "${RED}Error: No update image specified after --file option${NC}"
                    show_usage
                    exit 1
                fi
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
    
    # Handle erase operation separately
    if [ "$FLASH_TYPE" = "erase" ]; then
        print_header
        print_instructions
        check_erase_prerequisites
        confirm_erase
        erase_device
        exit 0
    fi
    
    print_header
    print_instructions
    check_prerequisites
    confirm_flash
    flash_device
}

# Run main function
main "$@"
