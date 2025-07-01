################################################################################
#
# fcitx-fbterm
#
################################################################################

FCITX_FBTERM_VERSION = 0.2.0
FCITX_FBTERM_SOURCE = $(FCITX_FBTERM_VERSION).tar.gz
FCITX_FBTERM_SITE = https://github.com/fcitx/fcitx-fbterm/archive/refs/tags
FCITX_FBTERM_CONF_OPTS = -Dstagingdir=$(STAGING_DIR)

FCITX_FBTERM_DEPENDENCIES = host-pkgconf dbus gettext fcitx

$(eval $(cmake-package))
