LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit spsdk hab deploy mx8-fuse-commands-helper

DEPENDS += " \
    bc-native \
    var-cst-signer-native \
    var-hab-certs \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# This package aggregates output deployed by other packages,
# so set the appropriate dependencies
do_compile[depends] += " \
    var-hab-certs:do_deploy \
"

BOOT_IMAGE_SD = "imx-boot-${MACHINE}-sd.bin-${SIGNED_TARGET}"
BOOT_TOOLS = "imx-boot-tools"
BOOT_NAME = "imx-boot"

UBOOT_IMAGE = "signed-${BOOT_IMAGE_SD}"

# Signs the imx-boot image. This command assumes that the PKI tree was generated.
do_sign_boot_image() {
    bbnote "Signing boot image"

    SIGNDIR="${S}"
}

do_sign_boot_image:append:ahab() {
    # Use user defined keys
    install -m 0755 ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/spsdk_ahab.yaml.sample ${SIGNDIR}/spsdk.yaml
}

do_sign_boot_image:append() {
    # Check if SD image is available
    if [ ! -e "${SIGNDIR}/${BOOT_IMAGE_SD}" ]; then
        bbfatal 'imx-boot SD image is not available to sign'
    fi
    # Generate signed image using cst_signer
    ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/imx_signer -d -i ${SIGNDIR}/${BOOT_IMAGE_SD} -c ${SIGNDIR}/spsdk.yaml
    if [ ! -e "${SIGNDIR}/${UBOOT_IMAGE}" ]; then
        bbfatal 'Image signing failed'
    fi
}

do_compile:append() {
    do_sign_boot_image
}

do_deploy:append() {
    # Copy signed image to DEPLOYDIR and link it to boot image
    if [ -e "${S}/${UBOOT_IMAGE}" ]; then
        install -m 0644 ${S}/${UBOOT_IMAGE} ${DEPLOYDIR}/${UUU_BOOTLOADER}
    else
        bbfatal "ERROR: Could not deploy U-Boot Signed image"
    fi
}

addtask do_deploy after do_compile

COMPATIBLE_MACHINE = "(mx8qm-generic-bsp|mx8qxp-generic-bsp|mx93-generic-bsp|mx91-generic-bsp)"
