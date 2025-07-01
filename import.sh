#!/bin/bash
set -e

# Package import script for PicoCalc Lyra SDK
# Compares packages from external buildroot against SDK and overlay
# and imports them appropriately (copy, patch, or report conflicts)
#
# Usage: ./import.sh [--dryrun]
#   --dryrun    Show what would be done without making changes

EXTERNAL_PACKAGES="../picocalc_luckfox_lyra/buildroot/package"
SDK_PACKAGES="SDK/Lyra-SDK/buildroot/package"
BASE_PACKAGES="base/buildroot/package"
REPORT_FILE="import_report.txt"

# Parse command line arguments
DRYRUN=false
DEBUG=false
for arg in "$@"; do
    case $arg in
        --dryrun|--dry-run|-n)
            DRYRUN=true
            shift
            ;;
        --debug|-d)
            DEBUG=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--dryrun] [--debug]"
            echo "  --dryrun    Show what would be done without making changes"
            echo "  --debug     Show additional debug information"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize report (only in real mode)
if [ "$DRYRUN" = false ]; then
    echo "Package Import Report - $(date)" > "$REPORT_FILE"
    echo "==========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Counters - use files to persist across subshells if needed
COPIED_NEW=0
CREATED_PATCHES=0
CONFLICTS=0
SKIPPED=0

# Helper functions for counters
increment_counter() {
    local counter_name="$1"
    case "$counter_name" in
        "COPIED_NEW") COPIED_NEW=$((COPIED_NEW + 1)) ;;
        "CREATED_PATCHES") CREATED_PATCHES=$((CREATED_PATCHES + 1)) ;;
        "CONFLICTS") CONFLICTS=$((CONFLICTS + 1)) ;;
        "SKIPPED") SKIPPED=$((SKIPPED + 1)) ;;
    esac
    return 0  # Always return success
}

log() {
    echo -e "$1"
}

debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

log_report() {
    if [ "$DRYRUN" = false ]; then
        echo "$1" >> "$REPORT_FILE"
    fi
}

# Function to check if two files are identical
files_identical() {
    local file1="$1"
    local file2="$2"
    
    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        return 1
    fi
    
    diff -q "$file1" "$file2" >/dev/null 2>&1
}

# Function to create a patch between two files
create_patch() {
    local original="$1"
    local modified="$2"
    local patch_file="$3"
    local patch_name="$4"
    
    if [ "$DRYRUN" = true ]; then
        # In dry run mode, just check if patch would be successful
        if diff -u "$original" "$modified" >/dev/null 2>&1; then
            return 1  # Files are identical, no patch needed
        else
            return 0  # Files differ, patch would be created
        fi
    fi
    
    local patch_dir=$(dirname "$patch_file")
    mkdir -p "$patch_dir"
    
    # Create git-style patch
    {
        echo "--- a/buildroot/package/$patch_name"
        echo "+++ b/buildroot/package/$patch_name"
        diff -u "$original" "$modified" | tail -n +3
    } > "$patch_file"
    
    return $?
}

# Function to process a single file
process_file() {
    local rel_path="$1"  # Relative path from packages directory
    local external_file="$EXTERNAL_PACKAGES/$rel_path"
    local sdk_file="$SDK_PACKAGES/$rel_path"
    local base_file="$BASE_PACKAGES/$rel_path"
    
    # Skip if external file doesn't exist
    if [ ! -f "$external_file" ]; then
        return
    fi
    
    local filename=$(basename "$rel_path")
    local dirname=$(dirname "$rel_path")
    
    log "${BLUE}Processing: $rel_path${NC}"
    
    # Case 1: File doesn't exist in SDK - copy directly to base
    if [ ! -f "$sdk_file" ]; then
        if [ "$DRYRUN" = true ]; then
            log "  ${GREEN}→ WOULD COPY: New file to base${NC}"
        else
            log "  ${GREEN}→ New file, copying to base${NC}"
            mkdir -p "$(dirname "$base_file")"
            cp "$external_file" "$base_file"
        fi
        log_report "COPIED (New): $rel_path"
        increment_counter "COPIED_NEW"
        return
    fi
    
    # Case 2: File exists in SDK, check if it's identical
    if files_identical "$external_file" "$sdk_file"; then
        if [ "$DRYRUN" = true ]; then
            log "  ${YELLOW}→ WOULD SKIP: Identical to SDK${NC}"
        else
            log "  ${YELLOW}→ Identical to SDK, skipping${NC}"
        fi
        log_report "SKIPPED (Identical): $rel_path"
        increment_counter "SKIPPED"
        return
    fi
    
    # Case 3: File differs from SDK
    if [ ! -f "$base_file" ]; then
        # No base version exists, create patch
        if [ "$DRYRUN" = true ]; then
            log "  ${GREEN}→ WOULD PATCH: Create $rel_path.patch${NC}"
            log_report "PATCH WOULD BE CREATED: $rel_path -> $rel_path.patch"
        else
            log "  ${GREEN}→ Creating patch for differences from SDK${NC}"
            local patch_file="${base_file}.patch"
            
            if create_patch "$sdk_file" "$external_file" "$patch_file" "$rel_path"; then
                log_report "PATCH CREATED: $rel_path -> $rel_path.patch"
            else
                log "  ${RED}→ Failed to create patch${NC}"
                log_report "PATCH FAILED: $rel_path"
                return
            fi
        fi
        increment_counter "CREATED_PATCHES"
        return
    fi
    
    # Case 4: File exists in base - check for conflicts
    if files_identical "$external_file" "$base_file"; then
        if [ "$DRYRUN" = true ]; then
            log "  ${YELLOW}→ WOULD SKIP: Identical to existing base${NC}"
        else
            log "  ${YELLOW}→ Identical to existing base file, skipping${NC}"
        fi
        log_report "SKIPPED (Base identical): $rel_path"
        increment_counter "SKIPPED"
    else
        log "  ${RED}→ CONFLICT: File differs from both SDK and existing base version${NC}"
        log_report "CONFLICT: $rel_path"
        log_report "  - External: $external_file"
        log_report "  - SDK:      $sdk_file"
        log_report "  - Base:     $base_file"
        log_report "  Manual resolution required."
        log_report ""
        increment_counter "CONFLICTS"
    fi
}

# Function to process a directory recursively
process_directory() {
    local dir="$1"
    local base_path="$EXTERNAL_PACKAGES"
    
    if [ ! -d "$base_path/$dir" ]; then
        return
    fi
    
    # Use process substitution instead of pipeline to avoid subshell issues
    while IFS= read -r -d '' file; do
        local rel_path="${file#$base_path/}"
        process_file "$rel_path"
    done < <(find "$base_path/$dir" -type f \( -name "*.mk" -o -name "Config.in" -o -name "*.patch" -o -name "*.hash" \) -print0)
}

# Main execution
if [ "$DRYRUN" = true ]; then
    log "${BLUE}=== Package Import Preview (Dry Run) ===${NC}"
    log "This shows what would happen without making changes"
else
    log "${BLUE}=== Package Import Tool ===${NC}"
fi
log "External packages: $EXTERNAL_PACKAGES"
log "SDK packages:      $SDK_PACKAGES"
log "Base packages:     $BASE_PACKAGES"
log ""

# Check if external packages directory exists
if [ ! -d "$EXTERNAL_PACKAGES" ]; then
    log "${RED}Error: External packages directory not found: $EXTERNAL_PACKAGES${NC}"
    exit 1
fi

# Check if SDK packages directory exists
if [ ! -d "$SDK_PACKAGES" ]; then
    log "${RED}Error: SDK packages directory not found: $SDK_PACKAGES${NC}"
    exit 1
fi

# Create base packages directory if it doesn't exist (only in real mode)
if [ "$DRYRUN" = false ]; then
    mkdir -p "$BASE_PACKAGES"
fi

# Get list of all package directories in external source
log "${BLUE}Scanning for packages...${NC}"
for package_dir in "$EXTERNAL_PACKAGES"/*; do
    if [ -d "$package_dir" ]; then
        package_name=$(basename "$package_dir")
        debug "Processing package directory: $package_name"
        log "Found package: $package_name"
        process_directory "$package_name"
        debug "Finished processing package: $package_name"
    fi
done
debug "Finished processing all package directories"

# Also process any standalone files in the root
while IFS= read -r -d '' file; do
    rel_path="${file#$EXTERNAL_PACKAGES/}"
    process_file "$rel_path"
done < <(find "$EXTERNAL_PACKAGES" -maxdepth 1 -type f \( -name "*.mk" -o -name "Config.in" -o -name "*.patch" \) -print0)

# Summary
log ""
if [ "$DRYRUN" = true ]; then
    log "${BLUE}=== Preview Summary ===${NC}"
    log "${GREEN}Would copy new files:   $COPIED_NEW${NC}"
    log "${GREEN}Would create patches:   $CREATED_PATCHES${NC}"
    log "${YELLOW}Would skip files:       $SKIPPED${NC}"
    log "${RED}Conflicts detected:     $CONFLICTS${NC}"
else
    log "${BLUE}=== Import Summary ===${NC}"
    log "${GREEN}New files copied:     $COPIED_NEW${NC}"
    log "${GREEN}Patches created:      $CREATED_PATCHES${NC}"
    log "${YELLOW}Files skipped:        $SKIPPED${NC}"
    log "${RED}Conflicts found:      $CONFLICTS${NC}"
fi

log_report ""
log_report "SUMMARY:"
log_report "  New files copied: $COPIED_NEW"
log_report "  Patches created:  $CREATED_PATCHES"
log_report "  Files skipped:    $SKIPPED"
log_report "  Conflicts found:  $CONFLICTS"

if [ $CONFLICTS -gt 0 ]; then
    log ""
    if [ "$DRYRUN" = true ]; then
        log "${RED}⚠️  Conflicts detected! Manual resolution required before import.${NC}"
    else
        log "${RED}⚠️  Conflicts detected! Please review $REPORT_FILE for manual resolution.${NC}"
    fi
    exit 1
else
    log ""
    if [ "$DRYRUN" = true ]; then
        log "${GREEN}✅ Ready to import! Run without --dryrun to proceed.${NC}"
        if [ $CREATED_PATCHES -gt 0 ]; then
            log "${YELLOW}📝 $CREATED_PATCHES patches would be created.${NC}"
        fi
    else
        log "${GREEN}✅ Import completed successfully!${NC}"
        if [ $CREATED_PATCHES -gt 0 ]; then
            log "${YELLOW}📝 $CREATED_PATCHES patches created. These will be applied during the next build.${NC}"
        fi
    fi
fi

if [ "$DRYRUN" = false ]; then
    log ""
    log "📄 Full report saved to: $REPORT_FILE"
fi

