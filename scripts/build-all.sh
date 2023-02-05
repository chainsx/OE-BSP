#!/bin/bash

__usage="
Usage: build_all [OPTIONS]
Build rockchip bootable image.
The target compressed bootable images will be generated in the build/YYYY-MM-DD folder of the directory where the build folder is located.

Options: 
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
    BOARD=rock5b
    repo_file="https://gitee.com/src-openeuler/openEuler-repos/raw/openEuler-22.03-LTS-SP1/generic.repo"
    spec_param=headless
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
    dnf install git wget make gcc bison dtc m4 flex bc kmod openssl-devel tar dosfstools rsync \
    parted dnf-plugins-core tar kpartx diffutils rpm-build python python3 -y
}

deppkg_install
default_param
parseargs "$@" || help $?

LOG "REPO=$repo_file"
LOG "SPEC=$spec_param"
LOG "BOARD=$BOARD"

check_and_apply_board_config

bash $work_dir/scripts/prepare-uboot.sh -r $BOARD
bash $work_dir/scripts/make-kernel.sh -r $BOARD
bash $work_dir/scripts/build-rootfs.sh -r $repo_file -s $spec_param
bash $work_dir/scripts/gen-image.sh -b $BOARD