#!/bin/bash

UBOOT_IDB_WRITE_SEEK="64"
UBOOT_ITB_WRITE_SEEK="16384"

target=$1

check_u-uboot() {
if [ ! -f $build_dir/u-boot/idbloader.img ];then
	echo "idbloader.img not found, exiting..."
	exit 2
fi
if [ ! -f $build_dir/u-boot/u-boot.itb ];then
	echo "u-boot.itb not found, exiting..."
	exit 2
fi
}

write_u-boot() {

dd if=$build_dir/u-boot/idbloader.img of=$target seek=$UBOOT_IDB_WRITE_SEEK
dd if=$build_dir/u-boot/u-boot.itb of=$target seek=$UBOOT_ITB_WRITE_SEEK

}

check_u-uboot
write_u-boot