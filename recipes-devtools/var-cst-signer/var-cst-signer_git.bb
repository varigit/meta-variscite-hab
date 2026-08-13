SUMMARY = "Variscite CST Signer based on NXP CST Signer"
DESCRIPTION = "Image signing automation tool using CST"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=1f6f1c0be32491a0c8d2915607a28f36"

inherit deploy

SRC_URI = "${CST_SIGNER};branch=${SRCBRANCH}"
CST_SIGNER = "git://github.com/varigit/nxp-cst-signer.git;protocol=https"
SRCBRANCH = "v3.0_var01"
SRCREV = "25f0c9482af267710294af2fc996e3ba4dbf439b"

S = "${UNPACKDIR}/git"

BOOT_TOOLS = "imx-boot-tools"

do_deploy () {
    install -Dm 0755 ${S}/src/imx_signer ${DEPLOYDIR}/${BOOT_TOOLS}/imx_signer
}

addtask deploy after do_compile before do_install

BBCLASSEXTEND = "native nativesdk"
