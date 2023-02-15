#!/bin/bash
# Format a microSD card for the BeagelBone Black
# Mastering Embedded Linux Programming
# Copyright (c) Chris Simmonds, 2017

SD_CARD_SIZE=124669952 #12669952=64GiB; 64000000=32GiB

echo "Run Tests this target is indeed and SD card!"
if [ $# -ne 1 ]; then #test number of arguments received is 1
        echo "Usage: $0 [drive]"
        echo "       drive is 'sdb', 'mmcblk0', etc"
        exit 1
else echo "OK"
fi

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

DRIVE=$1

# Check the drive exists in /sys/block
if [ ! -e /sys/block/${DRIVE}/size ]; then
        echo "Check 1 - Fail: Drive does not exist in sys/block/${DRIVE}/size"
        exit 1
else
        echo "Check 1 - Pass: Drive exists in sys/block/${DRIVE}/size."
fi

# Check it is a flash drive (size < 32GiB, 64GiB etc set SD_CARD_SIZE)
NUM_SECTORS=`cat /sys/block/${DRIVE}/size`
if [ $NUM_SECTORS -eq 0 -o $NUM_SECTORS -gt $SD_CARD_SIZE ]; then
        echo "Check 2 - Fail: /dev/$DRIVE does not look like an SD card, bailing out"
        exit 1
else
        echo "Check 2 - Pass: looks like an SD card by size $((12669952/2))"
fi

echo " "; echo "TODO user choice with exit to Delete existing partitions. User would execute sudo fdisk /dev/sdb"
#sudo dmesg | tail
#sudo fdisk /dev/sdb

echo " "; echo "Starting point:"
lsblk

# Unmount any partitions that have been automounted
echo " "; echo "Unmount any partitions that have been automounted"
if [ $DRIVE != "sdb" ]; then
        echo "Drive is not sdb"
    sudo umount /dev/${DRIVE}*
    BOOT_PART=/dev/${DRIVE}p1
    ROOT_PART=/dev/${DRIVE}p2
else
        echo "Drive is sdb"
    sudo umount /dev/${DRIVE}[1-9]
    BOOT_PART=/dev/${DRIVE}1
    ROOT_PART=/dev/${DRIVE}2
fi

# Overwite any existing partiton table with zeros
echo " "; echo "Overwite any existing partiton table with zeros"
sudo dd if=/dev/zero of=/dev/${DRIVE} bs=1M count=10
if [ $? -ne 0 ]; then echo "Error: dd"; exit 1; fi

# Create 2 primary partitons on the sd card
#  1: FAT32, 1024 MiB, boot flag, will hold bootloader
#  2: Linux is EXT4, 1024 MiB will hold file root sys
# Note that the parameters to sfdisk changed slightly v2.26
echo " "
SFDISK_VERSION=`sfdisk --version | awk '{print $4}'`
if version_gt $SFDISK_VERSION "2.26"; then
        echo "SFDISK_VERSION=2.26"
        sudo sfdisk /dev/${DRIVE} << EOF
,1024M,0x0c,*
,1024M,L,
EOF
else
        echo "SFDISK_VERSION!=2.26. Creating 2 primary partitons on the sd card 1: FAT32, 1024 MiB, boot flag; 2: Linux, 1024 MiB"
        sudo sfdisk --unit M /dev/${DRIVE} << EOF
,1024,0x0c,*
,1024,L,
EOF
fi
if [ $? -ne 0 ]; then echo "Error: sdfisk"; exit 1; fi

# Format p1 with FAT32 and p2 with ext4
echo " "; echo "Format $DRIVE 1 with FAT32 and $DRIVE 2 with ext4"
echo "p1:$BOOT_PART"
echo "p2:$ROOT_PART"
sudo mkfs.vfat -F 16 -n boot ${BOOT_PART}
if [ $? -ne 0 ]; then echo "Error: mkfs.vfat"; exit 1; fi
sudo mkfs.ext4 -L rootfs ${ROOT_PART}
if [ $? -ne 0 ]; then echo "Error: mkfs.ext4"; exit 1; fi

echo "SUCCESS! Your microSD card has been formatted"
lsblk
exit 0

