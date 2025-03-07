## After the device successfully boots a signed image without generating any HAB
## events, it is safe to **secure**, or **"close,"** the device. This is the final
## step in the process. Once the fuse is blown, the chip will **only** load images
## signed with the correct PKI tree.

## Important Notes:
## - This is a **One-Time Programmable (OTP) e-fuse**. Once written,
## it **cannot be undone**, so make sure everything is correct before proceeding.

## - If any of the previous steps were not performed correctly, the SOM
## **will not boot** after this bit is written.

CST_SRK_FUSE ?= "SRK1234fuse.bin"
CST_SRK_FUSE:mx8m-generic-bsp  ?= "SRK_1_2_3_4_fuse.bin"
CST_SRK_FUSE_PATH ?= "${DEPLOY_DIR_IMAGE}/imx-cst/crts/${CST_SRK_FUSE}"
CST_SRK_FUSE_CMDS ?= "${CST_SRK_FUSE}.u-boot-cmds"

fuse_write_line() {
    bank=$1
    word=$2
    value=$3
    echo "fuse prog -y $bank $word $value"
}

create_fuse_cmds_mx8m() {
    echo "${WARNING1}" > ${fuse_log}
    word=0
    bank=6
    for i in $(seq 0 7); do
        if [ "$i" -eq "4" ]; then
            bank=7
            word=0
        fi
        offset=$(echo "$i * 4" | bc)
        value=$(hexdump -s $offset -n 4  -e '/4 "0x"' -e '/4 "%X""\n"' ${cst_srk_fuse})
        fuse_write_line $bank $word $value >> ${fuse_log}
        word="$(expr $word + 1)"
    done
    echo "${WARNING2}" >> ${fuse_log}
    echo "fuse prog 1 3 0x02000000" >> ${fuse_log}
}

create_fuse_cmds_mx8() {
    echo "${WARNING1}" > ${fuse_log}
    word="$1"
    bank=0
    for i in $(seq 0 15); do
        offset=$(echo "$i * 4" | bc)
        value=$(hexdump -s $offset -n 4  -e '/4 "0x"' -e '/4 "%X""\n"' ${cst_srk_fuse})
        fuse_write_line 0 $word $value >> ${fuse_log}
        word="$(expr $word + 1)"
    done
    echo "${WARNING2}" >> ${fuse_log}
    echo "ahab_close" >> ${fuse_log}
}

create_fuse_cmds_mx9() {
    echo "${WARNING1}" > ${fuse_log}
    word=0
    for i in $(seq 0 7); do
        offset=$(echo "$i * 4" | bc)
        value=$(hexdump -s $offset -n 4  -e '/4 "0x"' -e '/4 "%X""\n"' ${cst_srk_fuse})
        fuse_write_line 16 $word $value >> ${fuse_log}
        word="$(expr $word + 1)"
    done
    echo "${WARNING2}" >> ${fuse_log}
    echo "ahab_close" >> ${fuse_log}
}

create_fuse_cmds() {
    soc="$1"
    cst_srk_fuse="$2"
    fuse_log="$3"
    if [ ! -f $cst_srk_fuse ]; then
        bbfatal "Could not find '$cst_srk_fuse'"
    fi

    case ${soc} in
      mx8m)
        create_fuse_cmds_mx8m
        ;;
      mx8x)
        create_fuse_cmds_mx8 730
        ;;
      mx8)
        create_fuse_cmds_mx8 722
        ;;
      mx93)
        create_fuse_cmds_mx9
        ;;
      *)
        bbwarn "Unsupported SOC: ${soc}"
        ;;
    esac
}

do_compile:append() {
    create_fuse_cmds ${SOC_FAMILY} ${CST_SRK_FUSE_PATH} ${WORKDIR}/${CST_SRK_FUSE_CMDS}
}

do_deploy:append() {
    if [ -f ${WORKDIR}/${CST_SRK_FUSE_CMDS} ]; then
        install -Dm 0755 ${WORKDIR}/${CST_SRK_FUSE_CMDS} ${DEPLOY_DIR_IMAGE}/${CST_SRK_FUSE_CMDS}
    else
        bbwarn "Could not deploy SRK fuse U-Boot commands"
    fi
}
