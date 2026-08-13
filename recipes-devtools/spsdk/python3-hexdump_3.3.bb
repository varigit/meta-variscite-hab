SUMMARY = "Hexadecimal dump utility and library"
HOMEPAGE = "https://bitbucket.org/techtonik/hexdump/"
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://README.txt;beginline=203;endline=205;md5=cc7323808d67dfd14f4064a091a649d0"

PYPI_PACKAGE_EXT = "zip"

inherit pypi python_setuptools_build_meta

S = "${UNPACKDIR}"

SRC_URI[sha256sum] = "d781a43b0c16ace3f9366aade73e8ad3a7bd5137d58f0b45ab2d3f54876f20db"

BBCLASSEXTEND = "native"
