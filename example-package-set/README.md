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

## Best Practices

- Use descriptive names for package sets (e.g., `gaming-packages`, `development-tools`)
- Keep package sets focused on specific functionality
- Document dependencies and requirements
- Test package sets independently before distribution
