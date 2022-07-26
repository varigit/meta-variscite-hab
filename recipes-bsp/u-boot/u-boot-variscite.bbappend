FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:hab = " file://u-boot-hab.cfg"
