#!/bin/bash
#Script to install linux root file system

set -e

MAKE_CORES=14

REGENERATE_ALL=1 #1=regenerates all main builds

MOUNT_BOOT_DIRECTORY="/media/sergio/boot"
MOUNT_ROOTFS_DIRECTORY="/media/sergio/rootfs"

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`

X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED="aarch64-rpi4-linux-gnu"
#X_TOOLCHAIN_DIRECTORY="$HOME/x-tools"
X_TOOLCHAIN_DIRECTORY="/usr/local/bin/x-tools"

KERNEL_ARCH="arm64"
RASPBERRYPI_PROCESSOR="BCM2711"
RASPBERRYPI_LINUXOS_GIT_REPO="https://github.com/raspberrypi/linux.git"
RASPBERRYPI_LINUXOS_DIRECTORY_PATH="../Kernel/raspberrypi_linuxos"

ROOTFS_ROOT_DIR="rootfs"
ROOTFS_PATH="/home/sergio/EmbeddedLinuxDesign/Rootfs/rootfs"

rcS_FILENAME="rcS"

BUSYBOX_DIR="busybox"
BUSYBOX_GIT_REPO="git://busybox.net/busybox.git"
BUSYBOX_CHECKOUT_BRANCH="1_35_stable"
BUSYBOX_LOG_FILENAME="log_busybox.txt"
BUSYBOX_LOG_FILENAME_PATH=$THIS_SCRIPT_DIR
USE_INTRAMFS=0

SYSROOT="" #toolchain sysroot directory path

STANDALONE_INITRAMFS_IMAGE="uRamdisk"
STANDALONE_INITRAMFS_IMAGE_NAME="InitramfsImage"
RAMDISK_ADDR_R="0x02700000"

#Disclaimer
echo " "; echo "-----------------------------------------------------"
echo "CREATE ROOT FILESYSTEM AND CREATE BOOT INITRAMFS AND COPY TO SD CARD"
echo " "
echo " "; echo "This script will install busybox to cross-compile linux kernel"
echo "Toolchain Arch: $KERNEL_ARCH"
echo "Kernel Arch: $KERNEL_ARCH"
#echo "crosstoolNG triplet: $X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED at $X_TOOLCHAIN_DIRECTORY"
echo "Kernel config file used for $RASPBERRYPI_PROCESSOR-based models (ARM64) linux kernel cloned from git $RASPBERRYPI_LINUXOS_GIT_REPO"

#Add Env variables
echo " "; echo "Add Environment variables:"
#PATH=/usr/local/bin/x-tools/aarch64-rpi4-linux-gnu/bin/:$PATH
#echo " Path: $PATH"
PATH=$HOME/x-tools/aarch64-rpi4-linux-gnu/bin/:$PATH
echo " "; echo "Added $PATH/bin/ to PATH env var"
export ARCH=$KERNEL_ARCH
echo " "; echo "Added $ARCH to ARCH env var"
export CROSS_COMPILE='/home/sergio/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-'
echo " "; echo "Added $CROSS_COMPILE to CROSS_COMPILE env var"

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
	cd $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_PATH
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
	make -j$MAKE_CORES CROSS_COMPILE=$CROSS_COMPILE defconfig 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#make -j$MAKE_CORES CROSS_COMPILE='/usr/local/bin/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-' defconfig 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#sed -i 's%^CONFIG_PREFIX=.*$%CONFIG_PREFIX='"$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR"'%' .config
	#sed -i 's%^CONFIG_PREFIX=.*$%CONFIG_PREFIX='"/home/sergio/EmbeddedLinuxDesign/Rootfs/rootfs"'%' .config
	make menuconfig

	echo " " 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME";
	echo " " 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"; echo "Cross compile busybox" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	echo "ARCH is $KERNEL_ARCH and CROSS_COMPILE is $CROSS_COMPILE"
	#make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#make -j$MAKE_CORES ARCH='arm64' CROSS_COMPILE='/usr/local/bin/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-' CONFIG_PREFIX='/home/sergio/EmbeddedLinuxDesign/Rootfs/rootfs' 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$ROOTFS_PATH 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	
	echo " "; echo "Install Busybox. Install Path is $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#sudo make -j$MAKE_CORES ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILE" CONFIG_PREFIX=$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR install #2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	#sudo make -j$MAKE_CORES ARCH='arm64' CROSS_COMPILE='/usr/local/bin/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-' CONFIG_PREFIX='/home/sergio/EmbeddedLinuxDesign/Rootfs/rootfs' install 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	sudo make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$ROOTFS_PATH install 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	
fi

#Get Libraries for the file system
echo " "; echo "Get the sysroot directory path of the x-toolchain"
#/usr/local/bin/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-gcc -print-sysroot
"$CROSS_COMPILE"gcc -print-sysroot
#/home/sergio/x-tools/aarch64-rpi4-linux-gnu/aarch64-rpi4-linux-gnu/sysroot
echo "Add the sysroot directory path to env variable SYSROOT"
#SYSROOT=$(/usr/local/bin/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-gcc -print-sysroot)
SYSROOT=$("$CROSS_COMPILE"gcc -print-sysroot)

echo " "; echo "Find the libraries required by apps in our board, in this case busybox and copy these libraries to $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR."
echo " "; echo "Show me the busybox program library dependencies found in busybox binary that I've created in the root filesystem $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox"
find $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR -name "*so*" -type f -delete

cd $SYSROOT 
echo " "; echo "Library dependencies found in busybox bin with words -program interpreter-" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
#lib=$(/usr/local/bin/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-readelf -a $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox | grep "program interpreter" | rev | cut -d' ' -f1 | tr -d '][' | rev)
lib=$("$CROSS_COMPILE"readelf -a $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox | grep "program interpreter" | rev | cut -d' ' -f1 | tr -d '][' | rev)
echo "$lib"
echo " "; echo "Copy these libraries and symbolic links:"
sudo cp -v -a $SYSROOT$lib $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/lib 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
echo $?

echo " "; echo "Library dependencies found in busybox bin with words -Shared library-" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
#libs=$(/usr/local/bin/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu-readelf -a $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/bin/busybox | awk '{print NR, $0}' | grep "Shared library" | rev | cut -d' ' -f1 | tr -d '][' | rev)
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

echo "Mount proc and sysfs in $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
if ! [ -d "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/proc" ]; then
        sudo mount -t proc proc /proc
        echo "Mounted $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/proc" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
else 
        echo "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/proc already mounted, skip" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
fi

if ! [ -d "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/sys" ]; then
        sudo mount -t sysfs sysfs /sys
	echo "Mounted $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/sys" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
else 
        echo "$THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR/sys already mounted, skip" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
fi

if [ USE_INTRAMFS == 1 ]; then
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

	#copy intramfs image to SD card boot
	echo " "; echo "Copy $THIS_SCRIPT_DIR/$STANDALONE_INITRAMFS_IMAGE to SD card" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	sudo cp -v $THIS_SCRIPT_DIR/$STANDALONE_INITRAMFS_IMAGE $MOUNT_BOOT_DIRECTORY
	echo $?
else
	#copy rootfs to SD card boot
	echo " "; echo "Copy $THIS_SCRIPT_DIR/$ROOTFS_ROOT_DIR to SD card" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"
	sudo cp -v -r $THIS_SCRIPT_DIR/"$ROOTFS_ROOT_DIR"/* $MOUNT_ROOTFS_DIRECTORY
	echo $?
fi

echo " "; echo "Update db with new file names to use by locate"
sudo updatedb

echo "End of $THIS_SCRIPT_NAME script" 2>&1 | tee -a "$BUSYBOX_LOG_FILENAME_PATH/$BUSYBOX_LOG_FILENAME"