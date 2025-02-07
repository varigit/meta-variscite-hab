LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit cst hab deploy mx8-fuse-commands-helper

DEPENDS += " \
    bc-native \
    linux-variscite \
    var-cst-signer-native \
    var-hab-certs \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_compile[depends] += "linux-variscite:do_deploy"

BOOT_IMAGE_SD = "imx-boot-${MACHINE}-sd.bin-${SIGNED_TARGET}"
BOOT_TOOLS = "imx-boot-tools"
BOOT_NAME = "imx-boot"

UBOOT_IMAGE = "signed-${BOOT_IMAGE_SD}"

KERNEL_LOAD_ADDR:mx93-generic-bsp ?= "0x80400000"
KERNEL_LOAD_ADDR:mx8qm-generic-bsp ?= "0x80200000"
KERNEL_LOAD_ADDR:mx8qxp-generic-bsp ?= "0x80200000"

DTB_LOAD_ADDR:mx93-generic-bsp ?= "0x83000000"
DTB_LOAD_ADDR:mx8qm-generic-bsp ?= "0x83000000"
DTB_LOAD_ADDR:mx8qxp-generic-bsp ?= "0x83000000"

CNTR_IMX_FLAGS:mx8qxp-generic-bsp ?= "-soc QX -rev B0"
CNTR_IMX_FLAGS:mx8qm-generic-bsp ?= "-soc QX -rev B0"

CORTEX_ARCH_FLAG:mx8qxp-generic-bsp ?= "a35"
CORTEX_ARCH_FLAG:mx8qm-generic-bsp ?= "a53"

# Signs the imx-boot image. This command assumes that the PKI tree was generated.
do_sign_boot_image() {
    bbnote "Signing boot image"

    SIGNDIR="${S}"
}

do_sign_boot_image:append:ahab() {
    # Use user defined keys
    install -m 0755 ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/csf_ahab.cfg.sample ${SIGNDIR}/csf.cfg
}

do_sign_boot_image:append() {
    # Check if SD image is available
    if [ ! -e "${SIGNDIR}/${BOOT_IMAGE_SD}" ]; then
        bbfatal 'imx-boot SD image is not available to sign'
    fi
    # Generate signed image using cst_signer
    CST_PATH=${CST_PATH} ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/cst_signer -d -i ${SIGNDIR}/${BOOT_IMAGE_SD} -c ${SIGNDIR}/csf.cfg
    if [ ! -e "${SIGNDIR}/signed-${BOOT_IMAGE_SD}" ]; then
        bbfatal 'Image signing failed'
    fi
}

# Signs the kernel image.
do_sign_kernel_image() {
    bbnote "Signing kernel image"

    SIGNDIR="${S}/kernel-sign-dir"

    if [ ! -d "${SIGNDIR}" ]; then
        mkdir "${SIGNDIR}"
    fi
}

do_sign_kernel_image:append:ahab() {
    # Use user defined keys
    install -m 0755 ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/csf_ahab.cfg.sample ${SIGNDIR}/csf.cfg
}

do_sign_kernel_image:append:ahab() {
    # Copy kernel images to BOOT_STAGING to build kernel container image
    cp ${DEPLOY_DIR_IMAGE}/Image ${SIGNDIR}/Image
    cp ${DEPLOY_DIR_IMAGE}/${KERNEL_DTB_DEFAULT} ${SIGNDIR}/${KERNEL_DTB_DEFAULT}

    # Invoke mkimage again to Get container info
    ${S}/mkimage_imx8 \
        ${CNTR_IMX_FLAGS} \
        -c -ap ${SIGNDIR}/Image \
        ${CORTEX_ARCH_FLAG} ${KERNEL_LOAD_ADDR} \
        --data ${SIGNDIR}/${KERNEL_DTB_DEFAULT} \
        ${CORTEX_ARCH_FLAG} ${DTB_LOAD_ADDR} \
        -out ${SIGNDIR}/flash_os.bin
}

do_sign_kernel_image:append:ahab() {
    # Generate signed kernel and dtb image using cst_signer
    CST_PATH=${CST_PATH} ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/cst_signer -d -i ${SIGNDIR}/flash_os.bin -c ${SIGNDIR}/csf.cfg

    mv ${S}/signed-flash_os.bin ${S}/os_cntr_signed.bin
}

do_compile:append() {
    do_sign_boot_image
    do_sign_kernel_image
}

do_deploy:append() {
    # Copy signed image to DEPLOYDIR and link it to boot image
    if [ -e "${S}/signed-${BOOT_IMAGE_SD}" ]; then
        install -m 0644 ${S}/signed-${BOOT_IMAGE_SD} ${DEPLOYDIR}/${UUU_BOOTLOADER}
    else
        bbfatal "ERROR: Could not deploy U-Boot Signed image"
    fi

    if [ -e "${S}/os_cntr_signed.bin" ]; then
        install -m 0644 ${S}/os_cntr_signed.bin ${DEPLOYDIR}
    else
        bbfatal "Could not deploy Kernel Signed image"
    fi
}

addtask do_deploy after do_compile

COMPATIBLE_MACHINE = "(mx8qm-generic-bsp|mx8qxp-generic-bsp|mx9-generic-bsp)"
