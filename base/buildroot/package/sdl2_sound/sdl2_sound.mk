################################################################################
#
# sdl2_sound
#
################################################################################

SDL2_SOUND_VERSION = 2.0.2
SDL2_SOUND_SITE = $(call github,icculus,SDL_sound,v$(SDL2_SOUND_VERSION))
SDL2_SOUND_LICENSE = BSD-Like
SDL2_SOUND_LICENSE_FILES = LICENSE.txt
SDL2_SOUND_INSTALL_STAGING = YES
SDL2_SOUND_DEPENDENCIES = sdl2
SDL2_SOUND_CONF_OPTS = \
	-DSDLSOUND_BUILD_STATIC=1

ifneq ($(BR2_ENABLE_LOCALE),y)
SDL2_SOUND_DEPENDENCIES += libiconv
endif

ifeq ($(BR2_PACKAGE_SDL2_SOUND_PLAYSOUND),y)
SDL2_SOUND_CONF_OPTS += -DSDLSOUND_BUILD_TEST=1
else
SDL2_SOUND_CONF_OPTS += -DSDLSOUND_BUILD_TEST=0
endif

$(eval $(cmake-package))
