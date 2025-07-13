################################################################################
#
# rtl8xxxu
#
################################################################################

# Use a specific commit to ensure reproducible builds
RTL8XXXU_VERSION = eb876f4950951af00e062677ddbfdfc05fa2b4df
RTL8XXXU_SITE = https://github.com/a5a5aa555oo/rtl8xxxu/archive
RTL8XXXU_SOURCE = $(RTL8XXXU_VERSION).tar.gz
RTL8XXXU_LICENSE = GPL-2.0, proprietary (rtl8188fufw.bin firmware blob)
RTL8XXXU_LICENSE_FILES = COPYING
RTL8XXXU_MODULE_MAKE_OPTS = CONFIG_RTL8XXXU=m

define RTL8XXXU_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WIRELESS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CFG80211)
	$(call KCONFIG_ENABLE_OPT,CONFIG_MAC80211)
	$(call KCONFIG_ENABLE_OPT,CONFIG_USB_SUPPORT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_USB)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WIRELESS_EXT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WEXT_CORE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WEXT_PROC)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WEXT_SPY)
	$(call KCONFIG_ENABLE_OPT,CONFIG_WEXT_PRIV)
endef

define RTL8XXXU_INSTALL_FIRMWARE
	$(INSTALL) -d $(TARGET_DIR)/lib/firmware/rtlwifi
	$(INSTALL) -m 644 $(@D)/firmware/*.bin \
		$(TARGET_DIR)/lib/firmware/rtlwifi/
	$(INSTALL) -m 644 $(@D)/firmware/LICENCE.rtlwifi_firmware.txt \
		$(TARGET_DIR)/lib/firmware/rtlwifi/
endef
RTL8XXXU_POST_INSTALL_TARGET_HOOKS += RTL8XXXU_INSTALL_FIRMWARE

$(eval $(kernel-module))
$(eval $(generic-package))
