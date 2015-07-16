#!/bin/bash

set -e
source config.sh


function check_device()
{
    local dev=${1}

    if [ ! -b "${dev}" ] ; then
	echo "${dev} is not a valid block device!"
	exit 1
    fi
}


function rescan_partitions()
{
    local dev="${1}"
    check_device "${dev}"
    
    echo -n "Rescanning partion table on ${dev}: "
    sync

    partprobe "${dev}"
    local retries=0
    until [ $retries -ge 20 ]
    do
	blockdev --rereadpt "${dev}" &> /dev/null && break
	sleep 1
	echo -n "."
	retries=$[$retries+1]
    done

    if [ $retries -ge 20 ] ; then
	echo "FAIL"
	echo "Failed to rescan partition table on device ${dev}"
	exit 1
    else
	echo "OK"
    fi
}


function clear_card()
{
    local dev="${1}"
    check_device "${dev}"

    echo "Clearing MBR + Partion table + Boot code on device: ${dev}"

    dd if=/dev/zero of="${dev}" bs=512 count=1024 &> /dev/null
}


function clear_partition()
{
    local dev="${1}"
    check_device "${dev}"

    echo "Clearing partion (first 8Mb) on device: ${dev}"
    # Clears the first 8M of the partion
    dd if=/dev/zero of="${dev}" bs=512 count=16384 &> /dev/null
}

function partition_card()
{
    local dev="${1}"

    rescan_partitions "${dev}"
    check_device "${dev}"
    clear_card "${dev}"
    
    echo "Creating partion table"
    parted --align optimal --script "${dev}" mklabel msdos
    echo "Creating boot partition"
    parted --align optimal --script "${dev}" mkpart primary fat16 -- 0 32MiB
    echo "Creating system partion"
    parted --align optimal --script "${dev}" mkpart primary ext4  -- 32MiB 100%
    echo "Making partion boot partion bootable"
    parted --align optimal --script "${dev}" set 1 boot on

    rescan_partitions "${dev}"
    check_device "${dev}"
    check_device "${dev}1"
    check_device "${dev}2"
}

function format_card()
{
    local dev="${1}"

    rescan_partitions "${dev}"
    check_device "${dev}"
    check_device "${dev}1"
    check_device "${dev}2"

    clear_partition "${dev}1"
    clear_partition "${dev}2"
    
    mkfs -t vfat -F 16  "${dev}1" &> /dev/null
    fatlabel "${dev}1" START
    mkfs -t ext4 -L SYSTEM -q "${dev}2" &> /dev/null

    sync
}


function confirm()
{
    local dev="${1}"

    echo "You are going to erease EVERYTHING on device ${device}"
    echo "Is that really what you want, type: YES"

    read ok

    if [[ ${ok} != "YES" ]] ; then
	echo "Aborting...."
	exit 1
    fi
}

function check_root()
{
    if [ $(id -u) -ne 0 ] ; then
	echo "${0} must be run as root (use sudo!)"
	exit 1
    fi
}


function mount_card()
{
    local dev="${1}"

    rescan_partitions "${dev}"
    check_device "${dev}"
    check_device "${dev}1"
    check_device "${dev}2"

    echo "Mounting file systems on card"
    
    mkdir -p ${BOOT_PATH}
    mkdir -p ${SYSTEM_PATH}
    mount -t vfat "${dev}1" ${BOOT_PATH}
    mount -t ext4 "${dev}2" ${SYSTEM_PATH}
}

function unmount_card()
{
    local dev="${1}"

    check_device "${dev}"

    echo "Unmounting file systems on card"
    
    #unmount all devices on the card
    for p in ${dev}* ; do
	if [ "${p}" != "${dev}" ] ; then
	    umount $p &> /dev/null || true
	fi
    done    

    sync

    rm -rf ${BOOT_PATH}
    rm -rf ${SYSTEM_PATH}
 }

function install_os_on_card()
{
    local dev="${1}"

    mount_card "${dev}"

    local output_dir=$(url_to_build_path ${BR_URL})/output

    echo "Copying boot files"
    cp -r ${output_dir}/images/rpi-firmware/overlays ${BOOT_PATH}
    cp ${output_dir}/images/rpi-firmware/*.dtb ${BOOT_PATH}
    cp ${output_dir}/images/rpi-firmware/bootcode.bin ${BOOT_PATH}
    cp ${output_dir}/images/rpi-firmware/fixup.dat ${BOOT_PATH}
    cp ${output_dir}/images/rpi-firmware/start.elf ${BOOT_PATH}
    cp ${output_dir}/images/zImage ${BOOT_PATH}/kernel.img

    echo "Copying system files"
    
    tar xpsf  ${output_dir}/images/rootfs.tar -C ${SYSTEM_PATH}

    unmount_card "${dev}"
}

function print_usage()
{
    echo "Usage: ${0} install DEVICE"
    echo "Usage: ${0} mount DEVICE"
    echo "Usage: ${0} unmount DEVICE"

    exit 1
}

check_root


if [[ $# != 2 ]] ; then
    print_usage
fi


cmd="$1"
device="$2"

case "$cmd" in
    install)
	unmount_card ${device}
	confirm ${device}
	partition_card ${device}
	format_card ${device}
	install_os_on_card ${device}	
	;;

    mount)
	mount_card ${device}
	echo "${device}1 is mounted in directory: ${BOOT_PATH}"
	echo "${device}2 is mounted in directory: ${SYSTEM_PATH}"
	;;

    unmount)
	unmount_card ${device}
	;;

    *)
	print_usage
	;;
esac


echo "---------"
echo "- DONE! -"
echo "---------"
