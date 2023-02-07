#!/bin/bash

build_dir=$1
target=$2

uboot_dir=$1/u-boot

check_u-uboot() {
if [ ! -f $uboot_dir/u-boot.bin ];then
	echo "u-boot.bin not found, exiting..."
	exit 2
fi
}

download_rpi_firmware() {
cd $build_dir
git clone https://github.com/raspberrypi/firmware --depth=1 $build_dir/rpi-firmware
mv $build_dir/rpi-firmware/boot $build_dir/rpi-boot 
rm -rf $build_dir/rpi-firmware
rm -rf $build_dir/rpi-boot/*dtb
rm -rf $build_dir/rpi-boot/*img
}

move_uboot_and_write_config() {
cp ${build_dir}/u-boot/u-boot.bin $build_dir/rpi-boot
echo "kernel=u-boot.bin
kernel_address=0x00080000
arm_64bit=1
enable_uart=1
uart_2ndstage=1
enable_gic=1" > "$build_dir/rpi-boot/config.txt"
}

apply_uboot() {
cp -rfp $build_dir/rpi-boot/* ${build_dir}/tmp_dir
sync
}

check_u-uboot
mkdir ${build_dir}/tmp_dir
mount ${target}1 ${build_dir}/tmp_dir
download_rpi_firmware
move_uboot_and_write_config
apply_uboot