################################################################################
#
# Chessboard
#
################################################################################

CHESSBOARD_VERSION = 6b461aabeb14d2e55fa891b6d955ca54d5f850c1
CHESSBOARD_SITE= https://github.com/hpsaturn/chessboard
CHESSBOARD_SITE_METHOD = git

CHESSBOARD_INSTALL_STAGING = YES

CHESSBOARD_DEPENDENCIES = host-pkgconf extra-cmake-modules sdl2

$(eval $(cmake-package))
