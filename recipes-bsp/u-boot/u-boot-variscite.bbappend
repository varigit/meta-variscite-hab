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
