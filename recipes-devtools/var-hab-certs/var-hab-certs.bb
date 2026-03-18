SUMMARY = "Variscite HAB certificates for i.MX"
DESCRIPTION = "Certificates for use with the i.MX Code Signing Tool"
LICENSE = "CLOSED"

inherit deploy

CST_CERTS_REV ?= "0b2c9c39fbc5020b5faf8c7f1d0db5381c680785"
CST_CERTS_URI ?= "git://github.com/varigit/var-hab-certs.git;protocol=https;branch=master;rev=${CST_CERTS_REV}"

S = "${WORKDIR}/cst-certs"

SRC_URI = "\
    ${CST_CERTS_URI};name=cst-certs;destsuffix=cst-certs \
"

SRC_URI:append:hab = " \
    file://csf_hab4.cfg \
"

SRC_URI:append:ahab = " \
    file://spsdk_ahab.yaml \
"

CST_CRT_ROOT:mx8m-generic-bsp ?= "${S}/iMX8M"
CST_CRT_ROOT:mx8-generic-bsp  ?= "${S}/iMX8"
CST_CRT_ROOT:mx9-generic-bsp  ?= "${S}/iMX9"

BOOT_TOOLS = "imx-boot-tools"

CST_SERIAL ?= "1248163E"
CST_KEYPASS ?= "Variscite_password"

do_deploy_hab_cfg() {
    bbnote "Deploying HAB configuration files"
    install -d ${DEPLOYDIR}/imx-boot-tools/
}

do_deploy_hab_cfg:append:hab() {
    install -m 0755 ${UNPACKDIR}/csf_hab4.cfg ${DEPLOYDIR}/${BOOT_TOOLS}/csf_hab4.cfg.sample
}

do_deploy_hab_cfg:append:ahab() {
    install -m 0755 ${UNPACKDIR}/spsdk_ahab.yaml ${DEPLOYDIR}/${BOOT_TOOLS}/spsdk_ahab.yaml.sample
}

do_deploy() {
    install -d ${DEPLOYDIR}/imx-cst/crts
    cp -R ${CST_CRT_ROOT}/crts/* ${DEPLOYDIR}/imx-cst/crts/

    install -d ${DEPLOYDIR}/imx-cst/keys
    cp -R ${CST_CRT_ROOT}/keys/* ${DEPLOYDIR}/imx-cst/keys/

    echo "${CST_SERIAL}" > ${DEPLOYDIR}/imx-cst/keys/serial
    echo "${CST_KEYPASS}" > ${DEPLOYDIR}/imx-cst/keys/key_pass.txt
    echo "${CST_KEYPASS}" >> ${DEPLOYDIR}/imx-cst/keys/key_pass.txt

    do_deploy_hab_cfg
}

do_deploy:append:mx95-generic-bsp() {
    # i.MX95 B0 requires sha512-based SRK binaries
    mv ${DEPLOYDIR}/imx-cst/crts/SRK1234fuse_mx95b0.bin \
       ${DEPLOYDIR}/imx-cst/crts/SRK1234fuse.bin

    mv ${DEPLOYDIR}/imx-cst/crts/SRK1234table_mx95b0.bin \
       ${DEPLOYDIR}/imx-cst/crts/SRK1234table.bin
}

addtask deploy after do_install before do_build
