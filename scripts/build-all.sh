#!/bin/bash

__usage="
Usage: build_all [OPTIONS]
Build rockchip bootable image.
The target compressed bootable images will be generated in the build/YYYY-MM-DD folder of the directory where the build folder is located.

Options: 
  -n, --name IMAGE_NAME         The Rockchip image name to be built.
  -b, --board BOARD_NAME        The target board name to be built.
  -r, --repo REPO_INFO          The URL/path of target repo file or list of repo's baseurls which should be a space separated list.
  -s, --spec SPEC               The image's specification: headless, xfce, ukui, dde or the file path of rpmlist. The default is headless.
  -h, --help                    Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

source ./scripts/common.sh

default_param() {
    outputdir=${build_dir}/$(date +'%Y-%m-%d')
    name=openEuler-Rockchip-aarch64-alpha1
    boot_dir=$rootfs_dir/boot
    uboot_dir=${build_dir}/u-boot
    boot_mnt=${build_dir}/boot_tmp
    root_mnt=${build_dir}/root_tmp
}

parseargs()
{
    if [ "x$#" == "x0" ]; then
        return 0
    fi

    while [ "x$#" != "x0" ];
    do
        if [ "x$1" == "x-h" -o "x$1" == "x--help" ]; then
            return 1
        elif [ "x$1" == "x" ]; then
            shift
        elif [ "x$1" == "x-n" -o "x$1" == "x--name" ]; then
            name=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-b" -o "x$1" == "x--board" ]; then
            BOARD=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-r" -o "x$1" == "x--repo" ]; then
            repo_file=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-s" -o "x$1" == "x--spec" ]; then
            spec_param=`echo $2`
            shift
            shift
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}


deppkg_install() {
    dnf makecache
    dnf install git wget make gcc bison dtc m4 flex bc kmod openssl-devel tar dosfstools rsync parted dnf-plugins-core tar kpartx diffutils rpm-build python python3 -y
}

deppkg_install
default_param
parseargs

LOG "REPO=$repo_file"
LOG "SPEC=$spec_param"
LOG "name=$name"
LOG "BOARD=$BOARD"

bash $work_dir/scripts/prepare-uboot.sh $BOARD
bash $work_dir/scripts/make-kernel.sh $BOARD
bash $work_dir/scripts/build-rootfs.sh -r $repo_file -s $spec_param
bash $work_dir/scripts/gen-image.sh -n $name -b $BOARD