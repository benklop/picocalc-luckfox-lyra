################################################################################
#
# ceni
#
################################################################################

CENI_VERSION = 2.33
CENI_SITE = https://github.com/fullstory-morgue/ceni/archive/refs/tags/debian
CENI_SOURCE = $(CENI_VERSION).tar.gz
CENI_LICENSE = GPL-2.0+
CENI_LICENSE_FILES = COPYING
CENI_DEPENDENCIES = perl perl-curses-ui perl-expect perl-term-readkey ifupdown-scripts wpa_supplicant

# Remove files installed outside the target directory
define CENI_REMOVE_MISPLACED_FILES
	rm -rf $(TARGET_DIR)/opt
endef

CENI_POST_INSTALL_TARGET_HOOKS += CENI_REMOVE_MISPLACED_FILES

$(eval $(perl-package))
