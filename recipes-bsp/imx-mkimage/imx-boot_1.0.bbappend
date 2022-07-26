inherit var-hab
FILESEXTRAPATHS:prepend := "${THISDIR}/imx-boot-hab:"

DEPENDS:hab += "\
    bc-native \
    util-linux-native \
    "

IMX_BOOT_REV:hab="6745ccdcf15384891639b7ced3aa6ce938682365"
IMX_BOOT_REV:hab:mx8mp-nxp-bsp="5138add7602a50d1730a54d0b67219f0ce0666b4"

SRC_URI:append:imx8qxp-var-som:hab = " file://0001-soc.mak-imx8-ahab-Use-u-boot-atf-container.img.signe.patch"
SRC_URI:append:imx8qm-var-som:hab = " file://0001-soc.mak-imx8-ahab-Use-u-boot-atf-container.img.signe.patch"

SRC_URI:append:hab += " \
    file://mx8m_create_csf.sh \
    file://mx8m_template.csf \
    file://mx8_create_csf.sh \
    file://mx8_template.csf \
    file://mx8_create_fuse_commands.sh \
    "

UBOOT_DTBS ?= "${UBOOT_DTB_NAME}"
UBOOT_DTBS:mx8mm-nxp-bsp ?= "imx8mm-var-dart-customboard.dtb imx8mm-var-som-symphony.dtb"
UBOOT_DTBS:mx8mp-nxp-bsp ?= "imx8mp-var-dart-dt8mcustomboard.dtb imx8mp-var-dart-dt8mcustomboard-legacy.dtb imx8mp-var-som-symphony.dtb"
UBOOT_DTBS_TARGET ?= "dtbs"

# Name of the image to include in final image
# e.g. imx-boot-imx8mn-var-som-sd.bin-flash_ddr4_evk-signed
UBOOT_DTB_DEFAULT ?= ""
UBOOT_DTB_DEFAULT:mx8mm-nxp-bsp ?= "-imx8mm-var-som-symphony"
UBOOT_DTB_DEFAULT:mx8mp-nxp-bsp ?= "-imx8mp-var-som-symphony"

sign_uboot_atf_container_ahab() {
    TARGET=$1
    IMAGE=$2
    LOG_MKIMAGE="${BOOT_STAGING}/${TARGET}.log"

    # Create u-boot-atf-container.img
    compile_${SOC_FAMILY}
    make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} ${UBOOT_DTBS_TARGET}=${UBOOT_DTB_NAME} ${TARGET} > ${LOG_MKIMAGE} 2>&1

    # Create u-boot-atf-container.img-signed for flash.bin image
    CST_SRK="${CST_SRK}" \
    CST_KEY="${CST_KEY}" \
    CST_BIN="${CST_BIN}" \
    IMAGE="${IMAGE}" \
    LOG_MKIMAGE="${LOG_MKIMAGE}" \
    ${WORKDIR}/mx8_create_csf.sh -t ${TARGET}
}

sign_flash_ahab() {
    TARGET=$1
    LOG_MKIMAGE_PREFIX="${S}/$2"

    # Sign u-boot-atf-container.img, so flash.bin will use the signed version
    bbnote "${WORKDIR}/mx8_create_csf.sh -t ${TARGET}"
    CST_SRK="${CST_SRK}" \
    CST_KEY="${CST_KEY}" \
    CST_BIN="${CST_BIN}" \
    IMAGE="${BOOT_STAGING}/flash.bin" \
    LOG_MKIMAGE="${LOG_MKIMAGE_PREFIX}.log" \
    ${WORKDIR}/mx8_create_csf.sh -t ${TARGET}
    bbnote "cp ${BOOT_STAGING}/flash.bin-signed ${S}/${BOOT_CONFIG_MACHINE}-${TARGET}-signed"
    cp ${BOOT_STAGING}/flash.bin-signed ${S}/${BOOT_CONFIG_MACHINE}-${TARGET}-signed
}

sign_flash_habv4() {
    TARGET=$1
    LOG_MKIMAGE_PREFIX="${B}/$2"

    # Generate csf spl and fit files
    CST_SRK="${CST_SRK}" \
    CST_CSF_CERT="${CST_CSF_CERT}" \
    CST_IMG_CERT="${CST_IMG_CERT}" \
    CST_BIN="${CST_BIN}" \
    IMXBOOT="${S}/${BOOT_CONFIG_MACHINE}-${TARGET}" \
    LOG_MKIMAGE="${LOG_MKIMAGE_PREFIX}.log" \
    LOG_PRINT_FIT_HAB="${LOG_MKIMAGE_PREFIX}.hab" \
    ${WORKDIR}/mx8m_create_csf.sh -t ${TARGET}

    offset_spl="$(cat ${LOG_MKIMAGE_PREFIX}.log | grep " csf_off" | awk '{print $NF}')"
    offset_fit="$(cat ${LOG_MKIMAGE_PREFIX}.log | grep " sld_csf_off" | awk '{print $NF}')"

    # Copy imx-boot image
    IMG_ORIG="${S}/${BOOT_CONFIG_MACHINE}-${TARGET}"
    IMG_SIGNED="${S}/${BOOT_CONFIG_MACHINE}-${TARGET}-signed"
    cp ${IMG_ORIG} ${IMG_SIGNED}

    # Insert SPL and FIT Signatures
    dd if=${WORKDIR}/${TARGET}-csf-spl.bin of=${IMG_SIGNED} seek=$(printf "%d" ${offset_spl}) bs=1 conv=notrunc
    dd if=${WORKDIR}/${TARGET}-csf-fit.bin of=${IMG_SIGNED} seek=$(printf "%d" ${offset_fit}) bs=1 conv=notrunc
}

do_deploy:append:hab() {
    # Deploy imx-boot images
    for target in ${IMXBOOT_TARGETS}; do
        for UBOOT_DTB in ${UBOOT_DTBS}; do
            if [ "$(echo ${UBOOT_DTBS} | wc -w)" -gt "1" ]; then
                DTB_SUFFIX="-${UBOOT_DTB%.*}"
            else
                DTB_SUFFIX=""
            fi
            # Deploy signed imx-boot image for each U-Boot Device Tree
            install -m 0644 ${S}/${BOOT_CONFIG_MACHINE}-${target}${DTB_SUFFIX}-signed \
                ${DEPLOYDIR}/${BOOT_CONFIG_MACHINE}-${target}${DTB_SUFFIX}
        done
        # Deploy default signed imx-boot image for sdcard image
        install -m 0644 ${S}/${BOOT_CONFIG_MACHINE}-${target}${UBOOT_DTB_DEFAULT}-signed \
            ${DEPLOYDIR}/${BOOT_CONFIG_MACHINE}-${target}
    done

    # Deploy U-Boot Fuse Commands
    install -m 0644 ${WORKDIR}/$(basename ${CST_SRK_FUSE}).u-boot-cmds ${DEPLOYDIR}
}

do_compile:hab() {

    # Copy TEE binary to SoC target folder to mkimage
    if ${DEPLOY_OPTEE}; then
        cp ${DEPLOY_DIR_IMAGE}/tee.bin ${BOOT_STAGING}
    fi

    for target in ${IMXBOOT_TARGETS}; do
        for UBOOT_DTB in ${UBOOT_DTBS}; do
            # If UBOOT_DTBS has more then one dtb, include in imx-boot filename
            # Currently, for imx8m, hab only supports a single U-Boot proper dtb
            if [ "$(echo ${UBOOT_DTBS} | wc -w)" -gt "1" ]; then
                DTB_SUFFIX="-${UBOOT_DTB%.*}"
            else
                DTB_SUFFIX=""
            fi
            compile_${SOC_FAMILY}

            # Prepare log file name
            MKIMAGE_LOG="mkimage-${target}${DTB_SUFFIX}"

            # mx8qm-nxp-bsp|mx8x: Sign u-boot-atf-container.img, so flash.bin will use the signed version
            if [ "${SOC_FAMILY}" = "mx8" ] || [ "${SOC_FAMILY}" = "mx8x" ]; then
                sign_uboot_atf_container_ahab u-boot-atf-container.img  ${BOOT_STAGING}/u-boot-atf-container.img
            fi

            bbnote "building ${IMX_BOOT_SOC_TARGET} - ${REV_OPTION} ${target}"
            make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} ${UBOOT_DTBS_TARGET}=${UBOOT_DTB} ${target} > ${MKIMAGE_LOG}.log 2>&1

            # mx8m: run print_fit_hab
            if [ "${SOC_FAMILY}" = "mx8m" ]; then
                # Create print_fit_hab log for create_csf.sh
                cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/*.dtb   ${BOOT_STAGING}
                make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} ${UBOOT_DTBS_TARGET}=${UBOOT_DTB} print_fit_hab > ${MKIMAGE_LOG}.hab 2>&1
            fi

            if [ -e "${BOOT_STAGING}/flash.bin" ]; then
                cp ${BOOT_STAGING}/flash.bin ${S}/${BOOT_CONFIG_MACHINE}-${target}${DTB_SUFFIX}
                cp ${BOOT_STAGING}/flash.bin ${S}/${BOOT_CONFIG_MACHINE}-${target}
            fi

            sign_flash_${HAB_VER} "${target}${DTB_SUFFIX}" "${MKIMAGE_LOG}"
        done
    done

    # Generate file with instructions for programming fuses
    ${WORKDIR}/mx8_create_fuse_commands.sh ${SOC_FAMILY} ${CST_SRK_FUSE} "${WORKDIR}/$(basename ${CST_SRK_FUSE}).u-boot-cmds"
}
