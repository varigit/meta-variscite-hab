inherit var-hab
FILESEXTRAPATHS_prepend_hab := "${THISDIR}/${PN}:"
FILESEXTRAPATHS_prepend_hab := "${THISDIR}/../../recipes-bsp/imx-mkimage/imx-boot-hab:"

SRC_URI_append_hab = " \
    file://var-genIVT \
    file://var-default.csf \
    file://align_image.sh \
    file://mx8_create_csf.sh \
    file://mx8_template.csf \
    "

# Define SIGN_DTB to authenticate device tree
# Optional: imx8m family
# Required: imx8qm and imx8qxp
SIGN_DTB_mx8qm ?= "${B}/${KERNEL_OUTPUT_DIR}/dts/freescale/imx8qm-var-som-lvds.dtb"
SIGN_DTB_mx8x ?= "${B}/${KERNEL_OUTPUT_DIR}/dts/freescale/imx8qxp-var-som-symphony-sd.dtb"

LOAD_ADDR_KERNEL_mx8m ?= "0x40480000"
LOAD_ADDR_DTB_mx8m ?= "0x43000000"
LOAD_ADDR_KERNEL_mx8 ?= "0x80280000"
LOAD_ADDR_DTB_mx8 ?= "0x83000000"

MKIMG_SOC_mx8qm="QM"
MKIMG_SOC_mx8x="QX"

# Generate HAB block for a file
# Inputs: Start Address, File Path
# Outputs: "<start address> 0x0 <file size> <relative path to file>"
create_hab_block() {
    START_ADDR=$1
    FILE_PATH=$2
    FILE_PATH_RELATIVE=$(realpath --relative-to=${WORKDIR} $2)
    FILE_SIZE=$(printf "0x%08x\n" `stat -c "%s" ${FILE_PATH}`)
    BLOCK=$(printf "0x%08x 0x%08x 0x%08x \"%s\"" "${START_ADDR}" "0x0" "${FILE_SIZE}" "${FILE_PATH_RELATIVE}")
    echo ${BLOCK}
}

create_csf_habv4() {
    CSF=$1

    # Copy Template
    cp ${WORKDIR}/var-default.csf ${CSF}

    # Update keys from template
    sed -i "s|CST_SRK|$(realpath --relative-to=${WORKDIR} ${CST_SRK})|g" ${CSF}
    sed -i "s|CST_CSF_CERT|$(realpath --relative-to=${WORKDIR} ${CST_CSF_CERT})|g" ${CSF}
    sed -i "s|CST_IMG_CERT|$(realpath --relative-to=${WORKDIR} ${CST_IMG_CERT})|g" ${CSF}

    # Add Block(s)
    # --- Add kernel block:
    HAB_BLOCK_KERNEL=$(create_hab_block  ${LOAD_ADDR_KERNEL} ${B}/${KERNEL_OUTPUT_DIR}/Image_pad_ivt)

    # --- Add device tree block (Optional):
    if [ -n "${SIGN_DTB}" ]; then
        if [ ! -f "${SIGN_DTB}" ]; then
            bbfatal "${SIGN_DTB} not found"
        fi

        # Append ", \" to kernel block for proper syntax
        HAB_BLOCK_KERNEL="${HAB_BLOCK_KERNEL}, \\"

        # Pad DTB
        ${WORKDIR}/align_image.sh ${SIGN_DTB}
        cp ${SIGN_DTB}-pad ${SIGN_DTB}

        # Add DTB block
        HAB_BLOCK_DTB=$(create_hab_block  ${LOAD_ADDR_DTB} ${SIGN_DTB})
    fi

    # --- Write blocks to CSF file:
    echo "    Blocks = ${HAB_BLOCK_KERNEL}" >> ${CSF}
    echo "             ${HAB_BLOCK_DTB}" >> ${CSF}
}

# Follows "Authenticating the OS container" from:
# https://github.com/varigit/uboot-imx/blob/imx_v2020.04_5.4.24_2.1.0_var02/doc/imx/ahab/guides/mx8_mx8x_secure_boot.txt
do_sign_kernel_ahab() {
    MKIMG="${DEPLOY_DIR_IMAGE}/imx-boot-tools/mkimage_imx8"
    MKIMG_LOG="${WORKDIR}/mkimage.log"
    IMG=${B}/${KERNEL_OUTPUT_DIR}/Image

    # Generate the OS container image
    ${MKIMG} -soc ${MKIMG_SOC} -rev B0 -c -ap ${IMG} a35 ${LOAD_ADDR_KERNEL} \
        --data ${SIGN_DTB} ${LOAD_ADDR_DTB} -out ${WORKDIR}/flash_os.bin > ${MKIMG_LOG}

    TARGET="linux_container"

    # Sign u-boot-atf-container.img, so flash.bin will use the signed version
    bbnote "${WORKDIR}/mx8_create_csf.sh -t ${TARGET}"
    CST_SRK="$(realpath --relative-to=${WORKDIR} ${CST_SRK})" \
    CST_KEY="$(realpath --relative-to=${WORKDIR} ${CST_KEY})" \
    CST_BIN="$(realpath --relative-to=${WORKDIR} ${CST_BIN})" \
    IMAGE="$(realpath --relative-to=${WORKDIR} ${WORKDIR}/flash_os.bin)" \
    LOG_MKIMAGE="${MKIMG_LOG}" \
    ${WORKDIR}/mx8_create_csf.sh -t ${TARGET}

    # Rename to os_cntr_signed.bin expected by U-Boot bootcmd
    mv ${WORKDIR}/flash_os.bin-signed ${WORKDIR}/os_cntr_signed.bin
}

# Follows "Authenticating additional boot images" from:
# https://github.com/varigit/uboot-imx/blob/imx_v2020.04_5.4.24_2.1.0_var02/doc/imx/habv4/guides/mx8m_secure_boot.txt
do_sign_kernel_habv4() {
    IMG_ADDR=${LOAD_ADDR_KERNEL}
    IMG=${B}/${KERNEL_OUTPUT_DIR}/Image
    IMG_NAME=$(basename ${IMG})
    LOGFILE=${WORKDIR}/${IMG_NAME}.log

    # Read kernel image size:
    IMG_SIZE=$(od -x -j 0x10 -N 0x4 --endian=little ${IMG} | awk 'NR==1 { print "0x"$3 $2 }')

    # Pad kernel image:
    objcopy -I binary -O binary --pad-to ${IMG_SIZE} --gap-fill=0x00 ${IMG} ${IMG}_pad

    # Generate IVT:
    (cd ${WORKDIR} && ./var-genIVT ${LOAD_ADDR_KERNEL} `printf "0x%x" ${IMG_SIZE}`)

    # Append the ivt.bin at the end of the padded Image:
    cat ${IMG}_pad ${WORKDIR}/ivt.bin > ${IMG}_pad_ivt

    # Create csf for signing
    create_csf_habv4 ${IMG}.csf

    # Create signature
    cd ${WORKDIR} && ${CST_BIN} -i ${IMG}.csf -o ${IMG}.csf.bin

    # Attach signature to Image_signed
	cat ${IMG}_pad_ivt ${IMG}.csf.bin > ${IMG}_signed

    # Create final signed Image.gz
    gzip -f ${IMG}_signed
    cp ${IMG}_signed.gz ${IMG}.gz

    # Manually authenticate:
    # u-boot> hab_auth_img ${IMG_ADDR} $filesize ${IMG_SIZE}
}

# Empty function for when hab override not defined
do_sign_kernel() {
    if [ -n "${HAB_VER}" ]; then
        do_sign_kernel_${HAB_VER}
    fi
}

do_install_append_hab() {
    # Install os_cntr_signed.bin for ahab SoCs
    if [ "ahab" = "${HAB_VER}" ]; then
        install -d ${D}/${KERNEL_IMAGEDEST}
        install -m 0644 ${WORKDIR}/os_cntr_signed.bin \
            ${D}/${KERNEL_IMAGEDEST}/os_cntr_signed.bin-${KERNEL_VERSION}
        ln -sf os_cntr_signed.bin-${KERNEL_VERSION} ${D}/${KERNEL_IMAGEDEST}/os_cntr_signed.bin
    fi
}

addtask sign_kernel after do_compile before do_deploy
# Depend on ${DEPLOY_DIR_IMAGE}/imx-boot-tools/mkimage_imx8
do_sign_kernel[depends] = "imx-boot:do_deploy"

FILES_${KERNEL_PACKAGE_NAME}-image_mx8qm_hab += "/boot/os_cntr_signed.bin*"
FILES_${KERNEL_PACKAGE_NAME}-image_mx8x_hab += "/boot/os_cntr_signed.bin*"
