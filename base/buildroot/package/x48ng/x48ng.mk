################################################################################
#
# x48ng
#
################################################################################

X48NG_VERSION = 43dae7322141627cd1792ef151eaa80884c6c114
X48NG_SITE = https://github.com/gwenhael-le-moine/x48ng.git
X48NG_SITE_METHOD = git
X48NG_LICENSE = GPL2
X48NG_LICENSE_FILES = COPYING
X48NG_DEPENDENCIES = ncurses readline lua
HTOP_CONF_ENV = HTOP_NCURSES_CONFIG_SCRIPT=$(STAGING_DIR)/usr/bin/$(NCURSES_CONFIG_SCRIPTS)

# Dependencies from .github/workflows/c-cpp.yml
X48NG_DEPENDENCIES = \
  ncurses \
  readline \
  lua
# Build flags with explicit include paths
X48NG_MAKE_OPTS = \
  WITH_X11=no \
  HAS_X11=0 \
  PREFIX=/usr \
  CC="$(TARGET_CC)" \
  CFLAGS="$(TARGET_CFLAGS) -mfloat-abi=hard -I$(STAGING_DIR)/usr/include" \
  LDFLAGS="$(TARGET_LDFLAGS) -mfloat-abi=hard" \
  PKG_CONF_PATH="$(PKG_CONFIG_HOST_BINARY)" \
  PKG_CONFIG_SYSROOT_DIR="$(STAGING_DIR)" \
  PKG_CONFIG_PATH="$(STAGING_DIR)/usr/lib/pkgconfig" \

# Build command
define X48NG_BUILD_CMDS
    $(X48NG_MAKE_ENV) $(MAKE) -C $(@D) $(X48NG_MAKE_OPTS)
endef

# Install command
define X48NG_INSTALL_TARGET_CMDS
    $(X48NG_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) $(X48NG_MAKE_OPTS) install
endef

$(eval $(generic-package))
