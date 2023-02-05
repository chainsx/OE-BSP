#!/bin/bash

source ./scripts/common.sh

root_dev=$1
boot_dev=$2

apply_boot-method(){
    line=$(blkid | grep ${root_dev})
    uuid=${line#*UUID=\"}
    uuid=${uuid%%\"*}
    LOG "root-UUID=${uuid}"
    LOG "CMDLINE=${CMDLINE}"
    LOG "BOOT_DTB_FILE=${BOOT_DTB_FILE}"

    mkdir -p ${boot_dev}/extlinux
    echo "label openEuler
    kernel /Image
    initrd /initrd.img
    fdt /dtb/${BOOT_DTB_FILE}
    append  root=UUID=${uuid} ${CMDLINE}" > ${boot_dev}/extlinux/extlinux.conf
}

check_and_apply_board_config
apply_boot-method
