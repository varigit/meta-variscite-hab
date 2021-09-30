FILESEXTRAPATHS_prepend := "${THISDIR}/imx-boot-hab:"

DEPENDS_hab += "\
    bc-native \
    util-linux-native \
    "

SRCREV_hab = ""
SRC_URI_hab = "git://source.codeaurora.org/external/imx/imx-mkimage.git;protocol=https;branch=${SRCBRANCH};subdir=git;rev=6745ccdcf15384891639b7ced3aa6ce938682365"
SRC_URI_append_imx8qxp-var-som_hab = " file://0001-soc.mak-imx8-ahab-Use-u-boot-atf-container.img.signe.patch"
SRC_URI_append_imx8qm-var-som_hab = " file://0001-soc.mak-imx8-ahab-Use-u-boot-atf-container.img.signe.patch"
SRC_URI_append_imx8mm-var-dart_hab = " file://0001-imx-mkimage-imx8mm-soc.mak-Add-hab-support.patch"

# NXP CST Utils
# Requires registration, download from https://www.nxp.com/webapp/sps/download/license.jsp?colCode=IMX_CST_TOOL
# Override NXP_CST_URI in local.conf as needed
NXP_CST_URI ?= "file://${HOME}/cst-3.1.0.tgz"
NXP_CST_SHA256 ?= "a8cb42c99e9bacb216a5b5e3b339df20d4c5612955e0c353e20f1bb7466cf222"
SRC_URI_hab += "${NXP_CST_URI};name=cst;subdir=cst"
SRC_URI_hab[cst.sha256sum] = "${NXP_CST_SHA256}"
CST_BIN ?= "${WORKDIR}/cst/release/linux64/bin/cst"

# Override CST_CERTS_URI in local.conf with customer repository:
CST_CERTS_URI ?= "git://github.com/varigit/var-hab-certs.git;protocol=http;branch=master;rev=c5e3314b6cde00d39470817c37c1c1e1a57c3cec"
SRC_URI_append_hab += "${CST_CERTS_URI};name=cst-certs;destsuffix=cst-certs;"

CST_CRT_ROOT_mx8m ?= "${WORKDIR}/cst-certs/iMX8M"
CST_CRT_ROOT_mx8 ?= "${WORKDIR}/cst-certs/iMX8"

# HABv4 Keys
CST_SRK_mx8m ?=      "${CST_CRT_ROOT}/crts/SRK_1_2_3_4_table.bin"
CST_CSF_CERT ?= "${CST_CRT_ROOT}/crts/CSF1_1_sha256_4096_65537_v3_usr_crt.pem"
CST_IMG_CERT ?= "${CST_CRT_ROOT}/crts/IMG1_1_sha256_4096_65537_v3_usr_crt.pem"
CST_SRK_FUSE_mx8m ?= "${CST_CRT_ROOT}/crts/SRK_1_2_3_4_fuse.bin"

# AHAB Keys
CST_SRK_mx8 ?=      "${CST_CRT_ROOT}/crts/SRK1234table.bin"
CST_KEY ?=      "${CST_CRT_ROOT}/crts/SRK1_sha384_4096_65537_v3_usr_crt.pem"
CST_SRK_FUSE_mx8 ?= "${CST_CRT_ROOT}/crts/SRK1234fuse.bin"

# Override in local.conf with customer serial & password
CST_KEYPASS ?= "Variscite_password"
CST_SERIAL ?= "1248163E"

HAB_VER_mx8x="ahab"
HAB_VER_mx8="ahab"
HAB_VER_mx8m="habv4"

SRC_URI_append_hab += " \
    file://mx8m_create_csf.sh \
    file://mx8m_template.csf \
    file://mx8_create_csf.sh \
    file://mx8_template.csf \
    file://mx8_create_fuse_commands.sh \
    "

UBOOT_DTBS ?= "${UBOOT_DTB_NAME}"
UBOOT_DTBS_mx8mm ?= "imx8mm-var-dart-customboard.dtb imx8mm-var-som-symphony.dtb"
UBOOT_DTBS_mx8mp ?= "imx8mp-var-dart-dt8mcustomboard.dtb imx8mp-var-dart-dt8mcustomboard-legacy.dtb imx8mp-var-som-symphony.dtb"
UBOOT_DTBS_TARGET ?= "dtbs"
UBOOT_DTBS_TARGET_mx8mm ?= "dtbs_lpddr4_ddr4_evk"

sign_uboot_atf_container_ahab() {
    TARGET=$1
    IMAGE=$2
    LOG_MKIMAGE="${BOOT_STAGING}/${TARGET}.log"

    # Create u-boot-atf-container.img
    compile_${SOC_FAMILY}
    make SOC=${SOC_TARGET} ${REV_OPTION} ${UBOOT_DTBS_TARGET}=${UBOOT_DTB_NAME} ${TARGET} > ${LOG_MKIMAGE} 2>&1

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

do_deploy_append_hab() {
    # Deploy imx-boot images
    for target in ${IMXBOOT_TARGETS}; do
        for UBOOT_DTB in ${UBOOT_DTBS}; do
            if [ "$(echo ${UBOOT_DTBS} | wc -w)" -gt "1" ]; then
                DTB_SUFFIX="-${UBOOT_DTB%.*}"
            else
                DTB_SUFFIX=""
            fi
            install -m 0644 ${S}/${BOOT_CONFIG_MACHINE}-${target}${DTB_SUFFIX}-signed ${DEPLOYDIR}
        done
    done

    # Deploy U-Boot Fuse Commands
    install -m 0644 ${WORKDIR}/$(basename ${CST_SRK_FUSE}).u-boot-cmds ${DEPLOYDIR}
}

do_compile_hab() {

    # Prepare serial and key_pass files with secrets
    echo "${CST_SERIAL}" > ${CST_CRT_ROOT}/keys/serial
    echo "${CST_KEYPASS}" > ${CST_CRT_ROOT}/keys/key_pass.txt
    echo "${CST_KEYPASS}" >> ${CST_CRT_ROOT}/keys/key_pass.txt

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

            # mx8qm|mx8x: Sign u-boot-atf-container.img, so flash.bin will use the signed version
            if [ "${SOC_FAMILY}" = "mx8" ] || [ "${SOC_FAMILY}" = "mx8x" ]; then
                sign_uboot_atf_container_ahab u-boot-atf-container.img  ${BOOT_STAGING}/u-boot-atf-container.img
            fi

            bbnote "building ${SOC_TARGET} - ${REV_OPTION} ${target}"
            make SOC=${SOC_TARGET} ${REV_OPTION} ${UBOOT_DTBS_TARGET}=${UBOOT_DTB} ${target} > ${MKIMAGE_LOG}.log 2>&1

            # mx8m: run print_fit_hab
            if [ "${SOC_FAMILY}" = "mx8m" ]; then
                # Create print_fit_hab log for create_csf.sh
                cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/*.dtb   ${BOOT_STAGING}
                make SOC=${SOC_TARGET} ${REV_OPTION} ${UBOOT_DTBS_TARGET}=${UBOOT_DTB} print_fit_hab > ${MKIMAGE_LOG}.hab 2>&1
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
