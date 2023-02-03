#!/bin/bash

source ./scripts/common.sh

BOARD=$1

check_and_prepare_uboot() {
if [[ -f $work_dir/config/u-boot/$BOARD.dl ]];then
  source $work_dir/config/u-boot/$BOARD.dl
  if [ -d $build_dir/u-boot ];then rm -rf $build_dir/u-boot; fi
  mkdir $build_dir/u-boot
  wget $UBOOT_IDB_DL_ADDR -O $build_dir/u-boot/idbloader.img
  wget $UBOOT_ITB_DL_ADDR -O $build_dir/u-boot/u-boot.itb
  
  echo "prebuilt u-boot configure file check done."
else
  if [[ -f $work_dir/config/u-boot/$BOARD.build ]];then
    bash $work_dir/config/u-boot/$BOARD.build  # $BOARD.build will build u-boot and generate idb and itb file at $build_dir/u-boot
    echo "boards configure file check done."
  fi
  echo "boards configure file check failed, please fix."
  exit 2
fi
}
check_and_prepare_uboot
