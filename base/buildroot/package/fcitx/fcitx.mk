################################################################################
#
# fcitx
#
################################################################################

FCITX_VERSION = 4.2.9.9
FCITX_SOURCE = $(FCITX_VERSION).tar.gz
FCITX_SITE = https://github.com/fcitx/fcitx/archive/refs/tags
FCITX_CONF_OPTS = -DENABLE_X11=OFF -DENABLE_CARIO=OFF -DENABLE_PANGO=OFF -DENABLE_XKB=OFF -DENABLE_GTK2_IM_MODULE=OFF -DENABLE_QT=OFF -DENABLE_QT_IM_MODULE=OFF -DENABLE_QT_GUI=OFF -DENABLE_OPENCC=OFF -DENABLE_SNOOPER=OFF -DENABLE_GIR=OFF -DENABLE_XDGAUTOSTART=OFF -DENABLE_SPELL=OFF -DENABLE_GETTEXT=ON -DHOST_DIR=$(HOST_DIR)


FCITX_INSTALL_STAGING = YES

FCITX_DEPENDENCIES = host-pkgconf host-fcitx-tools dbus gettext extra-cmake-modules libxkbcommon

$(eval $(cmake-package))
