################################################################################
#
# libzim
#
################################################################################

LIBZIM_VERSION = 9.3.0
LIBZIM_SITE = $(call github,openzim,libzim,$(LIBZIM_VERSION))
LIBZIM_SOURCE = libzim-$(LIBZIM_VERSION).tar.gz
LIBZIM_LICENSE = GPL-2.0+
LIBZIM_LICENSE_FILES = COPYING
LIBZIM_INSTALL_STAGING = YES

LIBZIM_DEPENDENCIES = xz zstd

ifeq ($(BR2_PACKAGE_LIBZIM_XAPIAN),y)
LIBZIM_DEPENDENCIES += xapian icu
LIBZIM_CONF_OPTS += -Dwith_xapian=true
else
LIBZIM_CONF_OPTS += -Dwith_xapian=false
endif

LIBZIM_CONF_OPTS += \
	-Dstatic-linkage=false \
	-Dtests=false \
	-Dexamples=false \
	-Ddoc=false

$(eval $(meson-package))
