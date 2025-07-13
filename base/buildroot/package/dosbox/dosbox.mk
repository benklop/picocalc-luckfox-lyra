################################################################################
#
# DosBox
#
################################################################################

DOSBOX_VERSION = aba5613630b58b960cfb237b184014a4f26c0cb7
DOSBOX_SITE = https://gitlab.com/lmerckx/recalbox-dosbox.git
DOSBOX_SITE_METHOD = git
DOSBOX_LICENSE = GPL2
DOSBOX_LICENSE_FILES = COPYING
DOSBOX_DEPENDENCIES = sdl2 zlib libpng libogg libvorbis sdl2_sound sdl2_net
# DOSBOX_DEPENDENCIES = sdl zlib libpng libogg libvorbis sdl_sound sdl_net
DOSBOX_AUTORECONF = YES

# Use best architecture for ARM boards
# RPI1: armv6l
# all others: armv7l
# Note that for RPI3 and Odroid C2 in true 64bits, it should be aarch64
# ifeq ($(BR2_PACKAGE_RECALBOX_TARGET_RPI1),y)
# DOSBOX_CPU=armv6l
# else
DOSBOX_CPU=armv7l
# endif

#	--enable-unaligned_memory --disable-opengl --with-sdl=sdl2 \

DOSBOX_CONF_OPTS=--enable-core-inline --prefix=/usr --enable-dynrec \
	--enable-unaligned_memory --disable-opengl --with-sdl=sdl2 \
	--with-sdl-prefix="$(STAGING_DIR)/usr" \
	CFLAGS="$(TARGET_CFLAGS) $(COMPILER_COMMONS_CFLAGS_NOLTO)" \
	CXXFLAGS="$(TARGET_CXXFLAGS) $(COMPILER_COMMONS_CXXFLAGS_NOLTO)" \
	CPPFLAGS="$(TARGET_CPPFLAGS) $(COMPILER_COMMONS_CXXFLAGS_NOLTO)" \
	LDFLAGS="$(TARGET_LDFLAGS) $(COMPILER_COMMONS_LDFLAGS_NOLTO)"

define DOSBOX_PATCH_CONFIGURE_CPU
	cd $(@D); $(SED) 's/$(DOSBOX_CPU)/\0|arm/g' configure.ac;
	# ./autogen.sh
endef
DOSBOX_PRE_CONFIGURE_HOOKS += DOSBOX_PATCH_CONFIGURE_CPU

$(eval $(autotools-package))
