#!/bin/bash

__usage="
Usage: prepare_uboot [OPTIONS]
Prepare rockchip u-boot image.
The target u-boot images will be generated in the build/u-boot folder.

Options: 
  -b, --board BOARD_NAME        The target board name to be built.
  -h, --help                    Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

source ./scripts/common.sh

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
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

check_and_prepare_uboot() {
if [ -d $build_dir/u-boot ];then rm -rf $build_dir/u-boot; fi
  mkdir -p $build_dir/u-boot
if [[ -f $work_dir/config/u-boot/$BOARD.dl ]];then
  bash $work_dir/config/u-boot/$BOARD.dl $build_dir
  echo "prebuilt u-boot configure file check done."
else
if [[ -f $work_dir/config/u-boot/$BOARD.build ]];then
  bash $work_dir/config/u-boot/$BOARD.build $build_dir
  echo "u-boot configure file check done."
fi
echo "u-boot configure file check failed, please fix."
exit 2
fi
}

parseargs "$@" || help $?
check_and_prepare_uboot
