#!/bin/bash -a

#derived from to https://www.ucsc-extension.edu/courses/embedded-linux-design-and-programming/

set -e

source "paths.sh" || (echo "Failed to load environment variables, exiting." && exit 1)

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`
source "$THIS_SCRIPT_DIR/paths.sh" || (echo "Unable to load paths, exiting" && exit 1)

EMBEDDED_LINUX_PATH="$HOME/el"

ORIGINAL_BUILDROOT_DIR_NAME="buildroot"
BUILDROOT_DIR_PATH="$EMBEDDED_LINUX_PATH/$ORIGINAL_BUILDROOT_DIR_NAME"
RENAMED_BUILDROOT_DIR_NAME="buildroot.rpi4"

TARGET_DEVICE="raspberrypi4"

LOG_FILENAME="log_rpi4_configure.log"
LOG_FILE_PATH=$THIS_SCRIPT_DIR/$LOG_FILENAME

CUSTOM_KERNEL=1

#Add Env variables
#echo " "; echo "Add Environment variables:"
#export PATH=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/bin/:$PATH
#echo " "; echo "Added $PATH/bin/ to PATH env var"
#export ARCH=$X_TOOLCHAIN_ARCH
#echo " "; echo "Added $ARCH to ARCH env var"

echo " "; echo "Clear log file"
> $LOG_FILE_PATH

# Step #1: see if build root is already installed and rename it to device target
echo " "; echo "Rename $BUILDROOT_DIR_PATH to device target if it exists"
cd $EMBEDDED_LINUX_PATH

if [ -d $BUILDROOT_DIR_PATH ]; then 
	mv $ORIGINAL_BUILDROOT_DIR_NAME $RENAMED_BUILDROOT_DIR_NAME
	BUILDROOT_DIR_PATH=$EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME
	echo "buildroot directory renamed to $BUILDROOT_DIR_PATH" 2>&1 | tee log_rpi4_configure.log
else if [ -d $EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME ]; then
	echo "$ORIGINAL_BUILDROOT_DIR_NAME already renamed to device target $BUILDROOT_DIR_PATH."
	BUILDROOT_DIR_PATH=$EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME
	else
		echo "Can't find path, please install"
		exit 1
	fi
fi
#[ -d $BUILDROOT_DIR_PATH ] || { echo "no $RENAMED_BUILDROOT_DIR_NAME installed. pls install from example 1 in ch3."; exit 1; }

# Step #2: ok. it is there; list configs and set the defconfig
echo " "; echo "List and set defconfig"
cd $BUILDROOT_DIR_PATH
# { egrep -i -q ubuntu /proc/version; } && { libtoolize; }
make list-defconfigs | grep $TARGET_DEVICE

if [ $CUSTOM_KERNEL==1 ]; then 
	if [ ! -d "board/mypi64" ]; then 
		mkdir board/mypi64
	fi
	if [ ! -f "board/mypi64/bcm2711-rpi-4-b.dts" ]; then 
		cp -v /home/sergio/EmbeddedLinuxDesign/Kernel/raspberrypi_linuxos/arch/arm/boot/dts/bcm2711-rpi-4-b.dts board/mypi64/bcm2711-rpi-4-b.dts
	fi
	if [ ! -f "board/mypi64/bcm2711_defconfig" ]; then 
		cp -v /home/sergio/EmbeddedLinuxDesign/Kernel/raspberrypi_linuxos/arch/arm64/configs/bcm2711_defconfig board/mypi64/bcm2711_defconfig
	fi
fi

echo "Write "$TARGET_DEVICE"_64_defconfig to .config"
make "$TARGET_DEVICE"_64_defconfig

#Add other features
echo " "; echo "Add other features in menuconfig"
echo " "; read -p "Press enter to launch menuconfig:" go
make menuconfig

echo " "; echo "Configuration complete, see .config"