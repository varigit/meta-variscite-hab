SUMMARY = "NXP Secure Provisioning SDK"
HOMEPAGE = "https://github.com/nxp-mcuxpresso/spsdk"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=863e3c0c79e2589ac9d16c3918e115d1"

SRC_URI += " \
    file://0001-relax-build-dependency-versions.patch \
    file://0002-build-only-the-AHAB-nxpimage-command.patch \
"

SRC_URI[sha256sum] = "33c29db757a9576190bb888e0479f8b3da2ee7f7ab01f3f5374450156f42bc64"

DEPENDS += " \
    python3-click-command-tree-native \
    python3-click-native \
    python3-colorama-native \
    python3-crcmod-native \
    python3-cryptography-native \
    python3-deepmerge-native \
    python3-fastjsonschema-native \
    python3-filelock-native \
    python3-hexdump-native \
    python3-libusbsio-native \
    python3-platformdirs-native \
    python3-prettytable-native \
    python3-pyserial-native \
    python3-pyyaml-native \
    python3-requests-native \
    python3-ruamel-yaml-native \
    python3-setuptools-scm-native \
    python3-sly-native \
    python3-typing-extensions-native \
"

inherit pypi python_setuptools_build_meta

BBCLASSEXTEND = "native"
