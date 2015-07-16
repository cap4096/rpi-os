#!/bin/bash

TOPDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PKGDIR=${TOPDIR}/downloads
BUILDDIR=${TOPDIR}/build
CONFIGDIR=${TOPDIR}/config
CT_PATCH_DIR=${TOPDIR}/ct-patches
BR_PATCH_DIR=${TOPDIR}/br-patches
KERNEL_PATCH_DIR=${TOPDIR}/kernel-patches

CTNGDIR=/opt/toolchains/ct-ng
TOOLCHAINDIR=/opt/toolchains/x-tools

CARDDIR=${TOPDIR}/card
BOOT_PATH=${CARDDIR}/boot
SYSTEM_PATH=${CARDDIR}/system

#----------- Begin: Package config 

CT_URL="http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.21.0.tar.bz2"
BR_URL="http://www.buildroot.org/downloads/buildroot-2015.05.tar.bz2"

#----------- End: Package config

export PKGDIR
export CONFIGDIR
export CT_PATCH_DIR
export BR_PATCH_DIR
export KERNEL_PATCH_DIR
export TOOLCHAINDIR

function url_to_pkg_name()
{
    local pkgName=$(basename $1)

    pkgName="${pkgName%.*}"
    pkgName="${pkgName%.*}"

    echo $pkgName
}

function url_to_build_path()
{
    echo "${BUILDDIR}/$(url_to_pkg_name $1)"
}

function url_to_pkg_path()
{
    echo "${PKGDIR}/$(basename $1)"
}

