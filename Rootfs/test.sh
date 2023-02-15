#!/bin/bash
#Script to install linux root file system

set -e

MAKE_CORES=12

X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED="aarch64-rpi4-linux-gnu"
X_TOOLCHAIN_DIRECTORY="$HOME/x-tools"

KERNEL_ARCH="arm64"
KERNEL_DEFAULT_CONFIG_FILE="bcm2711_defconfig" #this is raspberry pi config file used
IMAGE_NAME="Image"
RASPBERRYPI_PROCESSOR="BCM2711"
RASPBERRYPI_LINUXOS_GIT_REPO="https://github.com/raspberrypi/linux.git"

#Variables
ROOT_UBOOT_DIR="${HOME}/EmbeddedLinuxDesign/U-Boot"
UBOOT_DIR="u-boot" #git repo installed here

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`

ROOTFS_ROOT_DIR="rootfs"

BUSYBOX_DIR="busybox"
BUSYBOX_GIT_REPO="git://busybox.net/busybox.git"
BUSYBOX_CHECKOUT_BRANCH="1_36_stable"
BUSYBOX_LOG_FILENAME="log_busybox.txt"
BUSYBOX_LOG_FILENAME_PATH=$THIS_SCRIPT_DIR

SYSROOT="" #toolchain sysroot directory path
PATH=$HOME/x-tools/aarch64-rpi4-linux-gnu/bin/:$PATH
SYSROOT=$(aarch64-rpi4-linux-gnu-gcc -print-sysroot)

#aarch64-rpi4-linux-gnu-readelf -a rootfs/bin/busybox | grep "program interpreter"

$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED-readelf -a $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox | grep "program interpreter"
echo "Find library dependencies (readelf) for keyword -Shared library-"
$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED-readelf -a $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox | grep "Shared library"

cd $SYSROOT
echo "Show me the library lib/ld-linux-aarch64.so.1 in $SYSROOT"
ls -l "lib/ld-linux-aarch64.so.1"

echo "Show me the library lib/ld-linux-aarch64.so.1 in $SYSROOT"
ls -l "lib/libm.so.6"

echo "Show me the library lib64/libresolv.so.2 in $SYSROOT"
ls -l "lib64/libresolv.so.2"

echo "Show me the library lib64/libc.so.6 in $SYSROOT"
ls -l "lib64/libc.so.6"