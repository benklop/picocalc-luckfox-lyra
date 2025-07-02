# Example Package Set

This directory demonstrates how to create a package set that can be applied during the build process using the `--package-set` flag.

## Structure

A package set should mirror the structure of the base SDK directory. For example:

```
example-package-set/
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

Apply this package set during build:

```bash
./build.sh --package-set ./example-package-set all
```

## File Types

- **Regular files**: Copied directly to the SDK directory
- **`.patch` files**: Applied as patches to corresponding files in the SDK
  - Example: `buildroot/package/Config.in.patch` will be applied to `buildroot/package/Config.in`

## Creating Package Sets

1. **Add new packages**: Create directories under `buildroot/package/`
2. **Modify existing files**: Create `.patch` files for changes
3. **Add kernel modules**: Place source files in appropriate `kernel-6.1/` subdirectories
4. **Update configurations**: Include patches for configuration files

## Development and Testing

### Testing Package Sets

When developing a package set, use these commands to test and debug:

```bash
# Test package set application
./build.sh --package-set ./example-package-set buildroot-shell

# Test specific packages from the set
./build.sh --package-set ./example-package-set buildroot-make:my-custom-package-dirclean
./build.sh --package-set ./example-package-set buildroot-make:my-custom-package
```

### Development Workflow

1. **Create the package set structure** following the example above
2. **Test package set application**:
   ```bash
   ./build.sh --package-set ./my-package-set buildroot-shell
   # Verify files were copied and patches applied
   ```
3. **Test individual packages**:
   ```bash
   # Inside buildroot-shell:
   make my-custom-package-extract
   make my-custom-package-build
   ```
4. **Iterate and refine** until packages build successfully

### Debugging Package Set Issues

- **Check file copying**: Verify files are in expected locations in the SDK
- **Test patch application**: Look for patch rejection messages during build
- **Use interactive shell**: `buildroot-shell` to examine the environment
- **Test incrementally**: Add packages one at a time to isolate issues

### BuildRoot Development Commands

All standard BuildRoot commands work with package sets:

```bash
# Build specific packages
./build.sh --package-set ./my-set buildroot-make:package-name

# Clean and rebuild
./build.sh --package-set ./my-set buildroot-make:package-name-dirclean
./build.sh --package-set ./my-set buildroot-make:package-name

# Interactive configuration
./build.sh --package-set ./my-set buildroot-config
./build.sh --package-set ./my-set kernel-config
```

See the main [README.md](../README.md) and [ADDING_PACKAGES.md](../ADDING_PACKAGES.md) for detailed development workflows.

## Best Practices

- Use descriptive names for package sets (e.g., `gaming-packages`, `development-tools`)
- Keep package sets focused on specific functionality
- Document dependencies and requirements
- Test package sets independently before distribution
