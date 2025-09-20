# fakeroot-ng Migration Plan

## Current Status
We've successfully migrated most target rootfs operations to use fakeroot-ng instead of sudo. However, there are still many sudo operations in the host environment setup.

## Key Insight
Since we're building in a Docker container (not a real system), we can eliminate most sudo operations:

1. **Mounting operations** (`mount -t proc`, `/sys`, `/dev`) - Not needed in container
2. **Stage3 extraction** - Can use fakeroot-ng instead of sudo
3. **Chroot operations** - Can use fakeroot-ng instead of sudo
4. **File operations** - Already migrated to fakeroot-ng

## Remaining sudo Operations to Migrate

### Host Environment Setup
- `sudo tar xpf "$STAGE3_FILE"` → `fakeroot-ng -- tar xpf "$STAGE3_FILE"`
- `sudo cp /etc/resolv.conf etc/` → `fakeroot-ng -- cp /etc/resolv.conf etc/`
- Remove all mounting operations (not needed in container)

### Crossdev Operations
- All `sudo chroot` → `fakeroot-ng -- chroot`
- All `sudo mkdir` → `fakeroot-ng -- mkdir` or just `mkdir` (since we own the container)
- All `sudo tee` → Direct file writes with fakeroot-ng

### Cleanup Operations
- `sudo rm -rf` → `fakeroot-ng -- rm -rf` or just `rm -rf`
- `sudo umount` → Remove entirely (no mounting in container)

## Benefits
1. **Simpler container setup** - No need for privileged containers
2. **Better permission handling** - fakeroot-ng preserves real ownership
3. **More portable** - Works in restricted environments
4. **Cleaner builds** - No sudo pollution

## Testing Plan
1. First test basic operations without mounting
2. Verify emerge works in unmounted chroot with fakeroot-ng
3. Test complete build process
4. Validate final rootfs ownership and permissions