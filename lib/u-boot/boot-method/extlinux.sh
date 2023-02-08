#!/bin/bash

root_dev=$1
boot_dir=$2
CMELINE=$3
BOOT_DTB_FILE=$4

apply_boot-method(){
    line=$(blkid | grep ${root_dev})
    uuid=${line#*UUID=\"}
    uuid=${uuid%%\"*}
    mkdir -p ${boot_dir}/extlinux
    echo "label openEuler
    kernel /Image
    initrd /initrd.img
    fdt /dtb/${BOOT_DTB_FILE}
    append  root=UUID=${uuid} ${CMDLINE}" > ${boot_dir}/extlinux/extlinux.conf
}

apply_boot-method
