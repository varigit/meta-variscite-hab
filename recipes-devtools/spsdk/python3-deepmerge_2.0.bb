SUMMARY = "Toolset for deeply merging Python dictionaries"
HOMEPAGE = "https://github.com/toumorokoshi/deepmerge"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=5461efe2d19ce359c7d72d7be3c05e1c"

inherit pypi python_setuptools_build_meta

SRC_URI[sha256sum] = "5c3d86081fbebd04dd5de03626a0607b809a98fb6ccba5770b62466fe940ff20"

DEPENDS += "python3-setuptools-scm-native"

BBCLASSEXTEND = "native"
