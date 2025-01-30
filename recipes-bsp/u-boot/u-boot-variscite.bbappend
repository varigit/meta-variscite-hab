inherit hab

do_compile:prepend:hab4() {
    for config in ${UBOOT_MACHINE}; do
        echo "CONFIG_IMX_HAB=y" >> ${B}/${config}/.config
    done
}

do_compile:prepend:ahab() {
    # Update defconfig to enable secure boot
    for config in ${UBOOT_MACHINE}; do
        echo "CONFIG_AHAB_BOOT=y" >> ${B}/${config}/.config
    done
}

BOOT_TOOLS = "imx-boot-tools"

do_deploy:append:hab4() {
    unset i j
    for type in ${UBOOT_CONFIG}; do
        i=$(expr $i + 1)
        for config in ${UBOOT_MACHINE} ;do
            j=$(expr $j + 1)
            if [ "${type}" = "sd" ] && [ "${j}" = "${i}" ]; then
                # Store the uboot config file so that linux build can extract CONFIG_SYS_LOAD_ADDR from it for signing
                install -Dm 0755 ${B}/${config}/.config ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/u-boot-imx.config
                break 2
            fi
        done
    done

    if [ ! -e "${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/u-boot-imx.config" ]; then
        bbfatal 'Couldnt create UBoot config file to extract kernel image load address'
    fi
}
