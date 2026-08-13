SUMMARY = "Sly Lex Yacc"
HOMEPAGE = "https://github.com/dabeaz/sly"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit pypi python_setuptools_build_meta

SRC_URI[sha256sum] = "251d42015e8507158aec2164f06035df4a82b0314ce6450f457d7125e7649024"

BBCLASSEXTEND = "native"
