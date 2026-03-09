LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit cst hab

BOOT_TOOLS = "imx-boot-tools"

KERNEL_LOAD_ADDRESS:mx8m-generic-bsp ?= "0x40480000"

# Signs the kernel image.
do_sign_kernel_image() {
    bbnote "Signing kernel image"

    SIGNDIR="${B}"
}

do_sign_kernel_image:append:hab4() {
    # Only kernel image type Image and zImage are supported by i.MX devices
    if [ ${KERNEL_IMAGETYPE} != "zImage" ] && \
       [ ${KERNEL_IMAGETYPE} != "Image" ] && \
       [ ${KERNEL_IMAGETYPE} != "Image.gz" ]; then
        bbfatal "Unknown kernel image format"
    fi

    if [ "${KERNEL_IMAGETYPE}" = "Image" ] || \
       [ "${KERNEL_IMAGETYPE}" = "Image.gz" ]; then
        IMAGE="${B}/${KERNEL_OUTPUT_DIR}/Image"

        # Get kernel image pad size
        image_pad_size="$(od -An -j 16 -N 4 -i ${IMAGE} | tr -d ' ')"
        # Pad the image
    elif [ "${KERNEL_IMAGETYPE}" = "zImage" ]; then
        IMAGE="${B}/${KERNEL_OUTPUT_DIR}/${KERNEL_IMAGETYPE}"

        # Get kernel image pad size after padding it to next 1K
        image_size="$(stat -L --printf=%s ${IMAGE})"
        image_pad_size="$(expr ${image_size} + $(expr 4096 - $(expr ${image_size} % 4096)))"
    else
        bbfatal "Unknown kernel image format"
    fi

    # Pad the image
    objcopy -I binary -O binary --pad-to "${image_pad_size}" --gap-fill=0x00 ${IMAGE} "${SIGNDIR}/${KERNEL_IMAGETYPE}_pad.bin"

    load_address_hex="${KERNEL_LOAD_ADDRESS}"
    load_address="$(printf "%u" ${load_address_hex})"
    ivt_pointer="$(expr ${load_address} + ${image_pad_size})"
    csf_pointer="$(expr ${ivt_pointer} + 32)"

    # Generate Image Vector Table script
    GEN_IVT="$(cat <<-EOF
	import struct
	ivt = open('${SIGNDIR}/ivt.bin', 'wb') or Exception('Unable to open ivt file').throw()
	ivt.write(struct.pack('<L', 0x432000D1)) # Signature
	ivt.write(struct.pack('<L', ${load_address})) # Load Address (*load_address)
	ivt.write(struct.pack('<L', 0x0)) # Reserved
	ivt.write(struct.pack('<L', 0x0)) # DCD pointer
	ivt.write(struct.pack('<L', 0x0)) # Boot Data
	ivt.write(struct.pack('<L', ${ivt_pointer})) # Self Pointer (*ivt)
	ivt.write(struct.pack('<L', ${csf_pointer})) # CSF Pointer (*csf)
	ivt.write(struct.pack('<L', 0x0)) # Reserved
	ivt.close()
	EOF
)"

    # Generate Image Vector Table
    python3 -c "${GEN_IVT}"

    # Attach IVT
    cat ${SIGNDIR}/${KERNEL_IMAGETYPE}_pad.bin ${SIGNDIR}/ivt.bin > ${SIGNDIR}/${KERNEL_IMAGETYPE}_pad_ivt.bin
}

do_sign_kernel_image:append:hab4() {
    # Use user defined keys
    install -m 0755 ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/csf_hab4.cfg.sample ${SIGNDIR}/csf.cfg
}

do_sign_kernel_image:append:hab4() {
    # Generate signed image data
    ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/imx_signer -d -i ${SIGNDIR}/${KERNEL_IMAGETYPE}_pad_ivt.bin -c ${SIGNDIR}/csf.cfg
    if [ ! -e "${B}/signed-${KERNEL_IMAGETYPE}_pad_ivt.bin" ]; then
        bbfatal 'Kernel Image signing failed'
    fi

    if [ ${KERNEL_IMAGETYPE} = "Image.gz" ]; then
        gzip -f ${SIGNDIR}/signed-${KERNEL_IMAGETYPE}_pad_ivt.bin 
        cp ${B}/signed-${KERNEL_IMAGETYPE}_pad_ivt.bin.gz  ${B}/${KERNEL_OUTPUT_DIR}/${KERNEL_IMAGETYPE}
    else
        cp ${B}/signed-${KERNEL_IMAGETYPE}_pad_ivt.bin  ${B}/${KERNEL_OUTPUT_DIR}/${KERNEL_IMAGETYPE}
    fi
}

do_compile:append() {
    do_sign_kernel_image
}

PACKAGE_ARCH = "${MACHINE_ARCH}"

COMPATIBLE_MACHINE = "mx8-generic-bsp"
