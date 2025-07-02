################################################################################
#
# rtl8188fu
#
################################################################################

# Use a specific commit to ensure reproducible builds
RTL8188FU_VERSION = 7ce43037212aab03a5cfe441992eee04de7f858d
RTL8188FU_SITE = https://github.com/kelebek333/rtl8188fu/archive
RTL8188FU_SOURCE = $(RTL8188FU_VERSION).tar.gz
RTL8188FU_LICENSE = GPL-2.0, proprietary (rtl8188fufw.bin firmware blob)
RTL8188FU_LICENSE_FILES = COPYING
RTL8188FU_MODULE_MAKE_OPTS = CONFIG_RTL8188FU=m

define RTL8188FU_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WIRELESS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CFG80211)
	$(call KCONFIG_ENABLE_OPT,CONFIG_USB_SUPPORT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_USB)
endef

define RTL8188FU_INSTALL_FIRMWARE
	$(INSTALL) -D -m 644 $(@D)/firmware/rtl8188fufw.bin \
		$(TARGET_DIR)/lib/firmware/rtlwifi/rtl8188fufw.bin
endef
RTL8188FU_POST_INSTALL_TARGET_HOOKS += RTL8188FU_INSTALL_FIRMWARE

$(eval $(kernel-module))
$(eval $(generic-package))
