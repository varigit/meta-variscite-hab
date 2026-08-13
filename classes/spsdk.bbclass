DEPENDS += "var-hab-certs"
DEPENDS:append:imx95-var-dart = " python3-spsdk-native"

SIG_TOOL_PATH:imx95-var-dart ?= "${STAGING_BINDIR_NATIVE}"
SIG_DATA_PATH ?= "${DEPLOY_DIR_IMAGE}/imx-cst"

SIG_TOOL_PATH[export] = "1"
SIG_DATA_PATH[export] = "1"

do_configure:prepend () {
    # Check if SIG_TOOL_PATH is set and SPSDK binary is available
    if [ -z "${SIG_TOOL_PATH}" ] || [ ! -f "${SIG_TOOL_PATH}/spsdk" ]; then
        bbfatal 'Signing tool (SPSDK) is not installed.
        Make sure it is in your PATH or edit you configuration file
        and set SIG_TOOL_PATH variable to the top directory of SPSDK.'
    fi
}
