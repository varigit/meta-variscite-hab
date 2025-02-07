# Overrides for HAB
OVERRIDES:append:mx8m-generic-bsp:hab = ":hab4"

# Select signed target based on device
SIGNED_TARGET:mx8m-generic-bsp:hab = "flash_lpddr4_ddr4_evk"
SIGNED_TARGET:mx8mp-generic-bsp:hab = "flash_evk"
SIGNED_TARGET:mx93-generic-bsp:ahab = "flash_singleboot"
SIGNED_TARGET:mx8qxp-generic-bsp:ahab = "flash_spl"

python var_signbootdtb_handler() {
    if 'ahab' not in d.getVar('OVERRIDES').split(':') and 'hab' not in d.getVar('OVERRIDES').split(':'):
        return

    # Get default u-boot dtb to generate imx-boot image
    uboot_dtb = d.getVar('UBOOT_DTB_DEFAULT', True) or ""

    if not uboot_dtb:
        bb.fatal("UBOOT_DTB_DEFAULT is empty. Please set a value to proceed.")

    # Get kernel devicetree for signing Linux
    kernel_dtb = d.getVar('KERNEL_DTB_DEFAULT', True) or ""

    if 'ahab' in d.getVar('OVERRIDES') and not kernel_dtb:
        bb.fatal("KERNEL_DTB_DEFAULT is empty. Please set a value to proceed.")

    d.setVar('UBOOT_DTB_NAME', uboot_dtb)
    d.setVar('UBOOT_DTB_EXTRA', '')
}

var_signbootdtb_handler[eventmask] = "bb.event.RecipePreFinalise"
addhandler var_signbootdtb_handler
