#!/bin/bash

set -e

source config.sh

function init_build_system()
{
    mkdir -p ${BUILDDIR}
    mkdir -p ${PKGDIR}
}

function download
{
    local pkgPath=$(url_to_pkg_path $1)

    if [ ! -e ${pkgPath} ] ; then
	wget --quiet $1 -O ${pkgPath}  > /dev/null
    fi
}


function unpack
{
    local pkgPath=$(url_to_pkg_path $1)
    tar  xf "${pkgPath}" -C "${BUILDDIR}"
}


function do_prepare_toolchain()
{
    rm -rf $(url_to_build_path ${CT_URL})

    download ${CT_URL}
    unpack ${CT_URL}

    cd $(url_to_build_path ${CT_URL})

    rm -rf ${CTNGDIR}
    ./configure --prefix=${CTNGDIR}
    make
    make install    
    cd ${TOPDIR}
}

function do_configure_toolchain()
{
    cd $(url_to_build_path ${CT_URL})

    ${CTNGDIR}/bin/ct-ng distclean
    cp ${CONFIGDIR}/ct-config .config
    ${CTNGDIR}/bin/ct-ng oldconfig
    cd ${TOPDIR}
}

function do_clean_toolchain()
{
    cd $(url_to_build_path ${CT_URL})
    ${CTNGDIR}/bin/ct-ng clean
    cd ${TOPDIR}
}


function do_build_toolchain()
{
    cd $(url_to_build_path ${CT_URL})
    ${CTNGDIR}/bin/ct-ng build
    cd ${TOPDIR}
}


function do_prepare_os()
{
    rm -rf $(url_to_build_path ${BR_URL})

    download ${BR_URL}
    unpack ${BR_URL}
}

function do_configure_os()
{
    cd $(url_to_build_path ${BR_URL})
    cp ${CONFIGDIR}/br-config .config
    make oldconfig
    cd ${TOPDIR}
}


function do_clean_os()
{
    cd $(url_to_build_path ${BR_URL})
    make clean
    cd ${TOPDIR}
}

function do_build_os()
{
    cd $(url_to_build_path ${BR_URL})
    make
    cd ${TOPDIR}
}

function do_purge()
{
    rm -rf ${BUILDDIR}
    rm -rf ${PKGDIR}

    init_build_system
}


function do_print_usage()
{
    echo "Usages: "
    echo "----------------------------------------"
    echo "$0 prepare toolchain"
    echo "$0 prepare os"
    echo " "
    echo "$0 configure toolchain"
    echo "$0 configure os"
    echo " "
    echo "$0 build toolchain"
    echo "$0 build os"
    echo " "
    echo "$0 rebuild toolchain"
    echo "$0 rebuild os"
    echo " "
    echo "$0 clean toolchain"
    echo "$0 clean os"
    echo " "
    echo "$0 all"
    echo " "
    echo "$0 purge"
}


function do_prepare()
{
    local target="$1"
    case $target in
	toolchain)
	    do_prepare_toolchain
	    ;;
	
	os)
	    do_prepare_os
	    ;;
	
	*)
	    do_print_usage
	    exit 1
	    ;;
    esac
}

function do_prepare()
{
    local target="$1"
    case $target in
	toolchain)
	    do_prepare_toolchain
	    ;;
	
	os)
	    do_prepare_os
	    ;;
	
	*)
	    do_print_usage
	    exit 1
	    ;;
    esac
}


function do_configure()
{
    local target="$1"
    case $target in
	toolchain)
	    do_configure_toolchain
	    ;;
	
	os)
	    do_configure_os
	    ;;
	
	*)
	    do_print_usage
	    exit 1
	    ;;
    esac
}

function do_clean()
{
    local target="$1"
    case $target in
	toolchain)
	    do_clean_toolchain
	    ;;
	
	os)
	    do_clean_os
	    ;;
	
	*)
	    do_print_usage
	    exit 1
	    ;;
    esac
}


function do_build()
{
    local target="$1"
    case $target in
	toolchain)
	    do_build_toolchain
	    ;;
	
	os)
	    do_build_os
	    ;;
	
	*)
	    do_print_usage
	    exit 1
	    ;;
    esac
}


#---------------------------------------
#------------- ENTRY POINT -------------
#---------------------------------------


init_build_system

if [[ $# == 0 ]] ; then
    do_print_usage
    exit 1    
fi


while [[ $# > 0 ]]
do
    cmd="$1"

    case $cmd in
	prepare)
	    target="$2"
	    shift

	    do_prepare "$target"	    
	    ;;

	configure)
	    target="$2"
	    shift

	    do_configure "$target"
	    ;;

	clean)
	    target="$2"
	    shift

	    do_clean "$target"
	    ;;
	
	
	build)
	    target="$2"
	    shift	    

	    do_build "$target"
	    ;;
	
	rebuild)
	    target="$2"
	    shift
	    
	    do_clean "$target"
	    do_build "$target"
	    ;;

	all)
	    do_prepare toolchain
	    do_configure toolchain
	    do_clean toolchain
	    do_build toolchain

	    do_prepare os
	    do_configure os
	    do_clean os 
	    do_build os
	    ;;
	
	purge)
	    do_purge
	    ;;
	
	*)
	    do_print_usage
	    exit 1
	    ;;
    esac
    shift
done

echo "---------"
echo "- DONE! -"
echo "---------"
