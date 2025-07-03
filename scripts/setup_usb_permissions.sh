#!/bin/bash
#
# Setup script for PicoCalc LuckFox Lyra USB permissions
# This script installs udev rules to allow non-root flashing
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

UDEV_RULE_FILE="scripts/99-rockchip.rules"
UDEV_DEST="/etc/udev/rules.d/99-rockchip.rules"

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} PicoCalc USB Permissions Setup${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if udev rule file exists
    if [ ! -f "$UDEV_RULE_FILE" ]; then
        echo -e "${RED}❌ Error: $UDEV_RULE_FILE not found${NC}"
        echo "Make sure you're running this from the project root directory"
        exit 1
    fi
    
    # Check if running as root (we need sudo)
    if [ "$EUID" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Warning: Running as root. This is not recommended.${NC}"
        echo "Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: sudo command not found${NC}"
        echo "This script requires sudo to install system files"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
    echo
}

check_existing_setup() {
    echo -e "${BLUE}🔍 Checking existing setup...${NC}"
    
    local needs_setup=false
    
    # Check if udev rule is installed
    if [ -f "$UDEV_DEST" ]; then
        echo -e "${GREEN}✅ udev rule already installed at $UDEV_DEST${NC}"
    else
        echo -e "${YELLOW}⚠️  udev rule not installed${NC}"
        needs_setup=true
    fi
    
    # Check if user is in plugdev group
    if groups "$USER" | grep -q '\bplugdev\b'; then
        echo -e "${GREEN}✅ User '$USER' is in plugdev group${NC}"
    else
        echo -e "${YELLOW}⚠️  User '$USER' is not in plugdev group${NC}"
        needs_setup=true
    fi
    
    # Test device access if device is connected
    if lsusb | grep -q "2207:350f"; then
        echo -e "${GREEN}✅ Rockchip device detected${NC}"
        # Try to access the device
        local device_path
        device_path=$(find /dev/bus/usb -name "*" -exec lsusb -D {} 2>/dev/null \; | grep -B5 "2207:350f" | grep "Device:" | cut -d' ' -f2 | head -1)
        if [ -n "$device_path" ] && [ -r "$device_path" ] && [ -w "$device_path" ]; then
            echo -e "${GREEN}✅ Device is accessible without sudo${NC}"
        else
            echo -e "${YELLOW}⚠️  Device found but not accessible without sudo${NC}"
            needs_setup=true
        fi
    else
        echo -e "${BLUE}ℹ️  No Rockchip device currently connected${NC}"
    fi
    
    echo
    
    if [ "$needs_setup" = false ]; then
        echo -e "${GREEN}🎉 USB permissions are already set up correctly!${NC}"
        echo "You should be able to flash without sudo."
        echo
        exit 0
    fi
    
    return 0
}

install_udev_rule() {
    echo -e "${BLUE}📋 Installing udev rule...${NC}"
    
    # Copy the udev rule
    echo "Installing udev rule to $UDEV_DEST..."
    sudo cp "$UDEV_RULE_FILE" "$UDEV_DEST"
    echo -e "${GREEN}✅ udev rule installed${NC}"
    
    # Reload udev rules
    echo "Reloading udev rules..."
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo -e "${GREEN}✅ udev rules reloaded${NC}"
    
    echo
}

add_user_to_group() {
    echo -e "${BLUE}👥 Adding user to plugdev group...${NC}"
    
    # Add user to plugdev group
    sudo usermod -a -G plugdev "$USER"
    echo -e "${GREEN}✅ User '$USER' added to plugdev group${NC}"
    
    echo
}

show_completion_message() {
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo "1. ${YELLOW}Log out and log back in${NC} (or restart your session)"
    echo "   This is required for the group membership changes to take effect."
    echo
    echo "2. Connect your PicoCalc in loader mode and test:"
    echo "   ${BLUE}lsusb | grep Rockchip${NC}"
    echo
    echo "3. You should now be able to flash without sudo:"
    echo "   ${BLUE}./flash.sh${NC}"
    echo
    echo -e "${BLUE}ℹ️  If you still have permission issues after logging out/in:${NC}"
    echo "   • Check if the device is detected: ${BLUE}lsusb | grep 2207:350f${NC}"
    echo "   • Verify group membership: ${BLUE}groups${NC}"
    echo "   • Try unplugging and reconnecting the device"
    echo
}

confirm_installation() {
    echo -e "${YELLOW}🔧 Ready to set up USB permissions for Rockchip devices${NC}"
    echo
    echo "This will:"
    echo "• Install udev rule to /etc/udev/rules.d/"
    echo "• Add your user to the 'plugdev' group"
    echo "• Allow flashing without sudo"
    echo
    read -p "Continue with setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Setup cancelled by user${NC}"
        exit 0
    fi
    echo
}

show_usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -c, --check   Only check current setup, don't install"
    echo
    echo "This script sets up USB permissions for flashing Rockchip devices"
    echo "without requiring sudo privileges."
    echo
}

# Main script
main() {
    local check_only=false
    
    # Parse arguments
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--check)
            check_only=true
            ;;
        *)
            if [ -n "${1:-}" ]; then
                echo -e "${RED}Error: Unknown option '$1'${NC}"
                show_usage
                exit 1
            fi
            ;;
    esac
    
    print_header
    check_prerequisites
    check_existing_setup
    
    if [ "$check_only" = true ]; then
        echo -e "${BLUE}ℹ️  Check complete. Run without -c to install.${NC}"
        exit 0
    fi
    
    confirm_installation
    install_udev_rule
    add_user_to_group
    show_completion_message
}

# Run main function
main "$@"
