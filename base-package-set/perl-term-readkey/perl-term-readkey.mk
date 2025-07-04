################################################################################
#
# perl-term-readkey
#
################################################################################

PERL_TERM_READKEY_VERSION = 2.38
PERL_TERM_READKEY_SOURCE = TermReadKey-$(PERL_TERM_READKEY_VERSION).tar.gz
PERL_TERM_READKEY_SITE = $(BR2_CPAN_MIRROR)/authors/id/J/JS/JSTOWE
PERL_TERM_READKEY_DEPENDENCIES = perl host-qemu
PERL_TERM_READKEY_LICENSE = perl5
PERL_TERM_READKEY_LICENSE_FILES = README

# Redefine perl variables in Makefile to use target perl through qemu
define PERL_TERM_READKEY_POST_CONFIGURE_CMDS
	# First change 'host' to 'target' in path variables
	sed -i '/^XSUBPPDIR = /s/host/target/g' $(@D)/Makefile
	sed -i '/^XSUBPPDEPS = /s/host/target/g' $(@D)/Makefile
	sed -i '/^XSUBPPARGS = /s/host/target/g' $(@D)/Makefile
	# Set PERL and FULLPERL to use qemu with proper library path and PERL5LIB
	
	sed -i 's|^PERL = .*|PERL = PERL5LIB=$(STAGING_DIR)/usr/lib/perl5/5.38.2:$(STAGING_DIR)/usr/lib/perl5/site_perl/5.38.2 $(HOST_DIR)/bin/qemu-arm -L $(STAGING_DIR) $(STAGING_DIR)/usr/bin/perl|' $(@D)/Makefile
	sed -i 's|^FULLPERL = .*|FULLPERL = PERL5LIB=$(STAGING_DIR)/usr/lib/perl5/5.38.2:$(STAGING_DIR)/usr/lib/perl5/site_perl/5.38.2 $(HOST_DIR)/bin/qemu-arm -L $(STAGING_DIR) $(STAGING_DIR)/usr/bin/perl|' $(@D)/Makefile
	# Fix the second FULLPERL definition in the makeaperl section
	sed -i 's|^FULLPERL      = ".*|FULLPERL      = PERL5LIB=$(STAGING_DIR)/usr/lib/perl5/5.38.2:$(STAGING_DIR)/usr/lib/perl5/site_perl/5.38.2 $(HOST_DIR)/bin/qemu-arm -L $(STAGING_DIR) $(STAGING_DIR)/usr/bin/perl|' $(@D)/Makefile
endef

PERL_TERM_READKEY_POST_CONFIGURE_HOOKS += PERL_TERM_READKEY_POST_CONFIGURE_CMDS

define PERL_TERM_READKEY_BUILD_CMDS
	$(TARGET_MAKE_ENV) \
	QEMU_LD_PREFIX=$(STAGING_DIR) \
	PERL5LIB=$(STAGING_DIR)/usr/lib/perl5/5.38.2:$(STAGING_DIR)/usr/lib/perl5/site_perl/5.38.2 \
	$(MAKE) -C $(@D) OPTIMIZE="$(TARGET_CFLAGS)"
endef

$(eval $(perl-package))
