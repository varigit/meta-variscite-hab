SUMMARY = "Variscite HAB certificates for i.MX"
DESCRIPTION = "Certificates for use with the i.MX Code Signing Tool"
LICENSE = "CLOSED"

inherit deploy

CST_CERTS_REV ?= "56ad83a9962fb1cd8b4a18dc72993de7e7894bc5"
CST_CERTS_URI ?= "git://github.com/varigit/var-hab-certs.git;protocol=https;branch=master;rev=${CST_CERTS_REV}"

SRC_URI = "\
    ${CST_CERTS_URI};name=cst-certs;destsuffix=cst-certs \
    file://csf_hab4.cfg \
    file://csf_ahab.cfg \
"

CST_CRT_ROOT:mx8m-nxp-bsp ?= "${WORKDIR}/cst-certs/iMX8M"
CST_CRT_ROOT:mx8-nxp-bsp  ?= "${WORKDIR}/cst-certs/iMX8"

BOOT_TOOLS = "imx-boot-tools"

CST_SERIAL ?= "1248163E"
CST_KEYPASS ?= "Variscite_password"

do_deploy() {
    install -d ${DEPLOYDIR}/imx-cst/crts
    cp -R ${CST_CRT_ROOT}/crts/* ${DEPLOYDIR}/imx-cst/crts/

    install -d ${DEPLOYDIR}/imx-cst/keys
    cp -R ${CST_CRT_ROOT}/keys/* ${DEPLOYDIR}/imx-cst/keys/

    echo "${CST_SERIAL}" > ${DEPLOYDIR}/imx-cst/keys/serial
    echo "${CST_KEYPASS}" > ${DEPLOYDIR}/imx-cst/keys/key_pass.txt
    echo "${CST_KEYPASS}" >> ${DEPLOYDIR}/imx-cst/keys/key_pass.txt

    install -d ${DEPLOYDIR}/imx-boot-tools/
    install -m 0755 ${WORKDIR}/csf_ahab.cfg ${DEPLOYDIR}/${BOOT_TOOLS}/csf_ahab.cfg.sample
    install -m 0755 ${WORKDIR}/csf_hab4.cfg ${DEPLOYDIR}/${BOOT_TOOLS}/csf_hab4.cfg.sample
}

addtask deploy after do_install before do_build
