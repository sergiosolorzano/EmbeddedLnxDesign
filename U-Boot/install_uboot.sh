#!/bin/bash
#Script to install u-boot for arch rpi4 and copy files to SD card

set -e

MAKE_CORES=14

REGENERATE_ALL=1 #1=regenerates all main builds

UBOOT_TARGET_ARCHICTURE="rpi4"
UBOOT_DEFCONFIG_FILE="rpi_4_defconfig"
BOOTLOADER_CONFIG_FILE_SRC="bootloader_config_src.txt"

X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED="aarch64-rpi4-linux-gnu"
X_TOOLCHAIN_DIRECTORY="$HOME/x-tools"
X_TOOLCHAIN_ARCH="arm64"

#Variables
ROOT_UBOOT_DIR="`pwd`"
UBOOT_DIR="u-boot" #install git repo here
ROOT_UBOOT_TOOL_LIBS_DIR="src"

RPI_BOOTLOADER="bootcode.bin"

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`

PKGLIST="" #lib package list for toolchain installation
UBOOT_GIT_REPO="https://source.denx.de/u-boot/u-boot.git"
UBOOT_USER_VERSION=""

TARGET_DEVICE="" #USB device to format SD card
UTILITIES_DIRECTORY="$THIS_SCRIPT_DIR/../Utilities"
FORMAT_DEVICE_SCRIPT="format-sdcard.sh"
MOUNT_BOOT_DIRECTORY="/media/sergio/boot"
#MOUNT_ROOTFS_DIRECTORY="/media/sergio/rootfs"

echo " "; echo "-----------------------------------------------------"
echo " "
echo "CREATE U-BOOT AND COPY FILES TO TO SD CARD"
echo " "

#Get user input as to what u-boot branch is preferred
while getopts v:f: flag
do
    case "${flag}" in
        v) UBOOT_USER_VERSION=${OPTARG};;
        f) BOOTLOADER_CONFIG_FILE_SRC=${OPTARG};;
    esac
done

if [[ -z "$UBOOT_USER_VERSION" ]] ; then 
  echo "Execute this shell script by optionally providing u-boot git version, default is Master.";
  echo "You can also provide a bootloader config file, default is the file in this folder bootloader_config_source_file.txt";
  echo  "Example: Use ./$THIS_SCRIPT_NAME -v v2023.01 -f bootloader_config_source_file.txt"
  echo " "; read -p "Exit script and re-execute with your preferred version? (y/n)?" choice
  case "$choice" in 
    y|Y ) echo "yes. Exiting."; exit 1;;
    n|N ) echo "no, continue with master branch."; UBOOT_USER_VERSION="master";;
    * ) echo "invalid choice, exiting."; exit 1;;
  esac
fi

#Ensure user provides bootloader config file name
if [[ -z "$BOOTLOADER_CONFIG_FILE_SRC" ]] ; then
  echo " "
  echo "Script requires bootloader config file.";
  echo  "Example: Use ./$THIS_SCRIPT_NAME -v v2023.01 -f bootloader_config_source_file.txt"
fi

echo " "; echo "This script will build U-boot bootloader and copy the relevant files to an SD card."; echo " "; echo "The script is work in progress tested for rpi4 on Ubuntu 22.04"
echo " "; echo "Bootloader arch and triplet for x-tool:"
echo "Arch: $UBOOT_TARGET_ARCHICTURE"
echo "x-tool triplet: $X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED at $X_TOOLCHAIN_DIRECTORY"

if [ $REGENERATE_ALL ==  1 ]; then
  #set dir permissions
  sudo chmod a+rwx $THIS_SCRIPT_DIR

  #ask user to format sd-card
  echo " "; read -p "Format SD card? (y/n)?" format
  case "$format" in 
    y|Y|yes|Yes|YES ) read -p "yes. SD card will be formated. Insert the SD card and press Enter:" keypressed;;
    n|N|No|NO ) read -p "no. SD card will not be formated. Insert SD card to load up u-boot files then press enter." keypressed;;
    * ) echo "invalid choice, exiting."; exit 1;;
  esac

  #Format SD card
  if [[ "$format" =~ ^(y|Y|Yes|yes|YES)$ ]]; then 
    echo "Stand by, detecting SD card."
    sleep 5
    echo " "; echo "These are the available devices:"
    lsblk -f

    echo " "; read -p "Enter device name (e.g. sdb) to format SD card with boot and rootfs partitions:" TARGET_DEVICE

    echo " "; read -p "Continue to format device $TARGET_DEVICE? (y/n)?" cont
    case "$cont" in 
      y|Y|yes|Yes|YES ) echo "yes.";;
      n|N|No|NO ) echo "no. Exiting"; exit 1;;
      * ) echo "invalid choice, exiting."; exit 1;;
    esac
   
   #execute format script
    $UTILITIES_DIRECTORY/$FORMAT_DEVICE_SCRIPT $TARGET_DEVICE

    echo " "; echo "Formatting $TARGET_DEVICE done."

    echo " "; read -p "Remove and re-insert SD card. Press enter when done." presskey
    echo "Detecting SD card, standby."
    sleep 5
    echo "Device $TARGET_DEVICE should show FAT32 boot and ext4 rootfs partitions:"
    lsblk
  else
    read -p "Enter device name (e.g. sdb) to upload u-boot files:" TARGET_DEVICE
  fi

  #Create log directory
  echo " "
  if [ ! -d "$ROOT_UBOOT_DIR"/log ]; then
    sudo mkdir -p "$ROOT_UBOOT_DIR"/log
    echo "Created log directory $ROOT_UBOOT_DIR/log"
  else
    echo "Directory "$ROOT_UBOOT_DIR"/log exists. Deleting its contents."
    sudo rm -rf "$ROOT_UBOOT_DIR"/log/{*,.[!.]*}
  fi

  ##  Download U-Boot
  if [ ! -d "$ROOT_UBOOT_DIR"/$UBOOT_DIR ]; then
    echo " "; echo "Cloning $UBOOT_GIT_REPO into directory $ROOT_UBOOT_DIR."
    sudo git clone $UBOOT_GIT_REPO #2>&1 | tee log/git_clone.log >/dev/null
    cd $ROOT_UBOOT_DIR/$UBOOT_DIR
    echo "I've cloned u-boot, current branch is:"
    git branch
  else
      echo "Skip clone: u-boot clone directory already present at branch"
      cd $ROOT_UBOOT_DIR/$UBOOT_DIR
      git branch
  fi

  #permissions required in u-boot dir
  echo "Change $ROOT_UBOOT_DIR/$UBOOT_DIR directory rights recursively"
  sudo chmod -R 777 $ROOT_UBOOT_DIR/$UBOOT_DIR

  if [ "$UBOOT_USER_VERSION" != "master" ] ; then 
    echo "Switching to branch $UBOOT_USER_VERSION"
    git checkout -f ${UBOOT_USER_VERSION}
    #2>&1 | tee  ../log/git_checkout_uboot-${UBOOT_USER_VERSION}.log >/dev/null
  fi

  #install packages
  echo " "; echo "Install required package libssl and nfs-common"
  sudo apt -y update
  sudo apt-get install libssl-dev -y
  sudo apt-get install nfs-common -y
  sudo apt-get install cifs-utils -y
  sudo apt-get install u-boot-tools -y

  #Determine config files are available for target architecture in /configs directory:
  echo "I'm at `pwd`"
  echo " "; echo "Determine config files available for $UBOOT_TARGET_ARCHICTURE in /configs directory:"
  ls -la configs/ | grep rpi
  #TODO - CHECK FILE EXISTS FOR MY UBOOT_RAGET)_ARCHITECTURE

  #The CROSS_COMPILE variable U-Boot compile process uses triplet at the path where x-tools installed. 
  #Now we add a toolchain created using CrosstoolNG to your path and export ARCH and CROSS_COMPILE 
  #variables ready to  compile U-Boot, Linux, Busybox and anything else using the Kconfig/Kbuild scripts:
  #Add env variables
  echo " "; echo "Adding Environment Variables:"
  echo "The CROSS_COMPILE variable U-Boot compile process uses triplet at the path where x-tools installed. "
  echo "Now we add a toolchain created using CrosstoolNG to your path and export ARCH and CROSS_COMPILE "
  echo "variables ready to  compile U-Boot, Linux, Busybox and anything else using the Kconfig/Kbuild scripts:"

  PATH=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/bin/:$PATH
  echo " "; echo "Added $X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/bin/ to PATH env var"
  export CROSS_COMPILE=$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED-
  echo " "; echo "Added $X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED- to CROSS_COMPILE env var"
  export ARCH=$X_TOOLCHAIN_ARCH
  echo " "; echo "Added $X_TOOLCHAIN_ARCH to ARCH env var"
  echo " "

  #Make clean
  echo " "; echo "Make clean"
  make -j$MAKE_CORES clean

  #Create u-boot config file
  echo " "; echo "Create u-boot config file with $UBOOT_DEFCONFIG_FILE"
  make -j$MAKE_CORES $UBOOT_DEFCONFIG_FILE

  #make u-boot
  echo " "; echo "Make u-boot"
  make -j$MAKE_CORES

  echo " "; echo "Copy $THIS_SCRIPT_DIR/u-boot/u-boot.bin into SD card mount"
  if [ -f $MOUNT_BOOT_DIRECTORY/u-boot.bin ]; then
    echo " ";echo "Delete u-boot.bin from SD card"
    sudo rm $MOUNT_BOOT_DIRECTORY/u-boot.bin
  fi

  if [ ! -f $MOUNT_BOOT_DIRECTORY/u-boot.bin ]; then
    sudo cp  $THIS_SCRIPT_DIR/u-boot/u-boot.bin $MOUNT_BOOT_DIRECTORY
  fi

  if [ -f $MOUNT_BOOT_DIRECTORY/$RPI_BOOTLOADER ]; then
    echo " ";echo "Delete $MOUNT_BOOT_DIRECTORY/$RPI_BOOTLOADER from SD card"
    sudo rm $MOUNT_BOOT_DIRECTORY/$RPI_BOOTLOADER
  fi

  echo " "; echo "Copy $THIS_SCRIPT_DIR/../firmware_boot/$RPI_BOOTLOADER into SD card mount"
  if [ ! -f $MOUNT_BOOT_DIRECTORY/$RPI_BOOTLOADER ]; then
    sudo cp  $THIS_SCRIPT_DIR/../firmware_boot/$RPI_BOOTLOADER $MOUNT_BOOT_DIRECTORY
  fi

  if [ -f "$THIS_SCRIPT_DIR"/config.txt ]; then
    echo " ";echo "Delete "$THIS_SCRIPT_DIR"/config.txt from SD card"
    sudo rm "$THIS_SCRIPT_DIR"/config.txt
  fi

  echo " "; echo "Delete config.txt if it exists and create u-boot config file and add u-boot arguments to it."
  if [[ ! -z "$THIS_SCRIPT_DIR"/config.txt ]] ; then 
  sudo rm $THIS_SCRIPT_DIR/config.txt
  fi

  sudo cp -v $THIS_SCRIPT_DIR/$BOOTLOADER_CONFIG_FILE_SRC $THIS_SCRIPT_DIR/config.txt
  #sudo chmod -R 777 $THIS_SCRIPT_DIR/config.txt
  sudo cat <<< ' 
  enable_uart=1
  arm_64bit=1
  kernel=u-boot.bin' >> $THIS_SCRIPT_DIR/config.txt

  echo " "; echo "Copy bootloader config.txt file to SD card mount $MOUNT_BOOT_DIRECTORY"
  sudo cp -v $THIS_SCRIPT_DIR/config.txt $MOUNT_BOOT_DIRECTORY

fi

#updatedb
echo " "; echo "Update db with new file names to use by locate"
sudo updatedb

echo "Files in boot"
lsblk -f
ls $MOUNT_BOOT_DIRECTORY -l

echo " "; echo "End of $THIS_SCRIPT_NAME Script"










# notes



  #Create mnt/boot and mnt/rootfs directories
  #if [ ! -d "$MOUNT_BOOT_DIRECTORY" ]; then
   # sudo mkdir -p $MOUNT_BOOT_DIRECTORY
    #sudo chmod a+rwx $MOUNT_BOOT_DIRECTORY
    #echo "Created mount Directory $MOUNT_BOOT_DIRECTORY"
  #fi
  #if [ ! -d "$MOUNT_ROOTFS_DIRECTORY" ]; then
   # sudo mkdir -p $MOUNT_ROOTFS_DIRECTORY
    #sudo chmod a+rwx $MOUNT_ROOTFS_DIRECTORY/..
    #echo "Created mount Directory $MOUNT_ROOTFS_DIRECTORY"
  #fi
