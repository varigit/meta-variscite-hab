# NXP CST Utils
# Requires registration, download from https://www.nxp.com/webapp/sps/download/license.jsp?colCode=IMX_CST_TOOL
# Override NXP_CST_URI in local.conf as needed
NXP_CST_URI ?= "file://${HOME}/cst-3.1.0.tgz"
SRC_URI:append:hab = " ${NXP_CST_URI};name=cst;subdir=cst;"
CST_BIN ?= "${WORKDIR}/cst/release/linux64/bin/cst"

# Override CST_CERTS_URI in local.conf with customer repository:
CST_CERTS_REV ?= "56ad83a9962fb1cd8b4a18dc72993de7e7894bc5"
CST_CERTS_URI ?= "git://github.com/varigit/var-hab-certs.git;protocol=https;branch=master;rev=${CST_CERTS_REV}"
SRC_URI:append:hab = " ${CST_CERTS_URI};name=cst-certs;destsuffix=cst-certs;"
SRCREV_cst-certs="${CST_CERTS_REV}"

CST_CRT_ROOT:mx8m-nxp-bsp ?= "${WORKDIR}/cst-certs/iMX8M"
CST_CRT_ROOT:mx8-nxp-bsp ?= "${WORKDIR}/cst-certs/iMX8"

# HABv4 Keys
CST_SRK:mx8m-nxp-bsp ?= "${CST_CRT_ROOT}/crts/SRK_1_2_3_4_table.bin"
CST_CSF_CERT ?= "${CST_CRT_ROOT}/crts/CSF1_1_sha256_4096_65537_v3_usr_crt.pem"
CST_IMG_CERT ?= "${CST_CRT_ROOT}/crts/IMG1_1_sha256_4096_65537_v3_usr_crt.pem"
CST_SRK_FUSE:mx8m-nxp-bsp ?= "${CST_CRT_ROOT}/crts/SRK_1_2_3_4_fuse.bin"

# AHAB Keys
CST_SRK:mx8-nxp-bsp ?= "${CST_CRT_ROOT}/crts/SRK1234table.bin"
CST_KEY ?= "${CST_CRT_ROOT}/crts/SRK1_sha384_4096_65537_v3_usr_crt.pem"
CST_SRK_FUSE:mx8-nxp-bsp ?= "${CST_CRT_ROOT}/crts/SRK1234fuse.bin"

# Override in local.conf with customer serial & password
CST_KEYPASS ?= "Variscite_password"
CST_SERIAL ?= "1248163E"

HAB_VER:mx8x-nxp-bsp:hab="ahab"
HAB_VER:mx8qm-nxp-bsp:hab="ahab"
HAB_VER:mx8m-nxp-bsp:hab="habv4"

do_compile:prepend:hab() {
    # Prepare serial and key_pass files with secrets
    echo "${CST_SERIAL}" > ${CST_CRT_ROOT}/keys/serial
    echo "${CST_KEYPASS}" > ${CST_CRT_ROOT}/keys/key_pass.txt
    echo "${CST_KEYPASS}" >> ${CST_CRT_ROOT}/keys/key_pass.txt
}
