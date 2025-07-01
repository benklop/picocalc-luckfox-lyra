################################################################################
#
# python-sympy
#
################################################################################

PYTHON_SYMPY_VERSION = 1.13.3
PYTHON_SYMPY_SOURCE = sympy-$(PYTHON_SYMPY_VERSION).tar.gz
PYTHON_SYMPY_SITE = https://github.com/sympy/sympy/releases/download/$(PYTHON_SYMPY_VERSION)
#PYTHON_SYMPY_LICENSE = MIT
#PYTHON_SYMPY_LICENSE_FILES = LICENSE.txt
PYTHON_SYMPY_SETUP_TYPE = setuptools
PYTHON_SYMPY_DEPENDENCIES = python-mpmath

$(eval $(python-package))
