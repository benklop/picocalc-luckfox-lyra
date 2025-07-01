################################################################################
#
# tmux
#
################################################################################

CMATRIX_VERSION = 2.0
#CMATRIX_SOURCE = cmatrix-v$(CMATRIX_VERSION)-Butterscotch.tar
CMATRIX_SOURCE = v$(CMATRIX_VERSION).tar.gz
CMATRIX_SITE = https://github.com/abishekvashok/cmatrix/archive/refs/tags

#CMATRIX_CONF_OPTS += --cross-prefix=/home/luckfox/luckfox-lyra-sdk-250311/prebuilts/gcc/linux-x86/arm/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf- --cpu=armv7 --enable-static

CMATRIX_AUTORECONF = YES
CMATRIX_DEPENDENCIES += ncurses

$(eval $(autotools-package))
