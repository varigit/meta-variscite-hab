SUMMARY = "Click plugin for displaying a command tree"
HOMEPAGE = "https://github.com/whwright/click-command-tree"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PYPI_PACKAGE = "click_command_tree"

inherit pypi python_setuptools_build_meta

S = "${UNPACKDIR}/click-command-tree-${PV}"

SRC_URI[sha256sum] = "3e7f5db9f3eccc2eccab40f7979355efe6d5123c958b748dee9c242a38364d6c"

BBCLASSEXTEND = "native"
