SUMMARY = "Package to install os boot container required by ahab mechanism"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "imx-boot"

do_install[depends] += "imx-boot:do_deploy"
do_install:ahab() {
    install -Dm 0644 ${DEPLOY_DIR_IMAGE}/os_cntr_signed.bin ${D}/boot/os_cntr_signed.bin
}

PACKAGE_ARCH = "${MACHINE_ARCH}"

FILES:${PN} = "/boot"
