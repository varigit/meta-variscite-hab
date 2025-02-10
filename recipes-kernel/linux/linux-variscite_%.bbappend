require ${@ 'linux-var-signature.inc' if 'hab' in d.getVar('OVERRIDES').split(':') else ''}

do_deploy:append:ahab() {
    install -Dm 0755 ${B}/${KERNEL_OUTPUT_DIR}/Image ${DEPLOYDIR}/Image
}
