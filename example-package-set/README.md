# Example Overlay

This directory demonstrates how to create a overlay that can be applied during the build process using the `--overlay` flag.

## Structure

A overlay should mirror the structure of the base SDK directory. For example:

```
example-overlay/
├── buildroot/
│   └── package/
│       ├── my-custom-package/
│       │   ├── Config.in
│       │   └── my-custom-package.mk
│       └── Config.in.patch         # Patch to add new package to main menu
├── kernel-6.1/
│   └── drivers/
│       └── my-driver/
│           ├── my-driver.c
│           └── Makefile
└── README.md
```

## Usage

Apply this overlay during build:

```bash
./build.sh --overlay ./example-overlay all
```

## File Types

- **Regular files**: Copied directly to the SDK directory
- **`.patch` files**: Applied as patches to corresponding files in the SDK
  - Example: `buildroot/package/Config.in.patch` will be applied to `buildroot/package/Config.in`

## Creating Overlays

1. **Add new packages**: Create directories under `buildroot/package/`
2. **Modify existing files**: Create `.patch` files for changes
3. **Add kernel modules**: Place source files in appropriate `kernel-6.1/` subdirectories
4. **Update configurations**: Include patches for configuration files

## Development and Testing

### Testing Overlays

When developing a overlay, use these commands to test and debug:

```bash
# Test overlay application
./build.sh --overlay ./example-overlay buildroot-shell

# Test specific packages from the set
./build.sh --overlay ./example-overlay buildroot-make:my-custom-package-dirclean
./build.sh --overlay ./example-overlay buildroot-make:my-custom-package
```

### Development Workflow

1. **Create the overlay structure** following the example above
2. **Test overlay application**:
   ```bash
   ./build.sh --overlay ./my-overlay buildroot-shell
   # Verify files were copied and patches applied
   ```
3. **Test individual packages**:
   ```bash
   # Inside buildroot-shell:
   make my-custom-package-extract
   make my-custom-package-build
   ```
4. **Iterate and refine** until packages build successfully

### Debugging Overlay Issues

- **Check file copying**: Verify files are in expected locations in the SDK
- **Test patch application**: Look for patch rejection messages during build
- **Use interactive shell**: `buildroot-shell` to examine the environment
- **Test incrementally**: Add packages one at a time to isolate issues

### BuildRoot Development Commands

All standard BuildRoot commands work with overlays:

```bash
# Build specific packages
./build.sh --overlay ./my-set buildroot-make:package-name

# Clean and rebuild
./build.sh --overlay ./my-set buildroot-make:package-name-dirclean
./build.sh --overlay ./my-set buildroot-make:package-name

# Interactive configuration
./build.sh --overlay ./my-set buildroot-config
./build.sh --overlay ./my-set kernel-config
```

See the main [README.md](../README.md) and [ADDING_PACKAGES.md](../ADDING_PACKAGES.md) for detailed development workflows.

## Best Practices

- Use descriptive names for overlays (e.g., `gaming-packages`, `development-tools`)
- Keep overlays focused on specific functionality
- Document dependencies and requirements
- Test overlays independently before distribution
