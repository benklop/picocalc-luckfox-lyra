GLKTERM_VERSION = townba
GLKTERM_BRANCH = main-townba
GLKTERM_SOURCE = glkterm-$(GLKTERM_BRANCH).tar.gz
GLKTERM_SITE = https://github.com/$(GLKTERM_VERSION)/glkterm/archive/refs/heads/$(GLKTERM_BRANCH).tar.gz
GLKTERM_LICENSE = MIT
GLKTERM_LICENSE_FILES = LICENSE
GLKTERM_DEPENDENCIES = host-pkgconf ncurses zlib \
    sdl2 sdl2_mixer

# Gargoyle interpreters
GARGLK_SITE = https://github.com/garglk/garglk.git
GARGLK_VERSION = master
GARGLK_SUBDIR = $(BUILD_DIR)/garglk-$(GARGLK_VERSION)

define GLKTERM_EXTRACT_GARGLK
    rm -rf $(GARGLK_SUBDIR)
    git clone --depth 1 --branch $(GARGLK_VERSION) $(GARGLK_SITE) $(GARGLK_SUBDIR)
    $(PATCH) $(GARGLK_SUBDIR)/terps < $(GLKTERM_PKGDIR)/0001-use-glkterm-instead-of-garglk.patch
endef

GLKTERM_POST_EXTRACT_HOOKS += GLKTERM_EXTRACT_GARGLK

define GLKTERM_BUILD_CMDS
    $(MAKE) -C $(@D) # build glkterm itself
    # Build selected interpreters
ifeq ($(BR2_PACKAGE_GLKTERM_ADVSYS),y)
	GLKTERM_WITH_ADVSYS=1
else
	GLKTERM_WITH_ADVSYS=0
endif
endif
ifeq ($(BR2_PACKAGE_GLKTERM_AGILITY),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/agility
endif
ifeq ($(BR2_PACKAGE_GLKTERM_ALAN2),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/alan2
endif
ifeq ($(BR2_PACKAGE_GLKTERM_ALAN3),y)
    $(MAKE) -C $(GARGLK_SUBDIR)/terps/alan3
endif
ifeq ($(BR2_PACKAGE_GLKTERM_BOCFEL),y)
    $(MAKE) -C $(GARGLK_SUBDIR)/terps/bocfel
endif
ifeq ($(BR2_PACKAGE_GLKTERM_GLULXE),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/glulxe
endif
ifeq ($(BR2_PACKAGE_GLKTERM_GIT),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/git
endif
ifeq ($(BR2_PACKAGE_GLKTERM_HUGO),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/hugo
endif
ifeq ($(BR2_PACKAGE_GLKTERM_JACL),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/jacl
endif
ifeq ($(BR2_PACKAGE_GLKTERM_LEVEL9),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/level9
endif
ifeq ($(BR2_PACKAGE_GLKTERM_MAGNETIC),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/magnetic
endif
ifeq ($(BR2_PACKAGE_GLKTERM_PLUS),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/plus
endif
ifeq ($(BR2_PACKAGE_GLKTERM_SCARE),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/scare
endif
ifeq ($(BR2_PACKAGE_GLKTERM_SCOTT),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/scott
endif
ifeq ($(BR2_PACKAGE_GLKTERM_TADS),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/tads
endif
ifeq ($(BR2_PACKAGE_GLKTERM_TAYLOR),y)
	$(MAKE) -C $(GARGLK_SUBDIR)/terps/taylor
endif

endef

define GLKTERM_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/glkterm $(TARGET_DIR)/usr/bin/glkterm
ifeq ($(BR2_PACKAGE_GLKTERM_ADVSYS),y)
    $(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/advsys/advsys $(TARGET_DIR)/usr/bin/advsys
endif
ifeq ($(BR2_PACKAGE_GLKTERM_AGILITY),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/agility/agility $(TARGET_DIR)/usr/bin/agility
endif
ifeq ($(BR2_PACKAGE_GLKTERM_ALAN2),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/alan2/alan2 $(TARGET_DIR)/usr/bin/alan2
endif
ifeq ($(BR2_PACKAGE_GLKTERM_ALAN3),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/alan3/alan3 $(TARGET_DIR)/usr/bin/alan3
endif
ifeq ($(BR2_PACKAGE_GLKTERM_BOCFEL),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/bocfel/bocfel $(TARGET_DIR)/usr/bin/bocfel
endif
ifeq ($(BR2_PACKAGE_GLKTERM_GLULXE),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/glulxe/glulxe $(TARGET_DIR)/usr/bin/glulxe
endif
ifeq ($(BR2_PACKAGE_GLKTERM_GIT),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/git/git $(TARGET_DIR)/usr/bin/git
endif
ifeq ($(BR2_PACKAGE_GLKTERM_HUGO),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/hugo/hugo $(TARGET_DIR)/usr/bin/hugo
endif
ifeq ($(BR2_PACKAGE_GLKTERM_JACL),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/jacl/jacl $(TARGET_DIR)/usr/bin/jacl
endif
ifeq ($(BR2_PACKAGE_GLKTERM_LEVEL9),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/level9/level9 $(TARGET_DIR)/usr/bin/level9
endif
ifeq ($(BR2_PACKAGE_GLKTERM_MAGNETIC),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/magnetic/magnetic $(TARGET_DIR)/usr/bin/magnetic
endif
ifeq ($(BR2_PACKAGE_GLKTERM_PLUS),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/plus/plus $(TARGET_DIR)/usr/bin/plus
endif
ifeq ($(BR2_PACKAGE_GLKTERM_SCARE),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/scare/scare $(TARGET_DIR)/usr/bin/scare
endif
ifeq ($(BR2_PACKAGE_GLKTERM_SCOTT),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/scott/scott $(TARGET_DIR)/usr/bin/scott
endif
ifeq ($(BR2_PACKAGE_GLKTERM_TADS),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/tads/tads $(TARGET_DIR)/usr/bin/tads
endif
ifeq ($(BR2_PACKAGE_GLKTERM_TAYLOR),y)
	$(INSTALL) -D -m 0755 $(GARGLK_SUBDIR)/terps/taylor/taylor $(TARGET_DIR)/usr/bin/taylor
endif

endef

$(eval $(generic-package))