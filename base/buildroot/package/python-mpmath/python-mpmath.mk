################################################################################
#
# python-mpmath
#
################################################################################

PYTHON_MPMATH_VERSION = 1.3.0
PYTHON_MPMATH_SOURCE = $(PYTHON_MPMATH_VERSION).tar.gz
PYTHON_MPMATH_SITE = https://github.com/mpmath/mpmath/archive/refs/tags
#PYTHON_MPMATH_LICENSE = MIT
#PYTHON_MPMATH_LICENSE_FILES = LICENSE.txt
PYTHON_MPMATH_SETUP_TYPE = setuptools

$(eval $(python-package))
