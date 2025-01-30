# Overrides for HAB
OVERRIDES:append:mx8m-generic-bsp:hab = ":hab4"

# Select signed target based on device
SIGNED_TARGET:mx8m-generic-bsp:hab = "flash_lpddr4_ddr4_evk"
SIGNED_TARGET:mx8mp-generic-bsp:hab = "flash_evk"

python var_signbootdtb_handler() {
    if not 'hab' in d.getVar('OVERRIDES').split(':'):
        return

    sign_dtb = d.getVar('UBOOT_DTB_DEFAULT', True) or ""

    if not sign_dtb:
        bb.fatal("UBOOT_DTB_DEFAULT is empty. Please set a value to proceed.")

    d.setVar('UBOOT_DTB_NAME', sign_dtb)
    d.setVar('UBOOT_DTB_EXTRA', '')
}

var_signbootdtb_handler[eventmask] = "bb.event.RecipePreFinalise"
addhandler var_signbootdtb_handler
