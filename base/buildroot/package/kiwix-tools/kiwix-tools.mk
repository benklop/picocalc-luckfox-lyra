################################################################################
#
# kiwix-tools
#
################################################################################

KIWIX_TOOLS_VERSION = 3.7.0
KIWIX_TOOLS_SITE = $(call github,kiwix,kiwix-tools,$(KIWIX_TOOLS_VERSION))
KIWIX_TOOLS_SOURCE = kiwix-tools-$(KIWIX_TOOLS_VERSION).tar.gz
KIWIX_TOOLS_LICENSE = GPL-3.0+
KIWIX_TOOLS_LICENSE_FILES = COPYING

# Dependencies now available in buildroot:
KIWIX_TOOLS_DEPENDENCIES = libzim libkiwix docopt-cpp

KIWIX_TOOLS_CONF_OPTS = \
	-Dstatic-linkage=false \
	-Ddoc=false

# All dependencies are now available and the package should build successfully.

$(eval $(meson-package))
