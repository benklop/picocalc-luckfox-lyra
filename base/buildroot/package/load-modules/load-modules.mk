################################################################################
#
# load-modules baed on:
# https://unix.stackexchange.com/a/396581/42216
#
################################################################################

LOAD_MODULES_VERSION = 1.0
LOAD_MODULES_SITE = 
LOAD_MODULES_SOURCE = 
LOAD_MODULES_LICENSE = Public Domain
LOAD_MODULES_LICENSE_FILES = 


define LOAD_MODULES_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(LOAD_MODULES_PKGDIR)/S02modules \
		$(TARGET_DIR)/etc/init.d/S02modules
	$(INSTALL) -D -m 0644 $(LOAD_MODULES_PKGDIR)/functions \
		$(TARGET_DIR)/etc/sysconfig/functions
	# Generate modules file with header
	echo "# Module auto-loading configuration" > $(TARGET_DIR)/etc/sysconfig/modules
	echo "# " >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# This file contains a list of kernel modules to load at boot time." >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# One module per line, with optional arguments." >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# Lines starting with # are comments and are ignored." >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# Empty lines are also ignored." >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "#" >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# Examples:" >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# rtl8188fu" >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# snd-soc-dummy" >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# i2c-dev" >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "#" >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# Note: Module names should not include the .ko extension." >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# Arguments can be provided after the module name, separated by spaces." >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "# Example: module_name param1=value1 param2=value2" >> $(TARGET_DIR)/etc/sysconfig/modules
	echo "" >> $(TARGET_DIR)/etc/sysconfig/modules
	# Add configured modules if any
	$(if $(call qstrip,$(BR2_PACKAGE_LOAD_MODULES_LIST)), \
		echo "$(call qstrip,$(BR2_PACKAGE_LOAD_MODULES_LIST))" | tr ' ' '\n' >> $(TARGET_DIR)/etc/sysconfig/modules)
	chmod 644 $(TARGET_DIR)/etc/sysconfig/modules
endef

$(eval $(generic-package))
