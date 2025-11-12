################################################################################
#
# Chessboard
#
################################################################################

CHESSBOARD_VERSION = 789bc8ce7d704f3dee3067e6f425467eb7158c3d
CHESSBOARD_SITE= https://github.com/hpsaturn/chessboard
CHESSBOARD_SITE_METHOD = git

#CHESSBOARD_VERSION = local
#CHESSBOARD_SITE= $(TOPDIR)/../chessboard
#CHESSBOARD_SITE_METHOD = local

CHESSBOARD_INSTALL_STAGING = YES

CHESSBOARD_DEPENDENCIES = host-pkgconf extra-cmake-modules sdl2 yaml-cpp

$(eval $(cmake-package))
