################################################################################
#
# extra-cmake-modules
#
################################################################################

EXTRA_CMAKE_MODULES_VERSION = 6.13.0
EXTRA_CMAKE_MODULES_SITE = https://github.com/KDE/extra-cmake-modules/archive/refs/tags
EXTRA_CMAKE_MODULES_SOURCE = v$(EXTRA_CMAKE_MODULES_VERSION).tar.gz
# EXTRA_CMAKE_MODULES_LICENSE = BSD-3-Clause
# EXTRA_CMAKE_MODULES_LICENSE_FILES = COPYING-CMAKE-SCRIPTS

EXTRA_CMAKE_MODULES_DEPENDENCIES = host-pkgconf
EXTRA_CMAKE_MODULES_INSTALL_STAGING = YES
EXTRA_CMAKE_MODULES_INSTALL_TARGET = NO

EXTRA_CMAKE_MODULES_CONF_OPTS += \
	-DBUILD_HTML_DOCS=OFF \
	-DBUILD_MAN_DOCS=OFF \
	-DBUILD_QTHELP_DOCS=OFF

HOST_EXTRA_CMAKE_MODULES_CONF_OPTS += \
	-DBUILD_HTML_DOCS=OFF \
	-DBUILD_MAN_DOCS=OFF \
	-DBUILD_QTHELP_DOCS=OFF

$(eval $(cmake-package))
$(eval $(host-cmake-package))
