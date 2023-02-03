#!/bin/bash

source $workdir/scripts/common.sh

BOARD=$1

clone_kernel_source() {
cd $build
if [ -d $build_dir/kernel ];then rm -rf $build_dir/kernel; fi
git clone $KERNEL_GIT_SOURCE -b $KERNEL_GIT_SOURCE_BRANCH kernel
rm -rf $build_dir/kernel/.config
}

check_and_apply_kernel_config() {
if [[ -f $workdir/config/kernel/$KERNEL_CONFIG.conf ]];then
  cp $workdir/config/kernel/$KERNEL_CONFIG.conf $build_dir/kernel/.config
  cd $build/kernel
  make defconfig
  echo "kernel configure file check and apply done."
else
  echo "kernel configure file check and apply failed, please fix."
  exit 2
fi
}

build_kernel() {
cd $build/kernel
make rpm-pkg -j$(nproc)
mkdir $build/rpms
mv ~/rpmbuild/RPMS/aarch64/*rpm $build/rpms
}

check_and_apply_board_config
clone_kernel_source
check_and_apply_kernel_config
build_kernel
