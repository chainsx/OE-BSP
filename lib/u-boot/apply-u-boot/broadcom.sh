#!/bin/bash

build_dir=$1
target=$2

uboot_dir=$build_dir/u-boot

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
cp ${build_dir}/u-boot/arch/arm/dts/*.dtb $build_dir/rpi-boot
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
umount $build_dir/tmp_dir
rmdir $build_dir/tmp_dir
}

mkdir ${build_dir}/tmp_dir
mount /dev/mapper/${target}p1 ${build_dir}/tmp_dir
download_rpi_firmware
move_uboot_and_write_config
apply_uboot
