GARGLK_VERSION = 2023.1
GARGLK_SOURCE = gargoyle-$(GARGLK_VERSION).tar.gz
GARGLK_SITE = https://github.com/garglk/garglk/releases/download/$(GARGLK_VERSION)
GARGLK_LICENSE = GPL-2.0-or-later
GARGLK_LICENSE_FILES = License.txt
GARGLK_DEPENDENCIES = qt5base host-cmake host-pkgconf fontconfig freetype jpeg libpng zlib \
    sdl2 sdl2_mixer
GARGLK_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DQT_QMAKE_PLATFORM="linuxfb:fb=/dev/fb0" \
	-DWITH_FREEDESKTOP=OFF \
	-DWITH_KDE=OFF \
	-DWITH_TTS=DYNAMIC \
	-DSOUND=SDL

$(eval $(cmake-package))