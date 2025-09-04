################################################################################
#
# x48ng
#
################################################################################

X48NG_VERSION = 6a6b912e796f259231e1e42c5e3c7e51a37121e7
X48NG_SITE = https://github.com/hpsaturn/x48ng.git
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

X48NG_MAKE_ENV = \
  WITH_X11=no \
  WITH_SDL2=no \
  PKG_CONFIG_SYSROOT_DIR="$(STAGING_DIR)" \
  PKG_CONFIG_PATH="$(STAGING_DIR)/usr/lib/pkgconfig"

# Build flags with explicit
# the CC definition here fixed this issue:
# https://github.com/gwenhael-le-moine/x48ng/issues/29

X48NG_MAKE_OPTS = \
  WITH_X11=no \
  WITH_SDL2=no \
  HAS_X11=0 \
  PREFIX=/usr \
  CC="$(TARGET_CC)" \
  CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include \
    -O0 -rdynamic \
    -fno-stack-protector \
    -z execstack \
    -D_FILE_OFFSET_BITS=64 \
    -Wno-absolute-value \
    -Wno-sign-compare"
  LDFLAGS="$(TARGET_LDFLAGS) -mfloat-abi=hard" \
  PKG_CONF_PATH="$(PKG_CONFIG_HOST_BINARY)" \
  PKG_CONFIG_SYSROOT_DIR="$(STAGING_DIR)" \
  PKG_CONFIG_PATH="$(STAGING_DIR)/usr/lib/pkgconfig"

define X48NG_BUILD_CMDS
  $(X48NG_MAKE_ENV) $(MAKE) -C $(@D) $(X48NG_MAKE_OPTS)
endef

# Custom install command (some errors with original MakeFile
define X48NG_INSTALL_TARGET_CMDS
  # Install binary
  $(INSTALL) -D -m 0755 $(@D)/dist/x48ng $(TARGET_DIR)/usr/bin/x48ng
  
  # Install icon
  $(INSTALL) -D -m 0644 $(@D)/dist/hplogo.png $(TARGET_DIR)/usr/share/x48ng/hplogo.png
  
  cp -R $(@D)/dist/ROMs/ $(TARGET_DIR)/usr/share/x48ng/
  $(INSTALL) -c -m 755 $(@D)/dist/setup-x48ng-home.sh $(TARGET_DIR)/usr/share/x48ng/setup-x48ng-home.sh
  chmod 755 $(TARGET_DIR)/usr/share/x48ng/setup-x48ng-home.sh
endef

$(eval $(generic-package))
