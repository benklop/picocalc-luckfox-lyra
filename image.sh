#!/bin/bash

set -e

# Configuration
SDK_DIR="SDK"
TOOL_PATH="$SDK_DIR/tools/linux/programming_image_tool"
UPDATE_IMG="$SDK_DIR/output/firmware/update.img"
OUTPUT_DIR="output"
OUTPUT_IMAGE="$OUTPUT_DIR/sdcard.img"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]
Create an SD card image from the firmware

OPTIONS:
    -i INPUT     Input update.img file (default: $UPDATE_IMG)
    -o OUTPUT    Output SD card image file (default: $OUTPUT_IMAGE)
    -t TYPE      Storage type: SLC|SPINAND|SPINOR|EMMC (default: EMMC)
    -h           Show this help message

EXAMPLES:
    $0                                          # Use defaults
    $0 -i custom_update.img -o my_sdcard.img   # Custom input/output
    $0 -t SPINOR                               # Create image for SPI NOR flash

EOF
}

# Parse command line arguments
INPUT_FILE="$UPDATE_IMG"
OUTPUT_FILE="$OUTPUT_IMAGE"
STORAGE_TYPE="EMMC"

while getopts "i:o:t:h" opt; do
    case $opt in
        i)
            INPUT_FILE="$OPTARG"
            ;;
        o)
            OUTPUT_FILE="$OPTARG"
            ;;
        t)
            STORAGE_TYPE="$OPTARG"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            log_error "Invalid option: -$OPTARG"
            usage
            exit 1
            ;;
    esac
done

# Validate storage type
case "$STORAGE_TYPE" in
    SLC|SPINAND|SPINOR|EMMC)
        ;;
    *)
        log_error "Invalid storage type: $STORAGE_TYPE"
        log_error "Valid types: SLC, SPINAND, SPINOR, EMMC"
        exit 1
        ;;
esac

# Check if we're in the right directory
if [ ! -d "$SDK_DIR" ]; then
    log_error "SDK directory not found. Please run this script from the project root."
    exit 1
fi

# Check if the programmer tool exists
if [ ! -f "$TOOL_PATH/programmer_image_tool" ]; then
    log_error "programmer_image_tool not found at $TOOL_PATH"
    log_error "Make sure the SDK is properly extracted and tools are unpacked."
    exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    log_error "Input file not found: $INPUT_FILE"
    log_error "Please build the firmware first."
    exit 1
fi

# Create output directory
OUTPUT_DIR_PATH=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR_PATH"

log_info "Creating SD card image..."
log_info "Input file: $INPUT_FILE"
log_info "Output file: $OUTPUT_FILE"
log_info "Storage type: $STORAGE_TYPE"

# Get the absolute path of the input file
INPUT_FILE=$(realpath "$INPUT_FILE")
OUTPUT_FILE=$(realpath "$OUTPUT_FILE")

# Change to the tool directory
pushd "$TOOL_PATH" > /dev/null

# Run the programmer tool
log_info "Running programmer_image_tool..."
if ./programmer_image_tool -i "$INPUT_FILE" -t "$STORAGE_TYPE"; then
    log_info "Image creation successful"
else
    log_error "Failed to create image"
    popd > /dev/null
    exit 1
fi

# Check if the output image was created
if [ ! -f "out_image.bin" ]; then
    log_error "Expected output file 'out_image.bin' not found"
    popd > /dev/null
    exit 1
fi

# Move the image to the desired location
log_info "Moving image to $OUTPUT_FILE..."
mv "out_image.bin" "$OUTPUT_FILE"

popd > /dev/null

# Show final information
log_info "SD card image created successfully!"
log_info "Output: $OUTPUT_FILE"
log_info "Size: $(du -h "$OUTPUT_FILE" | cut -f1)"

echo ""
echo "You can now flash this image to an SD card using:"
echo "  sudo dd if=$OUTPUT_FILE of=/dev/sdX bs=1M status=progress"
echo "  (Replace /dev/sdX with your actual SD card device)"
echo ""
echo "Or use a tool like Raspberry Pi Imager, balenaEtcher, etc."
