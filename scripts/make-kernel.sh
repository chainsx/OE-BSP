#!/bin/bash

__usage="
Usage: make-kernel [OPTIONS]
Make rockchip kernel package.
The target kernel package will be generated in the build/rpms folder.

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

clone_kernel_source() {
cd $build_dir
if [ -d $build_dir/kernel ];then rm -rf $build_dir/kernel; fi
git clone $KERNEL_GIT_SOURCE -b $KERNEL_GIT_SOURCE_BRANCH kernel --depth=1
rm -rf $build_dir/kernel/.config
rm -rf $build_dir/kernel/.git
}

check_and_apply_kernel_config() {
echo "KERNEL_CONFIG=$KERNEL_CONFIG"
echo "KERNEL_GIT_SOURCE_BRANCH=$KERNEL_GIT_SOURCE_BRANCH"
if [[ -f $work_dir/config/kernel/${KERNEL_CONFIG}.config ]];then
  cp $work_dir/config/kernel/${KERNEL_CONFIG}.config $build_dir/kernel/arch/arm64/configs/rpmbuild_defconfig
  cd $build_dir/kernel
  tar -zcvf $build_dir/${KERNEL_VERSION}.tar.gz .
  cd $build_dir && rm -rf kernel
  echo "kernel configure file check and apply done."
else
  echo "kernel configure file check and apply failed, please fix."
  exit 2
fi
}

build_kernel() {
mkdir -p ~/rpmbuild/SPECS
mkdir -p ~/rpmbuild/SOURCES
mv $build_dir/${KERNEL_VERSION}.tar.gz ~/rpmbuild/SOURCES
cp $work_dir/config/package/kernel.spec.temp ~/rpmbuild/SPECS/kernel.spec
sed -i "s|BUILDVERSION|${KERNEL_VERSION}|g" ~/rpmbuild/SPECS/kernel.spec
sed -i "s|PLATFORM|${PLATFORM}|g" ~/rpmbuild/SPECS/kernel.spec
cd ~/rpmbuild/SPECS && rpmbuild -ba kernel.spec
mkdir -p $build_dir/rpms
mv ~/rpmbuild/RPMS/aarch64/*rpm $build_dir/rpms
cd $build_dir && rm -rf ~/rpmbuild

}

parseargs "$@" || help $?
check_and_apply_board_config
clone_kernel_source
check_and_apply_kernel_config
build_kernel
