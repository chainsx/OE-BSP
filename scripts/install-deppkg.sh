#!/bin/bash

deppkg_install() {
    dnf makecache
    dnf install git wget make gcc bison dtc m4 flex bc openssl-devel tar dosfstools rsync parted dnf-plugins-core tar kpartx diffutils rpm-build -y
}

deppkg_install
