DEPENDS += "imx-cst-native var-hab-certs"

SIG_TOOL_PATH ?= "${STAGING_BINDIR_NATIVE}"
SIG_DATA_PATH ?= "${DEPLOY_DIR_IMAGE}/imx-cst"

SIG_TOOL_PATH[export] = "1"
SIG_DATA_PATH[export] = "1"

do_configure:prepend () {
    # Check if SIG_TOOL_PATH is set and CST binary is available
    if [ -z "${SIG_TOOL_PATH}" ]; then
        bbfatal 'Code-Signing tool (CST) is not installed.
        Make sure it is in your PATH or edit you configuration file
        and set SIG_TOOL_PATH variable to the top directory of CST'
    fi
}
