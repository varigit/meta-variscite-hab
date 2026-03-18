LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit spsdk hab

SIGNDIR = "${WORKDIR}/kernel-sign-dir"

DEPENDS += " \
    bc-native \
    imx-boot \
    var-cst-signer-native \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# This package aggregates output deployed by other packages,
# so set the appropriate dependencies
do_compile[depends] += " \
    imx-boot:do_deploy \
    var-hab-certs:do_deploy \
"

BOOT_TOOLS = "imx-boot-tools"

KERNEL_LOAD_ADDR:mx93-generic-bsp ?= "0x80400000"
KERNEL_LOAD_ADDR:mx95-generic-bsp ?= "0x90400000"
KERNEL_LOAD_ADDR:mx8qm-generic-bsp ?= "0x80200000"
KERNEL_LOAD_ADDR:mx8qxp-generic-bsp ?= "0x80200000"

DTB_LOAD_ADDR:mx93-generic-bsp ?= "0x83000000"
DTB_LOAD_ADDR:mx95-generic-bsp ?= "0x93000000"
DTB_LOAD_ADDR:mx8qm-generic-bsp ?= "0x83000000"
DTB_LOAD_ADDR:mx8qxp-generic-bsp ?= "0x83000000"

CNTR_IMX_FLAGS:mx93-generic-bsp ?= "-soc IMX9"
CNTR_IMX_FLAGS:mx95-generic-bsp ?= "-soc IMX9 -cntr_version 2"
CNTR_IMX_FLAGS:mx8qxp-generic-bsp ?= "-soc QX -rev B0"
CNTR_IMX_FLAGS:mx8qm-generic-bsp ?= "-soc QX -rev B0"

CORTEX_ARCH_FLAG:mx93-generic-bsp ?=  "a55"
CORTEX_ARCH_FLAG:mx95-generic-bsp ?=  "a55"
CORTEX_ARCH_FLAG:mx8qxp-generic-bsp ?= "a35"
CORTEX_ARCH_FLAG:mx8qm-generic-bsp ?= "a53"

# Signs the kernel image.
do_sign_kernel_image() {
    bbnote "Signing kernel image"

    if [ ! -d "${SIGNDIR}" ]; then
        mkdir "${SIGNDIR}"
    fi
}

do_sign_kernel_image:append:ahab() {
    # Use user defined keys
    install -m 0755 ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/spsdk_ahab.yaml.sample ${SIGNDIR}/spsdk.yaml
}

do_sign_kernel_image:append:ahab() {
    # Copy kernel images to build kernel container image
    cp ${B}/arch/${ARCH}/boot/Image ${SIGNDIR}/Image
    cp ${B}/arch/${ARCH}/boot/dts/freescale/${KERNEL_DTB_DEFAULT} ${SIGNDIR}/${KERNEL_DTB_DEFAULT}

    # Invoke mkimage again to Get container info
    ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/mkimage_imx8 \
        ${CNTR_IMX_FLAGS} \
        -c -ap ${SIGNDIR}/Image \
        ${CORTEX_ARCH_FLAG} ${KERNEL_LOAD_ADDR} \
        --data ${SIGNDIR}/${KERNEL_DTB_DEFAULT} \
        ${CORTEX_ARCH_FLAG} ${DTB_LOAD_ADDR} \
        -out ${SIGNDIR}/flash_os.bin
}

do_sign_kernel_image:append:ahab() {
    # Generate signed kernel and dtb image using signer tool
    ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/imx_signer -d -i ${SIGNDIR}/flash_os.bin -c ${SIGNDIR}/spsdk.yaml

    mv ${B}/signed-flash_os.bin ${SIGNDIR}/os_cntr_signed.bin
}

do_compile:append() {
    do_sign_kernel_image
}

do_install:append() {
    install -Dm 0644 ${SIGNDIR}/os_cntr_signed.bin ${D}/boot/os_cntr_signed.bin
}

do_deploy:append() {
    # Copy signed image to DEPLOYDIR
    if [ -e "${SIGNDIR}/os_cntr_signed.bin" ]; then
        install -m 0644 ${SIGNDIR}/os_cntr_signed.bin ${DEPLOYDIR}
    else
        bbfatal "Could not deploy Kernel Signed image"
    fi
}

PACKAGES:append = " ${KERNEL_PACKAGE_NAME}-image-signed"
FILES:${KERNEL_PACKAGE_NAME}-image-signed = "/boot/os_cntr_signed.bin"
