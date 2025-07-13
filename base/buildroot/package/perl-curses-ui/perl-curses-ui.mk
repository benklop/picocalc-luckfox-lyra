################################################################################
#
# perl-curses-ui
#
################################################################################

PERL_CURSES_UI_VERSION = 0.9609
PERL_CURSES_UI_SOURCE = Curses-UI-$(PERL_CURSES_UI_VERSION).tar.gz
PERL_CURSES_UI_SITE = $(BR2_CPAN_MIRROR)/authors/id/M/MD/MDXI
PERL_CURSES_UI_DEPENDENCIES = perl perl-curses
PERL_CURSES_UI_LICENSE = perl5
PERL_CURSES_UI_LICENSE_FILES = README

$(eval $(perl-package))
