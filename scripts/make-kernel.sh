#!/bin/bash

source ./scripts/common.sh

BOARD=$1

check_and_apply_board_config() {
if [[ -f $work_dir/config/boards/$BOARD.conf ]];then
  source $work_dir/config/boards/$BOARD.conf
  echo "boards configure file check done."
else
  echo "boards configure file check failed, please fix."
  exit 2
fi
}

clone_kernel_source() {
cd $build_dir
if [ -d $build_dir/kernel ];then rm -rf $build_dir/kernel; fi
git clone $KERNEL_GIT_SOURCE -b $KERNEL_GIT_SOURCE_BRANCH kernel --depth=1
rm -rf $build_dir/kernel/.config
rm -rf $build_dir/kernel/.git
}

check_and_apply_kernel_config() {
if [[ -f $work_dir/config/kernel/$KERNEL_CONFIG.conf ]];then
  cp $work_dir/config/kernel/$KERNEL_CONFIG.conf $build_dir/kernel/arch/arm64/configs/rpmbuild_defconfigs
  cd $build_dir/kernel
  tar -zcvf $build/$KERNEL_GIT_SOURCE_BRANCH.tar.gz .
  cd $build_dir && rm -rf kernel
  echo "kernel configure file check and apply done."
else
  echo "kernel configure file check and apply failed, please fix."
  exit 2
fi
}

build_kernel() {
mkdir ~/rpmbuild/SPECS
mkdir ~/rpmbuild/SOURCES
mv $build_dir/$KERNEL_GIT_SOURCE_BRANCH.tar.gz ~/rpmbuild/SOURCES
cp $work_dir/config/package/kernel.spec.temp ~/rpmbuild/SPECS/kernel.spec
sed -i "s|BUILDVERSION|${KERNEL_GIT_SOURCE_BRANCH}|g" ~/rpmbuild/SPECS/kernel.spec
sed -i "s|PLATFORM|${PLATFORM}|g" ~/rpmbuild/SPECS/kernel.spec
cd ~/rpmbuild/SPECS && rpmbuild -ba kernel.spec
mv ~/rpmbuild/RPMS/aarch64/*rpm $build/rpms
cd $build_dir && rm -rf ~/rpmbuild

}
check_and_apply_board_config
clone_kernel_source
check_and_apply_kernel_config
build_kernel
