# Adding Packages to Buildroot

This document explains how to add new packages to the Buildroot configuration using the overlay and patching system.

## Overview

The PicoCalc SDK uses an overlay system that:
1. **Copies files** from `/base/` to the SDK (excluding `.patch` files)
2. **Applies patches** from `.patch` files to modify existing SDK files
3. **Supports git-style patches** for easy generation and maintenance

## Adding a New Package

### Step 1: Create the Package Directory

Create a new directory for your package in the overlay:

```bash
mkdir -p base/buildroot/package/your-package-name
```

### Step 2: Create Package Configuration (`Config.in`)

Create `base/buildroot/package/your-package-name/Config.in`:

```kconfig
config BR2_PACKAGE_YOUR_PACKAGE_NAME
	bool "your-package-name"
	depends on BR2_LINUX_KERNEL  # Add dependencies as needed
	help
	  Brief description of your package.
	  
	  Add more detailed information here about what the package
	  does, any special requirements, etc.
	  
	  https://github.com/user/your-package-repo

comment "your-package-name needs a Linux kernel to be built"
	depends on !BR2_LINUX_KERNEL  # Mirror the dependencies above
```

### Step 3: Create Package Makefile (`package.mk`)

Create `base/buildroot/package/your-package-name/your-package-name.mk`:

```makefile
################################################################################
#
# your-package-name
#
################################################################################

YOUR_PACKAGE_NAME_VERSION = v1.0.0
YOUR_PACKAGE_NAME_SITE = $(call github,user,repo,$(YOUR_PACKAGE_NAME_VERSION))
YOUR_PACKAGE_NAME_LICENSE = GPL-2.0
YOUR_PACKAGE_NAME_LICENSE_FILES = COPYING

# For kernel modules, add:
YOUR_PACKAGE_NAME_MODULE_MAKE_OPTS = CONFIG_YOUR_MODULE=m

# For kernel modules, configure required kernel options:
define YOUR_PACKAGE_NAME_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WIRELESS)
	# Add other required kernel config options
endef

# For packages that need firmware installation:
define YOUR_PACKAGE_NAME_INSTALL_FIRMWARE
	$(INSTALL) -D -m 644 $(@D)/firmware/firmware.bin \
		$(TARGET_DIR)/lib/firmware/firmware.bin
endef
YOUR_PACKAGE_NAME_POST_INSTALL_TARGET_HOOKS += YOUR_PACKAGE_NAME_INSTALL_FIRMWARE

# Choose the appropriate evaluation:
$(eval $(kernel-module))     # For kernel modules
$(eval $(generic-package))   # For all packages
```

### Step 4: Create Patch to Add Package to Menu

You need to patch the main `package/Config.in` file to include your package in the configuration menu.

#### Method 1: Generate Patch with Git (Recommended)

1. Make a temporary copy of the SDK's `package/Config.in`:
```bash
cp SDK/Lyra-SDK/buildroot/package/Config.in /tmp/Config.in.orig
```

2. Edit the file to add your package entry:
```bash
# Find the appropriate section and add:
source "package/your-package-name/Config.in"
```

3. Generate the patch:
```bash
diff -u /tmp/Config.in.orig SDK/Lyra-SDK/buildroot/package/Config.in > base/buildroot/package/Config.in.patch
```

#### Method 2: Create Patch Manually

Create `base/buildroot/package/Config.in.patch`:

```diff
--- a/buildroot/package/Config.in
+++ b/buildroot/package/Config.in
@@ -XXX,6 +XXX,7 @@
 	source "package/existing-package/Config.in"
+	source "package/your-package-name/Config.in"
 	source "package/another-package/Config.in"
```

**Important**: Replace `XXX` with the actual line numbers where you want to insert your package.

### Step 5: Package Categories

Add your package to the appropriate category in `Config.in`:

- **Audio and video applications** (line ~17)
- **Compressors and decompressors** (line ~61)
- **Debugging, profiling and benchmark** (line ~80)
- **Development tools** (line ~120)
- **Filesystem and flash utilities** (line ~200)
- **Games** (line ~250)
- **Graphic libraries and applications** (line ~290)
- **Hardware handling** (line ~620) ← **RTL WiFi drivers go here**
- **Interpreter languages and scripting** (line ~1150)
- **Libraries** (line ~1400)
- **Miscellaneous applications** (line ~2070)
- **Networking applications** (line ~2379)
- **Package managers** (line ~2650)
- **Real-Time** (line ~2670)
- **Security** (line ~2700)
- **System tools** (line ~2750)
- **Text editors and viewers** (line ~2850)

### Step 6: Test the Build

1. **Build the container**:
```bash
./setup.sh
```

2. **Configure Buildroot**:
```bash
# The container will start automatically
make menuconfig
# Navigate to your package and enable it
```

3. **Build the system**:
```bash
make
```

## Example: RTL8188FU WiFi Driver

Here's a complete example of how the RTL8188FU driver was added:

### File Structure
```
base/buildroot/package/
├── rtl8188fu/
│   ├── Config.in              # Package configuration
│   └── rtl8188fu.mk          # Build rules
└── Config.in.patch           # Adds package to main menu
```

### Config.in
```kconfig
config BR2_PACKAGE_RTL8188FU
	bool "rtl8188fu"
	depends on !BR2_s390x
	depends on BR2_LINUX_KERNEL
	help
	  A standalone driver for the RTL8188FU USB Wi-Fi adapter.
	  This driver provides support for Realtek RTL8188FU chipset 
	  USB WiFi dongles.

	  Make sure your target kernel has the CONFIG_WIRELESS_EXT
	  config option enabled.

	  Note: this package needs a firmware loading mechanism to load
	  the binary blob for the chip to work.

	  https://github.com/kelebek333/rtl8188fu

comment "rtl8188fu needs a Linux kernel to be built"
	depends on !BR2_s390x
	depends on !BR2_LINUX_KERNEL
```

### rtl8188fu.mk
```makefile
################################################################################
#
# rtl8188fu
#
################################################################################

RTL8188FU_VERSION = 5573b7e5c35b06de982b07ee3c29dd7c19b4cfde
RTL8188FU_SITE = $(call github,kelebek333,rtl8188fu,$(RTL8188FU_VERSION))
RTL8188FU_LICENSE = GPL-2.0, proprietary (rtl8188fufw.bin firmware blob)
RTL8188FU_LICENSE_FILES = COPYING
RTL8188FU_MODULE_MAKE_OPTS = CONFIG_RTL8188FU=m

define RTL8188FU_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WIRELESS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CFG80211)
	$(call KCONFIG_ENABLE_OPT,CONFIG_USB_SUPPORT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_USB)
endef

define RTL8188FU_INSTALL_FIRMWARE
	$(INSTALL) -D -m 644 $(@D)/firmware/rtl8188fufw.bin \
		$(TARGET_DIR)/lib/firmware/rtlwifi/rtl8188fufw.bin
endef
RTL8188FU_POST_INSTALL_TARGET_HOOKS += RTL8188FU_INSTALL_FIRMWARE

$(eval $(kernel-module))
$(eval $(generic-package))
```

### Config.in.patch
```diff
--- a/buildroot/package/Config.in
+++ b/buildroot/package/Config.in
@@ -627,6 +627,7 @@
 	source "package/rs485conf/Config.in"
 	source "package/rtc-tools/Config.in"
 	source "package/rtl8188eu/Config.in"
+	source "package/rtl8188fu/Config.in"
 	source "package/rtl8189es/Config.in"
 	source "package/rtl8189fs/Config.in"
 	source "package/rtl8192eu/Config.in"
```

## Tips and Best Practices

### 1. Package Naming
- Use lowercase with hyphens: `my-package-name`
- Make variable names uppercase with underscores: `MY_PACKAGE_NAME`

### 2. Dependencies
- Always specify dependencies accurately in `Config.in`
- Mirror dependencies in the `comment` section
- Use `depends on` for hard requirements
- Use `select` sparingly and only for libraries

### 3. Version Management
- Pin to specific commits/tags for reproducibility
- Use git commit hashes for development versions
- Use semantic version tags when available

### 4. Licensing
- Always specify the license correctly
- Include `LICENSE_FILES` pointing to license files
- For mixed licenses, list all components

### 5. Testing
- Test package builds in isolation
- Verify dependencies are correctly specified
- Test on clean build environments

## Development and Testing Workflow

### Interactive Development Commands

Use these commands during package development for testing and debugging:

```bash
# Clean and rebuild specific packages
./build.sh buildroot-make:your-package-dirclean   # Complete cleanup
./build.sh buildroot-make:your-package            # Build package

# Interactive development environment
./build.sh buildroot-shell                        # Open BuildRoot shell
./build.sh buildroot-config                       # Configure BuildRoot interactively
./build.sh kernel-config                          # Configure kernel interactively
```

### Step-by-Step Development Process

1. **Create your package files** as described above
2. **Add to BuildRoot menu** with Config.in patch
3. **Test package extraction**:
   ```bash
   ./build.sh buildroot-shell
   make your-package-extract
   ls build/your-package-*/  # Examine extracted source
   ```
4. **Test patch application**:
   ```bash
   make your-package-patch
   # Check if patches applied successfully
   ```
5. **Test compilation**:
   ```bash
   make your-package-build
   # Fix any compilation issues
   ```
6. **Clean rebuild test**:
   ```bash
   exit  # Exit BuildRoot shell
   ./build.sh buildroot-make:your-package-dirclean
   ./build.sh buildroot-make:your-package
   ```

### Debugging Package Issues

#### Examine Build Environment
```bash
./build.sh buildroot-shell
cd build/your-package-*/          # Go to extracted source
less ../../your-package/.stamp_*  # Check build stamps
cat config.log                    # Check configuration issues (if autotools)
```

#### Common BuildRoot Make Targets
```bash
# Inside buildroot-shell or via buildroot-make:
make your-package-extract          # Extract source only
make your-package-patch            # Apply patches only  
make your-package-configure        # Configure only
make your-package-build            # Build only
make your-package-install          # Install to staging
make your-package-install-target   # Install to target
make your-package-dirclean         # Complete cleanup
make your-package-rebuild          # Clean and rebuild
```

#### Package Information Commands
```bash
make your-package-show-depends     # Show dependencies
make your-package-show-info        # Show package information  
make printvars VARS=your-package   # Show package variables
```

### Testing Patches

When developing patches for existing packages:

1. **Extract the package source**:
   ```bash
   ./build.sh buildroot-shell
   make rtl8188fu-extract  # Example with RTL8188FU
   cd build/rtl8188fu-*/
   ```

2. **Make your changes manually** and test compilation

3. **Generate the patch**:
   ```bash
   # After making changes, create a patch
   cd build/rtl8188fu-*
   git init && git add . && git commit -m "Original"
   # Make your changes
   git add . && git commit -m "Fix compilation"
   git format-patch HEAD~1
   ```

4. **Test the patch**:
   ```bash
   # Copy patch to package directory, then:
   make rtl8188fu-dirclean
   make rtl8188fu-patch  # Test patch application
   make rtl8188fu-build  # Test compilation
   ```

### Advanced Development Tips

- **Use `V=1`** for verbose output: `make your-package V=1`
- **Preserve build directory** during development: Don't use `dirclean` until testing is complete
- **Check file installation**: Use `find host/ staging/ target/ -name "*your-package*"` to verify installation
- **Monitor build logs**: Build output shows configure and compile commands
- **Test cross-compilation**: Ensure package builds for target architecture

See [BuildRoot Manual - Package Build Steps](https://buildroot.org/downloads/manual/manual.html#pkg-build-steps) for complete reference.

## Troubleshooting

### Patch Application Fails
- Check that patch paths are correct (use git-style `a/` and `b/` prefixes)
- Verify line numbers match the current SDK version
- Ensure patch applies to the correct SDK version

### Package Not Visible in Menu
- Check that the patch to `Config.in` was applied correctly
- Verify dependencies are satisfied
- Look for syntax errors in `Config.in`

### Build Failures
- Check variable naming consistency (uppercase with underscores)
- Verify all required fields are present in the `.mk` file
- Check kernel configuration requirements for kernel modules

### Module Loading Issues
- Ensure firmware files are installed to correct locations
- Check kernel configuration for required options
- Verify module dependencies and load order

## Reference Documentation

- [Buildroot Manual - Adding Packages](https://buildroot.org/downloads/manual/manual.html#adding-packages)
- [Buildroot Package Guidelines](https://buildroot.org/downloads/manual/manual.html#writing-rules-mk)
- [Kernel Module Integration](https://buildroot.org/downloads/manual/manual.html#_infrastructure_for_packages_building_kernel_modules)
