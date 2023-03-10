#!/bin/bash
#Script to install linux kernel

set -e

MAKE_CORES=14

REGENERATE_ALL=1 #1=regenerates all main builds

X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED="/usr/bin/arm-linux-gnueabihf"

KERNEL_ARCH="arm"
KERNEL_DEFAULT_CONFIG_FILE="bcm2711_defconfig" #this is raspberry pi config file used
IMAGE_NAME="zImage"
KERNEL="kernel7"

#Variables
ROOT_UBOOT_DIR="${HOME}/EmbeddedLinuxDesign/U-Boot"
UBOOT_DIR="u-boot" #git repo installed here
UBOOT_BOOTARGS_FILENAME="cmdline.txt" #not copy to sd: when we create the root filesystem we grep this cmd line and add it to the .scr file.
KERNEL_ADDR_R="0x00080000"
RAMDISK_ADDR_R="0x02700000"
FDT_ADDR="2eff2d00"

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`

RASPBERRYPI_LINUXOS_GIT_REPO="https://github.com/raspberrypi/linux.git"
RASPBERRYPI_LINUXOS_DIRECTORY_NAME="raspberrypi_linuxos"

#RASPBERRYPI_FIRMWARE_GIT_REPO="https://github.com/raspberrypi/firmware.git"
RASPBERRYPI_FIRMWARE_GIT_REPO="https://github.com/raspberrypi/firmware/trunk/boot"
RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY="firmware_boot"

RASPBERRYPI_PROCESSOR="BCM2711"
PROCESSOR_SOC="broadcom"

TARGET_DEVICE_PARTITION="" #USB device with SD card boot partition
MOUNT_BOOT_DIRECTORY="/media/sergio/boot"
ROOT_PARTITION="/dev/mmcblk0p2"
#MOUNT_ROOTFS_DIRECTORY="/mnt/rpi_custom_kernel/rootfs"
UTILITIES_DIRECTORY="../Utilities"

#Target files to copy to SD card
DTB_RPI_FILE="bcm2711-rpi-4-b.dtb"


#function delete file
delete_file(){
  locate file=$1
  echo "Incoming file $file"
  if [ -f $file ]; then
  sudo rm -v $file
  else
    echo "File $file did not exist."
  fi
}

delete_device_tree_rpios(){
  echo " "; echo "Delete *dtb * overlays/*.dtbo from raspberry pi cloned boot firmware"
    for file in $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/dts/$PROCESSOR_SOC/*.dtb; do
      delete_file "$file"
    done
    for file in $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/dts/$PROCESSOR_SOC/kernel*; do
      delete_file "$file"
    done
    for file in $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/dts/overlays/*.dtbo; do
      delete_file "$file"
    done
}

delete_device_tree_rpi_firmware(){
  echo " "; echo "Delete *dtb * overlays/*.dtbo from raspberry pi cloned boot firmware"
    for file in $THIS_SCRIPT_DIR/../$RASPBERRYPI_LINUXOS_DIRECTORY_NAME//*.dtb; do
      delete_file "$file"
    done
    for file in $THIS_SCRIPT_DIR/../$RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY/kernel*; do
      delete_file "$file"
    done
    for file in $THIS_SCRIPT_DIR/../$RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY/overlays/*.dtbo; do
      delete_file "$file"
    done
}


#Disclaimer
echo " "; echo "-----------------------------------------------------"
echo "CREATE LINUX KERNEL AND COPY FILES TO SD CARD"
echo " "
echo " "; echo "This script will cross-compile linux kernel using compiler/toolset crosstoolNG."; echo " "; echo "The script is work in progress tested for rpi4 on Ubuntu 22.04"
#echo "Toolchain Arch: $X_TOOLCHAIN_ARCH"
echo "Kernel Arch: $KERNEL_ARCH"
echo "crosstool triplet: $X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED"
echo "Kernel config file used for $RASPBERRYPI_PROCESSOR-based models (ARM64) will be raspberrypiOS $KERNEL_DEFAULT_CONFIG_FILE"

echo "Files in boot"
lsblk -f
ls $MOUNT_BOOT_DIRECTORY -l

#mount usb device
#echo " "; echo "Let's mount your SD card boot partition"
#echo " "; read -p "Insert your SD card and enter the device name of the SD card with boot partition (e.g. sdb1):" TARGET_DEVICE_PARTITION

#sd_card_device=$(echo $TARGET_DEVICE_PARTITION | cut -c1-5)
#echo "sd_card_device:$sd_card_device"
#if ! findmnt /dev/$TARGET_DEVICE_PARTITION; then
#  echo "I mount $TARGET_DEVICE_PARTITION"
#  sudo mount /dev/$TARGET_DEVICE_PARTITION $MOUNT_BOOT_DIRECTORY
#fi

#Add Env variables
echo " "; echo "Added KERNEL=$KERNEL"
export KERNEL=$KERNEL
echo " "; echo "Added $PATH/bin/ to PATH env var"
export ARCH=$KERNEL_ARCH
echo " "; echo "Added $ARCH to ARCH env var"
export CROSS_COMPILE="$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED"-
echo " "; echo "Added $CROSS_COMPILE to CROSS_COMPILE env var"

if [ $REGENERATE_ALL ==  1 ]; then
  #Delete files in SD card that this cript generates
  sudo chmod a+rwx $THIS_SCRIPT_DIR
  #remove copy $UBOOT_BOOTARGS_FILENAME
  echo " ";echo "Delete from $THIS_SCRIPT_DIR $UBOOT_BOOTARGS_FILENAME"
  if test -f $THIS_SCRIPT_DIR/$UBOOT_BOOTARGS_FILENAME ; then sudo rm $THIS_SCRIPT_DIR/$UBOOT_BOOTARGS_FILENAME ; fi
  echo " ";echo "Delete from SD card boot partition files: $IMAGE_NAME - $UBOOT_BOOTARGS_FILENAME - *.dtb - overlays/*.dtbo start*.elf fixup*.dat files"
  for file in $MOUNT_BOOT_DIRECTORY/*.dtb; do
    delete_file "$file"
  done
  delete_file $MOUNT_BOOT_DIRECTORY/$IMAGE_NAME
  delete_file $MOUNT_BOOT_DIRECTORY/$UBOOT_BOOTARGS_FILENAME
  for file in $MOUNT_BOOT_DIRECTORY/start*.elf; do
    delete_file "$file"
  done
  for file in $MOUNT_BOOT_DIRECTORY/fixup*.dat; do
    delete_file "$file"
  done
  if [ -d $MOUNT_BOOT_DIRECTORY/overlays ]; then
    for file in $MOUNT_BOOT_DIRECTORY/overlays/*.dtbo; do
      delete_file "$file"
    done
  fi

  ##  Clone Raspberry Pi Firmware boot
  echo " "
  if [ ! -d "$THIS_SCRIPT_DIR"/../$RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY ]; then
    echo "Export clone $RASPBERRYPI_FIRMWARE_GIT_REPO into directory $THIS_SCRIPT_DIR/.."
    cd $THIS_SCRIPT_DIR/..
    sudo svn export $RASPBERRYPI_FIRMWARE_GIT_REPO #2>&1 | tee log/git_clone.log >/dev/null
    sudo mv boot $RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY
    cd $THIS_SCRIPT_DIR
    echo "I've cloned Raspberry Pi boot Firmware, renamed to $RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY."
    
  else
    echo "Skip Raspberry Pi boot Firmware clone: clone directory already present at branch"
  fi

  echo " "; echo "Delete dtb, dtbo, kernel image files from raspberry pi firmware to regenerate them at make" 
  delete_device_tree_rpi_firmware

  echo " "
  echo "i'm at $PWD"
  #Clone RaspberryPi linux OS
  if [ ! -d "$THIS_SCRIPT_DIR"/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME ]; then
    echo "Clone Raspberry Pi OS depth=1 to get system files."
    echo "Cloning $RASPBERRYPI_LINUXOS_GIT_REPO into directory $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME"
    sudo git clone --depth=1 $RASPBERRYPI_LINUXOS_GIT_REPO
    sudo mv $THIS_SCRIPT_DIR/linux $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME
    #cd $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME
    #git checkout rpi-5.15.y
    #cd $THIS_SCRIPT_DIR
    echo "I've cloned Raspberry Pi Linux OS, current branch is:"
    git branch
  else
    echo "Skip Raspberry Pi Linux OS clone: clone directory already present at branch"
  fi

  #delete dtb, dtbo, kernel image files from raspberry pi OS cloned source - this is where they are stored when I rebuild them
  echo " "; echo "Delete dtb, dtbo, kernel image files from raspberry pi OS to regenerate them at make"
  delete_device_tree_rpios

  #install menuconfig required libraries
  echo " "; echo "Install menuconfig required libraries"
  sudo apt -y update
  sudo apt install libncurses5-dev flex bison libgmp3-dev libmpc-dev subversion
  #sudo apt-get install libgmp3-dev

  ### Raspberry Pi kernel build
  cd $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME
  #clean files
  echo " "; echo "Clean files - distclean"
  sudo make -j$MAKE_CORES distclean

  #Show default config file to use to build Kernel
  echo " "; echo "We use raspberry pi default config file." 
  echo "Kernel build config file used for $KERNEL_ARCH located at $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/configs/$KERNEL_DEFAULT_CONFIG_FILE"

  echo " "; echo "Configure Linux with config file $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/configs/$KERNEL_DEFAULT_CONFIG_FILE"
  sudo make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE $KERNEL_DEFAULT_CONFIG_FILE

  #not using menuconfig
  #make menuconfig

  #Build linux kernel
  echo " "; echo "Build kernel Image"
  sudo make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE $IMAGE_NAME

  #Build modules
  echo " "; echo "Build modules"
  sudo make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE modules

  #Build dtbs
  echo " "; echo "Build dtbs"
  sudo make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs

  echo " "; echo "Copy Image File to SD card"
  sudo cp -v $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/$IMAGE_NAME $MOUNT_BOOT_DIRECTORY

  echo " "; echo "Copy dtb Files to SD card"
  sudo cp -v $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/dts/$DTB_RPI_FILE $MOUNT_BOOT_DIRECTORY

  echo " "; echo "Copy dtbo Files to SD card"
  echo "Copy overlays dtbo from $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/dts/overlays/*.dtbo to $MOUNT_BOOT_DIRECTORY/overlays"
  if [ ! -d $MOUNT_BOOT_DIRECTORY/overlays ]; then
    sudo mkdir $MOUNT_BOOT_DIRECTORY/overlays
  fi
  sudo cp -v $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/dts/overlays/*.dtbo $MOUNT_BOOT_DIRECTORY/overlays

  echo "Copy start*.elf fixup*.dat files from raspberry pi firmware boot to SD card mount $MOUNT_BOOT_DIRECTORY"
  sudo cp -v $THIS_SCRIPT_DIR/../$RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY/start*.elf $MOUNT_BOOT_DIRECTORY
  sudo cp -v $THIS_SCRIPT_DIR/../$RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY/fixup*.dat $MOUNT_BOOT_DIRECTORY
  sudo cp -v $THIS_SCRIPT_DIR/../$RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY/bootcode.bin $MOUNT_BOOT_DIRECTORY

  echo " "; echo "Create $UBOOT_BOOTARGS_FILENAME and copy to SD card"
  sudo touch $THIS_SCRIPT_DIR/$UBOOT_BOOTARGS_FILENAME
  sudo chmod -R 777 $THIS_SCRIPT_DIR/$UBOOT_BOOTARGS_FILENAME
  sudo cat <<< 'console=serial0,115200 console=tty1 root='$ROOT_PARTITION' rootfstype=ext4 rootwait' >> $THIS_SCRIPT_DIR/$UBOOT_BOOTARGS_FILENAME
  sudo mv $THIS_SCRIPT_DIR/$UBOOT_BOOTARGS_FILENAME $MOUNT_BOOT_DIRECTORY

  echo "Copy config.txt to boot mount"
  cp $THIS_SCRIPT_DIR/config.txt $MOUNT_BOOT_DIRECTORY

fi

#echo "Files in mount BEFORE"
#ls $MOUNT_BOOT_DIRECTORY -l

#unmount sd card boot partition e.g. dev/sdb1
#echo " "; echo "Unmount $TARGET_DEVICE_PARTITION"
#for partition in sd_card_device?*; do
#    if mount | grep -q $partition; then
#      echo "SD found. Unmount $partition"
#      sudo umount $partition
#    else
#      echo "Partition $partition is already unmounted, skip."
#    fi
#done
#echo "Files in mount AFTER"
#ls $MOUNT_BOOT_DIRECTORY -l

echo " "; echo "End of $THIS_SCRIPT_NAME script"