SUMMARY = "Python wrapper around NXP LIBUSBSIO"
HOMEPAGE = "https://www.nxp.com/"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/BSD-3-Clause;md5=550794465ba0ec5312d6919e203a55f9"

# The PyPI package ships prebuilt libraries for several architectures.
INHIBIT_SYSROOT_STRIP:class-native = "1"

inherit pypi python_setuptools_build_meta

SRC_URI[sha256sum] = "45d521c229413b0835f5acb73e8df3b31aa5055f454f2ddbb490db3b8604292f"

BBCLASSEXTEND = "native"
