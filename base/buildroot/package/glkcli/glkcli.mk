################################################################################
#
# glkcli
#
################################################################################

GLKCLI_VERSION = main
GLKCLI_SITE = https://github.com/benklop/glkcli.git
GLKCLI_SITE_METHOD = git
GLKCLI_LICENSE = MIT
GLKCLI_LICENSE_FILES = LICENSE
GLKCLI_DEPENDENCIES = glkterm

# Use the cargo package infrastructure for Rust projects
$(eval $(cargo-package))
