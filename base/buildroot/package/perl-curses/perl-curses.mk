################################################################################
#
# perl-curses
#
################################################################################

PERL_CURSES_VERSION = 1.45
PERL_CURSES_SOURCE = Curses-$(PERL_CURSES_VERSION).tar.gz
PERL_CURSES_SITE = $(BR2_CPAN_MIRROR)/authors/id/G/GI/GIRAFFED
PERL_CURSES_DEPENDENCIES = perl ncurses
PERL_CURSES_LICENSE = Artistic or GPL-1.0+
PERL_CURSES_LICENSE_FILES = README

# perl-curses needs access to curses.h and ncurses libraries
PERL_CURSES_CONF_ENV = \
	CURSES_LIBTYPE=ncurses \
	CURSES_LDFLAGS="-L$(STAGING_DIR)/usr/lib -lncurses" \
	CURSES_CFLAGS="-I$(STAGING_DIR)/usr/include"

$(eval $(perl-package))
