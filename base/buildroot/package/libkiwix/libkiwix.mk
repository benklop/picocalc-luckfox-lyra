################################################################################
#
# libkiwix
#
################################################################################

LIBKIWIX_VERSION = 14.0.0
LIBKIWIX_SITE = $(call github,kiwix,libkiwix,$(LIBKIWIX_VERSION))
LIBKIWIX_SOURCE = libkiwix-$(LIBKIWIX_VERSION).tar.gz
LIBKIWIX_LICENSE = GPL-3.0+
LIBKIWIX_LICENSE_FILES = COPYING
LIBKIWIX_INSTALL_STAGING = YES

LIBKIWIX_DEPENDENCIES = \
	libzim \
	icu \
	pugixml \
	libcurl \
	libmicrohttpd \
	zlib \
	xapian

# Download mustache.hpp header file since it's not packaged
define LIBKIWIX_DOWNLOAD_MUSTACHE
	$(WGET) -O $(@D)/include/mustache.hpp \
		https://raw.githubusercontent.com/kainjow/Mustache/v4.1/mustache.hpp
endef

LIBKIWIX_POST_EXTRACT_HOOKS += LIBKIWIX_DOWNLOAD_MUSTACHE

LIBKIWIX_CONF_OPTS = \
	-Dstatic-linkage=false \
	-Ddoc=false

$(eval $(meson-package))
