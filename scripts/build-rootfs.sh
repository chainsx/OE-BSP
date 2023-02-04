#!/bin/bash

__usage="
Usage: build_rootfs [OPTIONS]
Build rockchip openEuler-root image.
Run in root user.
The folder rootfs will be generated in the build folder.

Options: 
  -r, --repo REPO_INFO          The URL/path of target repo file or list of repo's baseurls which should be a space separated list.
  -s, --spec SPEC               The image's specification: headless, xfce, ukui, dde or the file path of rpmlist. The default is headless.
  -h, --help                    Show command help.
"

source ./scripts/common.sh
if [ ! -d ${log_dir} ];then mkdir ${log_dir}; fi
if [ ! -f ${log_dir}/${builddate}.log ];then touch ${log_dir}/${builddate}.log; fi


help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    repo_file="https://gitee.com/src-openeuler/openEuler-repos/raw/openEuler-22.03-LTS-SP1/generic.repo"
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

INSTALL_PACKAGES(){
    for item in $(cat $1)
    do
        dnf ${repo_info} --disablerepo="*" --installroot=${rootfs_dir}/ install -y $item --nogpgcheck
        if [ $? == 0 ]; then
            LOG install $item.
        else
            ERROR can not install $item.
        fi
    done
}

build_rootfs() {
    trap 'UMOUNT_ALL' EXIT
    cd $build_dir
    if [ -d rootfs ];then rm -rf rootfs; fi
    mkdir rootfs

    if [ ! -d ${tmp_dir} ]; then
        mkdir -p ${tmp_dir}
    else
        rm -rf ${tmp_dir}/*
    fi

    if [ "x$spec_param" == "xheadless" ] || [ "x$spec_param" == "x" ]; then
        :
    elif [ "x$spec_param" == "xxfce" ] || [ "x$spec_param" == "xukui" ] || [ "x$spec_param" == "xdde" ]; then
        CONFIG_RPM_LIST=$work_dir/config/package/rpmlist/rpmlist-${spec_param}
    elif [ -f ${spec_param} ]; then
        cp ${spec_param} ${tmp_dir}/
        spec_file_name=${spec_param##*/}
        CONFIG_RPM_LIST=${tmp_dir}/${spec_file_name}
    else
        echo `date` - ERROR, please check your params in option -s or --spec.
        exit 2
    fi

    mkdir -p ${rootfs_dir}/var/lib/rpm
    rpm --root  ${rootfs_dir}/ --initdb

    if [ "x$repo_file" == "x" ] ; then
        echo `date` - ERROR, \"-r REPO_INFO or --repo REPO_INFO\" missing.
        help 2
    elif [ "x${repo_file:0:4}" == "xhttp" ]; then
        if [ "x${repo_file:0-5}" == "x.repo" ]; then
            repo_url=${repo_file}
            wget ${repo_file} -P ${tmp_dir}/
            repo_file_name=${repo_file##*/}
            repo_file=${tmp_dir}/${repo_file_name}
        else
            repo_file_name=tmp.repo
            repo_file_tmp=${tmp_dir}/${repo_file_name}
            index=1
            for baseurl in ${repo_file// / }
            do
                echo [repo${index}] >> ${repo_file_tmp}
                echo name=repo${index} to build rockchip image >> ${repo_file_tmp}
                echo baseurl=${baseurl} >> ${repo_file_tmp}
                echo enabled=1 >> ${repo_file_tmp}
                echo gpgcheck=0 >> ${repo_file_tmp}
                echo >> ${repo_file_tmp}
                index=$(($index+1))
            done
            repo_file=${repo_file_tmp}
        fi
    else
        if [ ! -f $repo_file ]; then
            echo `date` - ERROR, repo file $repo_file can not be found.
            exit 2
        else
            cp $repo_file ${tmp_dir}/
            repo_file_name=${repo_file##*/}
            repo_file=${tmp_dir}/${repo_file_name}
        fi
    fi

    repo_info_names=`cat ${repo_file} | grep "^\["`
    repo_baseurls=`cat ${repo_file} | grep "^baseurl="`
    index=1
    for repo_name in ${repo_info_names}
    do
        repo_name_list[$index]=${repo_name:1:-1}
        index=$((index+1))
    done
    index=1
    for baseurl in ${repo_baseurls}
    do
        repo_info="${repo_info} --repofrompath ${repo_name_list[$index]}-tmp,${baseurl:8}"
        index=$((index+1))
    done
    
    os_release_name="openEuler-release"
    dnf ${repo_info} --disablerepo="*" --downloaddir=${build_dir}/ download ${os_release_name}
    if [ $? != 0 ]; then
        ERROR "Fail to download ${os_release_name}!"
        exit 2
    fi
    os_release_name=`ls -r ${build_dir}/${os_release_name}*.rpm 2>/dev/null| head -n 1`
    if [ -z "${os_release_name}" ]; then
        ERROR "${os_release_name} can not be found!"
        exit 2
    else
        LOG "Success to download ${os_release_name}."
    fi

    rpm -ivh --nodeps --root ${rootfs_dir}/ ${os_release_name}

    mkdir -p ${rootfs_dir}/etc/rpm
    chmod a+rX ${rootfs_dir}/etc/rpm
    echo "%_install_langs en_US" > ${rootfs_dir}/etc/rpm/macros.image-language-conf
    INSTALL_PACKAGES $CONFIG_RPM_LIST
    cp -L /etc/resolv.conf ${rootfs_dir}/etc/resolv.conf
    rm ${build_dir}/*rpm
    
    echo "   nameserver 8.8.8.8
   nameserver 114.114.114.114"  > "${rootfs_dir}/etc/resolv.conf"
    if [ ! -d ${rootfs_dir}/etc/sysconfig/network-scripts ]; then mkdir -p "${rootfs_dir}/etc/sysconfig/network-scripts"; fi
    echo "   TYPE=Ethernet
   PROXY_METHOD=none
   BROWSER_ONLY=no
   BOOTPROTO=dhcp
   DEFROUTE=yes
   IPV4_FAILURE_FATAL=no
   IPV6INIT=yes
   IPV6_AUTOCONF=yes
   IPV6_DEFROUTE=yes
   IPV6_FAILURE_FATAL=no
   IPV6_ADDR_GEN_MODE=stable-privacy
   NAME=eth0
   UUID=851a6f36-e65c-3a43-8f4a-78fd0fc09dc9
   ONBOOT=yes
   AUTOCONNECT_PRIORITY=-999
   DEVICE=eth0" > "${rootfs_dir}/etc/sysconfig/network-scripts/ifup-eth0"
    
    LOG "Configure network done."

    #mount --bind /dev ${rootfs_dir}/dev
    #mount -t proc /proc ${rootfs_dir}/proc
    #mount -t sysfs /sys ${rootfs_dir}/sys

    cp $work_dir/target/scripts/expand-rootfs.sh ${rootfs_dir}/etc/rc.d/init.d/expand-rootfs.sh
    chmod +x ${rootfs_dir}/etc/rc.d/init.d/expand-rootfs.sh
    LOG "Set auto expand rootfs done."

    cat << EOF | chroot ${rootfs_dir}  /bin/bash
    echo 'openeuler' | passwd --stdin root
    echo openEuler > /etc/hostname
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    chkconfig --add expand-rootfs.sh
    chkconfig expand-rootfs.sh on
EOF

    #sed -i 's/#NTP=/NTP=0.cn.pool.ntp.org/g' ${rootfs_dir}/etc/systemd/timesyncd.conf
    #sed -i 's/#FallbackNTP=/FallbackNTP=1.asia.pool.ntp.org 2.asia.pool.ntp.org/g' ${rootfs_dir}/etc/systemd/timesyncd.conf

    echo "LABEL=rootfs  / ext4    defaults,noatime 0 0" > ${rootfs_dir}/etc/fstab
    echo "LABEL=boot  /boot vfat    defaults,noatime 0 0" >> ${rootfs_dir}/etc/fstab
    LOG "Set NTP and fstab done."

    if [ -d ${rootfs_dir}/boot/grub2 ]; then
        rm -rf ${rootfs_dir}/boot/grub2
    fi

    if [ -d ${rootfs_dir}/boot/efi ]; then
        rm -rf ${rootfs_dir}/boot/efi
    fi

    UMOUNT_ALL
}

set -e
root_need
default_param
parseargs "$@" || help $?

CONFIG_RPM_LIST=$work_dir/config/package/rpmlist/rpmlist

build_rootfs
