inherit hab

do_compile:prepend:hab4() {
    for config in ${UBOOT_MACHINE}; do
        echo "CONFIG_IMX_HAB=y" >> ${B}/${config}/.config
    done
}

do_compile:prepend:ahab() {
    # Update defconfig to enable secure boot
    unset i
    for config in ${UBOOT_MACHINE}; do
        i=$(expr $i + 1)
        unset j
        for type in ${UBOOT_CONFIG}; do
            j=$(expr $j + 1)
            if [ $j -eq $i ]; then
                builddir="${config}-${type}"
                echo "CONFIG_AHAB_BOOT=y" >> ${B}/${builddir}/.config
                break
            fi
        done
    done
}
