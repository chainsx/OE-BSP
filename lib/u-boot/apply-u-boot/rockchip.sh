#!/bin/bash

UBOOT_IDB_WRITE_SEEK="64"
UBOOT_ITB_WRITE_SEEK="16384"

uboot_dir=$1
target=$2

check_u-uboot() {
if [ ! -f $uboot_dir/idbloader.img ];then
	echo "idbloader.img not found, exiting..."
	exit 2
fi
if [ ! -f $uboot_dir/u-boot.itb ];then
	echo "u-boot.itb not found, exiting..."
	exit 2
fi
}

write_u-boot() {
dd if=$uboot_dir/idbloader.img of=$target seek=$UBOOT_IDB_WRITE_SEEK
dd if=$uboot_dir/u-boot.itb of=$target seek=$UBOOT_ITB_WRITE_SEEK
}

check_u-uboot
write_u-boot