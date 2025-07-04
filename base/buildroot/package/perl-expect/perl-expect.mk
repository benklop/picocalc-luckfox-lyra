################################################################################
#
# perl-expect
#
################################################################################

PERL_EXPECT_VERSION = 1.38
PERL_EXPECT_SOURCE = Expect-$(PERL_EXPECT_VERSION).tar.gz
PERL_EXPECT_SITE = $(BR2_CPAN_MIRROR)/authors/id/J/JA/JACOBY
PERL_EXPECT_DEPENDENCIES = perl
PERL_EXPECT_LICENSE = perl5
PERL_EXPECT_LICENSE_FILES = README

$(eval $(perl-package))
