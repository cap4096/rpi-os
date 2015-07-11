#!/bin/bash


CTNGDIR=/opt/toolchains/ct-ng
TOOLCHAINDIR=/opt/toolchains/x-tools
TOPDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BUILDDIR=${TOPDIR}/build
PKGDIR=${TOPDIR}/downloads
CONFIGDIR=${TOPDIR}/config
CT_PATCH_DIR=${TOPDIR}/ct-patches
BR_PATCH_DIR=${TOPDIR}/br-patches
KERNEL_PATCH_DIR=${TOPDIR}/kernel-patches

export PKGDIR
export CONFIGDIR
export CT_PATCH_DIR
export BR_PATCH_DIR
export KERNEL_PATCH_DIR
export TOOLCHAINDIR

mkdir -p ${BUILDDIR}
mkdir -p ${PKGDIR}



function download
{
    local pkgName=$(basename $1)

    if [ ! -e ${PKGDIR}/$pkgName ] ; then
	wget --quiet $1 -O ${PKGDIR}/$pkgName  > /dev/null
    fi

    echo "$pkgName"
}

function unpack
{
    local pkgName="${1%.*}"
    pkgName="${pkgName%.*}"

    tar  xf "${PKGDIR}/$1" -C "${BUILDDIR}"
    echo "${BUILDDIR}/${pkgName}"
}


function build_toolchain
{
    cd $1
    rm -rf ${CTNGDIR}
    ./configure --prefix=${CTNGDIR}
    make
    make install
    
    ${CTNGDIR}/bin/ct-ng distclean
    cp ${CONFIGDIR}/ct-config .config
    ${CTNGDIR}/bin/ct-ng oldconfig
    ${CTNGDIR}/bin/ct-ng build
    
    cd ${TOPDIR}
}

function build_buildroot
{
    cd $1
    
    cp ${CONFIGDIR}/br-config .config
    make oldconfig
    make
    cd ${TOPDIR}
}



#
# Download tarballs
#
CTPKG=$(download http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.21.0.tar.bz2)
BRPKG=$(download http://www.buildroot.org/downloads/buildroot-2015.05.tar.bz2)

CT_DIR=$(unpack ${CTPKG} )
BR_DIR=$(unpack ${BRPKG} )

build_toolchain ${CT_DIR}
build_buildroot ${BR_DIR}
