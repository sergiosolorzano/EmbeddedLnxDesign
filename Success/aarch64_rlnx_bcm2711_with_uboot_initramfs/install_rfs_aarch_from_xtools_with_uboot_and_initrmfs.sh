#!/bin/bash
#Script to install linux root file system

set -e

MAKE_CORES=8

REGENERATE_ALL=1 #1=regenerates all main builds

MOUNT_BOOT_DIRECTORY="/media/sergio/boot"
MOUNT_ROOTFS_DIRECTORY="/media/sergio/rootfs"

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`

X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED="aarch64-rpi4-linux-gnu"
X_TOOLCHAIN_DIRECTORY="$HOME/x-tools"

KERNEL_ARCH="arm64"
RASPBERRYPI_PROCESSOR="BCM2711"

RASPBERRYPI_LINUXOS_GIT_REPO="https://github.com/raspberrypi/linux.git"
RASPBERRYPI_LINUXOS_DIRECTORY_PATH="$THIS_SCRIPT_DIR/../Kernel/raspberrypi_linuxos"

#Variables
ROOT_UBOOT_DIR="$THIS_SCRIPT_DIR/../U-Boot"
UBOOT_DIR="u-boot" #git repo installed here

UBOOT_INITRAMFS_CONFIG_FILENAME="boot_cmd.txt" #holds instructors for u-boot on rfs, busybox converts to image
UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME="boot.scr"
UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME_IMGNAME="boot-scr-Image"

ROOTFS_ROOT_DIR="rootfs" 			#/home/sergio/EmbeddedLinuxDesign/Rootfs/rootfs
ROOTFS_PATH="/home/sergio/EmbeddedLinuxDesign/Rootfs/rootfs"

rcS_FILENAME="rcS"

BUSYBOX_DIR="busybox"
BUSYBOX_GIT_REPO="git://busybox.net/busybox.git"
BUSYBOX_CHECKOUT_BRANCH="1_35_stable"
BUSYBOX_LOG_FILENAME="log_busybox.txt"
BUSYBOX_LOG_FILENAME_PATH=$THIS_SCRIPT_DIR

SYSROOT="" #toolchain sysroot directory path

STANDALONE_INITRAMFS_IMAGE="uRamdisk"
STANDALONE_INITRAMFS_IMAGE_NAME="InitramfsImage"
RAMDISK_ADDR_R="0x02700000"

USE_INITRAMFS_0_OR_COPY_ROOTS_1=0

#Disclaimer
echo " "; echo "-----------------------------------------------------"
echo "CREATE ROOT FILESYSTEM AND CREATE BOOT INITRAMFS AND COPY TO SD CARD"
echo " "
echo " "; echo "This script will install busybox to cross-compile linux kernel"
echo "Toolchain Arch: $KERNEL_ARCH"
echo "Kernel Arch: $KERNEL_ARCH"
echo "crosstoolNG triplet: $X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED at $X_TOOLCHAIN_DIRECTORY"
echo "Kernel config file used for $RASPBERRYPI_PROCESSOR-based models (ARM64) linux kernel cloned from git $RASPBERRYPI_LINUXOS_GIT_REPO"

#Add Env variables
echo " "; echo "Add Environment variables:"
PATH=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/bin/:$PATH
echo " Path: $PATH"
echo " "; echo "Added $PATH/bin/ to PATH env var"
export ARCH=$KERNEL_ARCH
echo " "; echo "Added $ARCH to ARCH env var"
export CROSS_COMPILE='/home/sergio/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-'
#/home/sergio/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-
echo " "; echo "Added $CROSS_COMPILE to CROSS_COMPILE env var"


#-----------------------------
#rm boot_cmd.txt
#rm boot.scr
#sudo rm $MOUNT_BOOT_DIRECTORY/boot.scr
if [ 1 ==  1 ]; then
	echo "Ensure you have the correct name entered for the image to boot - kernel8.img, etc"
	touch $UBOOT_INITRAMFS_CONFIG_FILENAME
	#setenv bootargs console=serial0,115200 console=tty1 rdinit=/bin/sh
	cat <<< ' 
	fatload mmc 0:1 ${kernel_addr_r} kernel8.img
	fatload mmc 0:1 ${ramdisk_addr_r} uRamdisk
	setenv bootargs 8250.nr_uarts=1 console=ttyS0,115200 rdinit=/bin/sh
	booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr}' >> $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_FILENAME
	echo "no need to copy $UBOOT_INITRAMFS_CONFIG_FILENAME because we create its image"

	echo " "; echo "Make $UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME image"
	$ROOT_UBOOT_DIR/$UBOOT_DIR/tools/mkimage -A $ARCH -O linux -T script -C none -n $UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME_IMGNAME -d $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_FILENAME $UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"

	#Copy UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME to SD card
	if [ $USE_INITRAMFS_0_OR_COPY_ROOTS_1 == 0 ]; then
		echo "Copy $UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME to SD card" 
		sudo cp -v $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME $MOUNT_BOOT_DIRECTORY
		echo $?
	fi
	exit 1
fi
=-----------------------------
if [ $REGENERATE_ALL ==  1 ]; then
	#set permissions
	sudo chmod a+rwx $THIS_SCRIPT_DIR

	#install menuconfig required libraries
	echo "Update libraries"
	sudo apt -y update
	echo " "; echo "Install coreutils"
	#sudo apt install --reinstall coreutils

	#Delete existing root filesystem
	echo " "
	if [ -d $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR ]; then
		echo "Delete Root FileSystem $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR"
		sudo rm -rf $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR
	else
		echo "Can't find existing Root Filesystem directory $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR to delete."
	fi

	#Create staging directory - required to assemble files that will be transferred to target
	echo " "
	if [ ! -d $ROOTFS_ROOT_DIR ]; then
		echo "Create staging directory"
		mkdir $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR
		else
			echo "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR already exists."
	fi

	cd $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR

	#sudo mkdir bin dev etc home lib proc sbin sys tmp usr var
	echo " "; echo "Create in $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR directories bin dev etc home lib proc sbin sys tmp usr var"
	dirs=($THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/dev $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/etc $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/home $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/lib $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/proc $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/sbin $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/sys $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/tmp $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/usr $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/var)
	for dir in "${dirs[@]}"; do
	  if [ ! -d "/$dir" ]; then
	    mkdir "/$dir"
		else
		echo "Directory /$dir exists, skip."
	  fi
	done

	echo " "; echo "Create in $ROOTFS_ROOT_DIR directories usr/bin usr/lib usr/sbin"
	dirs=($THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/usr/bin $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/usr/lib $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/usr/sbin)
	for dir in "${dirs[@]}"; do
	  if [ ! -d "/$dir" ]; then
	    mkdir "/$dir"
		else
		echo "Directory /$dir exists, skip."
	  fi
	done

	dir="$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/var/log"
	if [ ! -d "$dir" ]; then
		echo " "; echo "Create in $dir directory var/log"
		mkdir -p "$dir"
	else
		echo "$dir already exists, skip."	
	fi

	echo " "; echo "Display $ROOTFS_ROOT_DIR directory tree"
	tree -d

	#Install Kernel Modules
	cd $RASPBERRYPI_LINUXOS_DIRECTORY_PATH
	sudo su -c "make modules_install"
	cd $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR

	#Create init.d and rcS
	echo " ";echo "Create init.d directory and $rcS_FILENAME file"
	sudo mkdir -p $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/etc/init.d
	sudo touch $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/etc/init.d/$rcS_FILENAME
	sudo chmod a+rwx $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/etc/init.d/$rcS_FILENAME
	sudo cat <<< ' 
	#!/bin/sh
	mount -t proc none /proc
	mount -t sysfs none /sys
	echo /sbin/mdev > proc/sys/kernel/hotplug
	mdev -s' >> $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/etc/init.d/$rcS_FILENAME
	sudo chmod +x $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/etc/init.d/$rcS_FILENAME

	#echo "Mount proc and sysfs in $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#if ! [ -d "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/proc" ]; then
	#        sudo mount -t proc proc /proc
	#        echo "Mounted $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/proc" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#else 
	#        echo "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/proc already mounted, skip" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#fi

	#if ! [ -d "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/sys" ]; then
	#        sudo mount -t sysfs sysfs /sys
	#	echo "Mounted $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/sys" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#else 
	#        echo "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/sys already mounted, skip" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#fi

	# Change the owner of the directories to be root
	# Because current user doesn't exist on target device
	echo "**I am here $PWD"

	sudo chown -R root:root $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR

	#Create log file for busybox build and install
	if [ ! -f $BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME ]; then
		echo "Create log file $BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME for busybox build and install"
		touch $BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME
	fi

	#clear file
	truncate -s 0 $BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME

	#Clone busybox
	cd $THIS_SCRIPT_DIR
	echo " "
	if [ ! -d "$BUSYBOX_DIR" ]; then
		echo "Clone Busybox repo"
		git clone $BUSYBOX_GIT_REPO
		cd $THIS_SCRIPT_DIR/$BUSYBOX_DIR
		git checkout -b 1_36_0
		git branch
		#git checkout -b $BUSYBOX_CHECKOUT_BRANCH -f
	else
		echo "BusyBox already cloned at directory $BUSYBOX_DIR, skip cloning."
	fi

	cd $THIS_SCRIPT_DIR/$BUSYBOX_DIR

	#Configure busybox
	echo " "; echo "Distclean Busybox" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	sudo make -j$MAKE_CORES distclean 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"

	echo " "; echo "Configure busybox with crosscompile $CROSS_COMPILE" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	make -j$MAKE_CORES CROSS_COMPILE='/home/sergio/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-' defconfig 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	
	echo " "; echo "Ready for manual changes in busybox menuconfig."
	echo " "; echo "- Settings -> Build static binary (no shared libraries)    .. Enable"
	echo "- Settings -> Cross compiler prefix   .. arm-Linux-gnueabihf-"
	echo "- Settings -> Destination path for ‘make install’ .. same as INSTALL_MOD_PATH above"
	echo " "; read -p "Press a key to enter menuconfig" contin
	
	make menuconfig

	echo " " 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME";
	echo " " 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"; echo "Cross compile busybox" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	echo "ARCH is $KERNEL_ARCH and CROSS_COMPILE is $CROSS_COMPILE"
	make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE='/home/sergio/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-' CONFIG_PREFIX=$ROOTFS_PATH 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	
	echo " "; echo "Install Busybox. Install Path is $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	sudo make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE='/home/sergio/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-' CONFIG_PREFIX=$ROOTFS_PATH install 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	
fi

#Get Libraries for the file system
echo " "; echo "Get the sysroot directory path of the x-toolchain"
"$CROSS_COMPILE"gcc -print-sysroot
#/home/sergio/x-tools/aarch64-rpi4-linux-gnu/aarch64-rpi4-linux-gnu/sysroot
echo "Add the sysroot directory path to env variable SYSROOT"
SYSROOT=$("$CROSS_COMPILE"gcc -print-sysroot)

echo " "; echo "Find the libraries required by apps in our board, in this case busybox and copy these libraries to $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR."
echo " "; echo "Show me the busybox program library dependencies found in busybox binary that I've created in the root filesystem $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox"
find $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR -name "*so*" -type f -delete

cd $SYSROOT 
echo " "; echo "Library dependencies found in busybox bin with words -program interpreter-" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
lib=$("$CROSS_COMPILE"readelf -a $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox | grep "program interpreter" | rev | cut -d' ' -f1 | tr -d '][' | rev)
echo "$lib"
echo " "; echo "Copy these libraries and symbolic links:"
sudo cp -v -a $SYSROOT$lib $THIS_SCRIPT_DIR/"$ROOTFS_ROOT_DIR"/lib 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
echo $?

echo " "; echo "Library dependencies found in busybox bin with words -Shared library-" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
libs=$("$CROSS_COMPILE"readelf -a $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox | awk '{print NR, $0}' | grep "Shared library" | rev | cut -d' ' -f1 | tr -d '][' | rev)
echo "$libs"
echo " "; echo "Copy these libraries and symbolic links"

#ls -l lib/libm.so.6 | rev | cut -d' ' -f1 | rev
sudo cp -v -a $SYSROOT/lib/libm.so.6 $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/lib 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
echo $?

#ls -l lib64/libresolv.so.2 | rev | cut -d' ' -f1 | rev
sudo cp -v -a $SYSROOT/lib64/libresolv.so.2 $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/lib 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
echo $?

#ls -l lib64/libc.so.6 | rev | cut -d' ' -f1 | rev
sudo cp -v -a $SYSROOT/lib64/libc.so.6 $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/lib 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
echo $?

#Create busybox required devices
echo " "; echo "Create busybox required devices:" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
cd $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR

if [ ! -e dev/null ]; then
	echo "Create null character device, permissions for everyone" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	sudo mknod -m 666 dev/null c 1 3
else
	echo "dev/null busybox device not created because it already exists." 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
fi

if [ ! -e dev/console ]; then
	echo "Create console character device, permissions only root" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	sudo mknod -m 600 dev/console c 5 1
else
	echo "dev/console busybox device not created because it already exists." 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
fi

#Transferring rootfs to the target
#Create a standalone initramfs
cd $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR
echo " "; echo "Transfer rootfs to the target: Create a standalone initramfs" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
echo "Clean files."
if [ -f $THIS_SCRIPT_DIR/initramfs.cpio ]; then
	rm -v $THIS_SCRIPT_DIR/initramfs.cpio
else
	echo "$THIS_SCRIPT_DIR/initramfs.cpio doesn't exist to delete it."
fi

if [ -f $THIS_SCRIPT_DIR/initramfs.cpio.gz ]; then
	rm -v $THIS_SCRIPT_DIR/initramfs.cpio.gz 
else
	echo "$THIS_SCRIPT_DIR/initramfs.cpio.gz doesn't exist to delete it."
fi

if [ -f $THIS_SCRIPT_DIR/$STANDALONE_INITRAMFS_IMAGE ]; then
	rm -v $THIS_SCRIPT_DIR/$STANDALONE_INITRAMFS_IMAGE
else
	echo "$THIS_SCRIPT_DIR/$STANDALONE_INITRAMFS_IMAGE doesn't exist to delete it."
fi

if [ -f $MOUNT_BOOT_DIRECTORY/$STANDALONE_INITRAMFS_IMAGE ]; then
	sudo rm -v $MOUNT_BOOT_DIRECTORY/$STANDALONE_INITRAMFS_IMAGE
else
	echo "$MOUNT_BOOT_DIRECTORY doesn't exist to delete it."
fi

echo " "; echo "Create initramfs.cpio and initramfs image" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio

cd ..
gzip initramfs.cpio

mkimage -A $ARCH -O linux -T ramdisk -d initramfs.cpio.gz -n $STANDALONE_INITRAMFS_IMAGE_NAME $STANDALONE_INITRAMFS_IMAGE 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"

#copy $STANDALONE_INITRAMFS_IMAGE tree to SD card boot
if [ $USE_INITRAMFS_0_OR_COPY_ROOTS_1 == 0 ]; then
echo " "; echo "Copy $THIS_SCRIPT_DIR/$STANDALONE_INITRAMFS_IMAGE to SD card" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
sudo cp -v $THIS_SCRIPT_DIR/$STANDALONE_INITRAMFS_IMAGE $MOUNT_BOOT_DIRECTORY
echo $?
fi

#copy rootfs to SD card boot
if [ $USE_INITRAMFS_0_OR_COPY_ROOTS_1 == 1 ]; then
	echo " "; echo "Copy $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR to SD card" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	sudo cp -v -r $THIS_SCRIPT_DIR/"$ROOTFS_ROOT_DIR"/* $MOUNT_ROOTFS_DIRECTORY
	echo $?
fi

#Create u-boot config script image
echo " "; echo "Make u-boot config script image" 
echo "Clean existing files"
if [ -f $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME ]; then
	rm -v $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME
else
	echo "$THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME doesn't exist to delete it."
fi

if [ -f $MOUNT_BOOT_DIRECTORY/$UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME ]; then
	sudo rm -v $MOUNT_BOOT_DIRECTORY/$UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME
else
	echo "$MOUNT_BOOT_DIRECTORY/$UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME doesn't exist to delete it."
fi

#Configure u-boot for booti and uRamdisk rootfs image
echo "Configure u-boot to boot with a script image with booti by creating file $UBOOT_INITRAMFS_CONFIG_FILENAME"
echo "File required to pass the correct kernel commandline and device tree binary to kernel"
echo "Busybox creates the boot image from this script."
if [ -f $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_FILENAME ]; then
  rm -v $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_FILENAME
else
  echo "$THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_FILENAME doesn't exist to delete it."
fi

echo "Ensure you have the correct name entered for the image to boot - kernel8.img, etc"
touch $UBOOT_INITRAMFS_CONFIG_FILENAME
#setenv bootargs console=serial0,115200 console=tty1 rdinit=/bin/sh
cat <<< ' 
fatload mmc 0:1 ${kernel_addr_r} kernel8.img
fatload mmc 0:1 ${ramdisk_addr_r} uRamdisk
setenv bootargs console=serial0,115200 console=ttyS0 rdinit=/bin/sh
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr}' >> $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_FILENAME
echo "no need to copy $UBOOT_INITRAMFS_CONFIG_FILENAME because we create its image"

echo " "; echo "Make $UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME image"
$ROOT_UBOOT_DIR/$UBOOT_DIR/tools/mkimage -A $ARCH -O linux -T script -C none -n $UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME_IMGNAME -d $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_FILENAME $UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"

#Copy UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME to SD card
if [ $USE_INITRAMFS_0_OR_COPY_ROOTS_1 == 0 ]; then
	echo "Copy $UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME to SD card" 
	sudo cp -v $THIS_SCRIPT_DIR/$UBOOT_INITRAMFS_CONFIG_IMAGE_FILENAME $MOUNT_BOOT_DIRECTORY
	echo $?
fi

echo " "; echo "Update db with new file names to use by locate"
sudo updatedb

echo "End of $THIS_SCRIPT_NAME script" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"