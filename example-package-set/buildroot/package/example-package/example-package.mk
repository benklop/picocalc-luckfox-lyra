################################################################################
#
# example-package
#
################################################################################

EXAMPLE_PACKAGE_VERSION = 1.0.0
EXAMPLE_PACKAGE_SITE = $(call github,user,example-package,v$(EXAMPLE_PACKAGE_VERSION))
EXAMPLE_PACKAGE_LICENSE = MIT
EXAMPLE_PACKAGE_LICENSE_FILES = LICENSE

# Example of a simple package that just installs a script
define EXAMPLE_PACKAGE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/example-script $(TARGET_DIR)/usr/bin/example-script
endef

$(eval $(generic-package))
