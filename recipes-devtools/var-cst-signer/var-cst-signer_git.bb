SUMMARY = "Variscite CST Signer based on NXP CST Signer"
DESCRIPTION = "Image signing automation tool using CST"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=1f6f1c0be32491a0c8d2915607a28f36"

inherit deploy

SRC_URI = "${CST_SIGNER};branch=${SRCBRANCH}"
CST_SIGNER = "git://git@github.com/varigit-dev/nxp-cst-signer.git;protocol=ssh"
SRCBRANCH = "master"
SRCREV = "6f126504e0b625ad192e92613098b999bf61a0f1"

S = "${WORKDIR}/git"

BOOT_TOOLS = "imx-boot-tools"

do_deploy () {
    install -Dm 0755 ${S}/src/cst_signer ${DEPLOYDIR}/${BOOT_TOOLS}/cst_signer
}

addtask deploy after do_compile before do_install

BBCLASSEXTEND = "native nativesdk"
