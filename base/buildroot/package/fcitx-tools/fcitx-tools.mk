################################################################################
#
# fcitx tools
#
################################################################################

FCITX_TOOLS_VERSION = 4.2.9.9
FCITX_TOOLS_SOURCE = $(FCITX_TOOLS_VERSION).tar.gz
FCITX_TOOLS_SITE = https://github.com/fcitx/fcitx/archive/refs/tags
HOST_FCITX_TOOLS_CONF_OPTS = -DENABLE_X11=OFF -DENABLE_CARIO=OFF -DENABLE_PANGO=OFF -DENABLE_XKB=OFF -DENABLE_GTK2_IM_MODULE=OFF -DENABLE_QT=OFF -DENABLE_QT_IM_MODULE=OFF -DENABLE_QT_GUI=OFF -DENABLE_OPENCC=OFF -DENABLE_SNOOPER=OFF -DENABLE_GIR=OFF -DENABLE_XDGAUTOSTART=OFF -DENABLE_SPELL=OFF -DENABLE_GETTEXT=ON

FCITX_TOOLS_DEPENDENCIES = host-pkgconf host-extra-cmake-modules
# FCITX_TOOLS_DEPENDENCIES = host-pkgconf host-dbus host-gettext host-extra-cmake-modules host-libxkbcommon

$(eval $(host-cmake-package))
