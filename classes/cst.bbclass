DEPENDS += "imx-cst-native var-hab-certs"

CST_PATH ?= "${STAGING_BINDIR_NATIVE}"
CST_KEY_PATH ?= "${DEPLOY_DIR_IMAGE}/imx-cst"

CST_KEY_PATH[export] = "1"
CST_PATH[export] = "1"

do_configure:prepend () {
    # Check if CST_PATH is set and CST binary is available
    if [ -z "${CST_PATH}" ]; then
        bbfatal 'Code-Signing tool (CST) is not installed.
        Make sure it is in your PATH or edit you configuration file
        and set CST_PATH variable to the top directory of CST'
    fi
}
