#!/bin/bash
#Script to install linux kernel

set -e

X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED="aarch64-rpi4-linux-gnu"
X_TOOLCHAIN_DIRECTORY="$HOME/x-tools"

KERNEL_ARCH="arm64"
KERNEL_SOURCE_DIRECTORY="linux-ltr2"
KERNEL_DEFAULT_CONFIG_FILE="multi_v7_defconfig" #linux config to make
RPI4_DTB="bcm2711-rpi-4-b.dtb"
KERNEL_USED="kernel8"
COMPRESSED_KERNEL_IMAGE="zImage"
KERNEL_GENERATED_ELF_FILE="vmlinux"
UIMAGE_FILENAME="L_uImage.bin"
UIMAGE_NAME="Linux_uImage"
#LOADADDR address to load uImage in physical RAM - found for mach-bcm2707 https://patchwork.kernel.org/project/linux-arm-kernel/patch/1346908038-22421-1-git-send-email-swarren@wwwdotorg.org/
#could not find Makefile.boot for mach-bcm: EmbeddedLinuxDesign/Kernel/linux-ltr/arch/arm/mach-bcm
#or EmbeddedLinuxDesign/Kernel/raspberrypi_linuxos/arch/arm/mach-bcm$
UIMAGE_LOAD_ADDRESS="0x00008000"

#Variables
RESULT_FILES_DIRECTORY="result_files"

ROOT_UBOOT_DIR="${HOME}/EmbeddedLinuxDesign/U-Boot"
UBOOT_DIR="u-boot" #install git repo here

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`

DEFAULT_LINUX_KERNEL_VERSION="5.15" #5.16 #6.2.2
DEFAULT_LINUX_KERNEL_MAJOR_VERSION="5" #5 #6
USER_SELECTED_LINUX_KERNEL_VERSION=""
#LINUX_KERNEL_GIT_REPO="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-"
LINUX_KERNEL_GIT_REPO="https://cdn.kernel.org/pub/linux/kernel/v$DEFAULT_LINUX_KERNEL_MAJOR_VERSION.x/linux-"

#RASPBERRYPI_LINUXOS_GIT_REPO="https://github.com/raspberrypi/linux.git"
#RASPBERRYPI_LINUXOS_DIRECTORY_NAME="raspberrypi_linuxos"
#RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY="firmware"
RASPBERRYPI_PROCESSOR="BCM2711"
PROCESSOR_SOC="broadcom"

TARGET_DEVICE="" #USB device with SD card
MOUNT_BOOT_DIRECTORY="mnt/boot"
UTILITIES_DIRECTORY="../Utilities"

ENABLE_CONFIG_DEBUG_INFO=0 #1=Enables Debug in .config file, can be used with debugger such as kgdb
ENABLE_CONFIG_DEBUG_CONFIG=0 #1=Enables Config debug support

#function delete file
delete_file(){
  if [ -f $1 ]; then
    echo "Delete $1"
    sudo rm $1
  else
    echo "File $1 did not exist."
  fi
}

#function to change linux kernel .config variables after .config has been built
set_kernel_config_variables() {
  if grep -q $1 .config ; then
    LINE=$(grep $1 .config)
    if [[ $LINE == *"#"* || $LINE == *"=n"* ]]; then    
        sed -i 's/.*'$1'.*/'$1'='$2'/' .config
        echo "I've replaced  $1 to $2"
    else
        echo "$1 is already set to $2"
    fi
else
    echo "$1=$2" >> .config
    echo "$1 not present in file, I've added $1 to $2"
fi
}

#Get user input as to what kernel version is preferred
while getopts v: flag
do
    case "${flag}" in
        v) USER_SELECTED_LINUX_KERNEL_VERSION=${OPTARG};;
    esac
done

if [[ -z "$USER_SELECTED_LINUX_KERNEL_VERSION" ]] ; then 
  echo "Execute this shell script by optionally providing linux kernel v5.x long term release version, default is $DEFAULT_LINUX_KERNEL_VERSION.";
  echo " "; echo  "Example: Use ./$THIS_SCRIPT_NAME -v $DEFAULT_LINUX_KERNEL_VERSION"
  echo " "; read -p "Exit script and re-execute with your preferred version? (y/n)?" choice
  case "$choice" in 
    y|Y ) echo "yes. Exiting."; exit 1;;
    n|N ) echo "no, continue with $DEFAULT_LINUX_KERNEL_VERSION."; 
          USER_SELECTED_LINUX_KERNEL_VERSION=$DEFAULT_LINUX_KERNEL_VERSION;;
    * ) echo "invalid choice, exiting."; exit 1;;
  esac
fi

LINUX_KERNEL_GIT_REPO=$LINUX_KERNEL_GIT_REPO$USER_SELECTED_LINUX_KERNEL_VERSION.tar.xz

#Disclaimer
echo " "; echo "This script will cross-compile linux kernel using compiler/toolset crosstoolNG."; echo " "; echo "The script is work in progress tested for rpi4 on Ubuntu 22.04"
echo "crosstoolNG triplet: $X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED at $X_TOOLCHAIN_DIRECTORY"
echo "Kernel Arch: $KERNEL_ARCH"
echo "Kernel config file used for $RASPBERRYPI_PROCESSOR-based models (ARM64) will be linux source"

#Create directory for resulting files from build
echo " "
if [ ! -d "$THIS_SCRIPT_DIR"/$RESULT_FILES_DIRECTORY ]; then
  sudo mkdir $RESULT_FILES_DIRECTORY
  echo "I've created directory to store resulting files from the build: $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY"
else
  echo "$THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY exists."
fi

#Delete System.map and vmlinux from linux kernel source folder and stored results folders
#Deleting files from linux kernel will force a new kernel build
delete_file $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY/$COMPRESSED_KERNEL_IMAGE
delete_file $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY/System.map
delete_file $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY/$UIMAGE_FILENAME
delete_file $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/System.map
delete_file $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/$KERNEL_GENERATED_ELF_FILE

#Download kernel
echo " "
if [[ ! -d "$THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY" ]] ; then 
  echo "Download Linux Kernel $LINUX_KERNEL_GIT_REPO and decompress."
  git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git --depth=1
  git branch
  echo "Rename linux clone to $KERNEL_SOURCE_DIRECTORY"
  sudo mv linux-stable $KERNEL_SOURCE_DIRECTORY
else
  echo "Skip download Linux kernel, already present."
fi

#Download kernel and decompress
#echo " "
#if [[ ! -d "$THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY" ]] ; then 
#  echo "Download Linux Kernel $LINUX_KERNEL_GIT_REPO and decompress."
#  wget -q $LINUX_KERNEL_GIT_REPO
#  tar xf linux-$USER_SELECTED_LINUX_KERNEL_VERSION.tar.xz
#  echo "Rename linux clone to $KERNEL_SOURCE_DIRECTORY"
#  sudo mv linux-$USER_SELECTED_LINUX_KERNEL_VERSION $KERNEL_SOURCE_DIRECTORY
#  echo "Delete linux kernel tar file"
#  sudo rm linux-$USER_SELECTED_LINUX_KERNEL_VERSION.tar.xz
#else
#  echo "Skip download Linux kernel, already present."
#fi

#install menuconfig required libraries
echo " "; echo "Install menuconfig required libraries"
sudo apt -y update
#sudo apt install libncurses5-dev flex bison libgmp3-dev libgmp-dev libmpc-dev
sudo apt install libncurses5-dev flex bison libgmp3-dev libmpc-dev subversion libssl-dev
#sudo apt-get install libgmp3-dev

#Add Env variables
echo " "; echo "Add Environment variables:"
PATH=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/bin/:$PATH
echo " "; echo "Added $PATH/bin/ to PATH env var"
export ARCH=$KERNEL_ARCH
echo " "; echo "Added $ARCH to ARCH env var"
export CROSS_COMPILE="$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED"-
echo " "; echo "Added $KERNEL_USED to PATH env var"
export KERNEL=$KERNEL_USED
echo " "; echo "Added $CROSS_COMPILE to CROSS_COMPILE env var"

cd $KERNEL_SOURCE_DIRECTORY

#if [ ! -f $KERNEL_GENERATED_ELF_FILE ]; then
if [ ! -f $COMPRESSED_KERNEL_IMAGE ]; then
  #echo "vmlinux not present. Build kernel."
  echo "zImage not present. Build kernel."
  #clean files
  echo " "; echo "Clean files with make mrproper"
  make mrproper

  echo " "; echo "Configure Kernel config file $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/configs/$KERNEL_DEFAULT_CONFIG_FILE"
  #make -j8 ARCH=arm CROSS_COMPILE=/home/sergio/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu- multi_v7_defconfig
  make ARCH=$KERNEL_ARCH CROSS_COMPILE==$CROSS_COMPILE $KERNEL_DEFAULT_CONFIG_FILE

  echo " "; echo "Set specific debug variables in .config file"
  #set_kernel_config_variables CONFIG_DEBUG_INFO y
  #set_kernel_config_variables CONFIG_DEBUG_CONFIG y
  #set_kernel_config_variables CONFIG_DEBUG_INFO_REDUCED n
  #set_kernel_config_variables CONFIG_DEBUG_INFO_COMPRESSED n
  #set_kernel_config_variables CONFIG_DEBUG_INFO_SPLIT n
  #set_kernel_config_variables CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT y
  #set_kernel_config_variables CONFIG_DEBUG_INFO_DWARF4 n
  #set_kernel_config_variables CONFIG_DEBUG_INFO_DWARF5 n
  #set_kernel_config_variables CONFIG_DEBUG_INFO_BTF n
  #set_kernel_config_variables CONFIG_GDB_SCRIPTS n
  #set_kernel_config_variables CONFIG_DEBUG_EFI n

  #echo "confirm variables changed: "
  #cat .config | grep CONFIG_DEBUG_INFO
  #cat .config | grep CONFIG_DEBUG_CONFIG

  #not using menuconfig
  #make menuconfig ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE nconfig

  #Build linux kernel
  echo " "; echo "Build compressed kernel Image: zImage"
  #make -j8 ARCH=arm CROSS_COMPILE=/home/sergio/x-tools/aarch64-rpi4-linux-gnu/bin/aarch64-rpi4-linux-gnu- zImage
  make -j8 ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE CXXFLAGS="-march=armv8-a+crc -mtune=cortex-a72" CFLAGS="-march=armv8-a+crc -mtune=cortex-a72" $COMPRESSED_KERNEL_IMAGE
  sudo cp $COMPRESSED_KERNEL_IMAGE $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY

  #Move System.map to Results folder
  #echo " "; echo "Move System.map to $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY"
  #sudo mv "System.map" $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY  
fi

if [ 0 == 1 ]; then
#convert vmlinux to uImage for u-boot
cd $ROOT_UBOOT_DIR/$UBOOT_DIR
echo " ";echo "Convert $KERNEL_GENERATED_ELF_FILE to uImage for u-boot using u-boot's mkimage:"
#echo "Kernel generated ELF file: $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/$KERNEL_GENERATED_ELF_FILE - Image Name: $UIMAGE_NAME - Image filename $UIMAGE_FILENAME - Image Stored Address:$UIMAGE_LOAD_ADDRESS - located at $PWD"
#mkimage -A arm -O linux -T kernel -C none -a $UIMAGE_LOAD_ADDRESS -e $UIMAGE_LOAD_ADDRESS -n $UIMAGE_NAME -d "$THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/$KERNEL_GENERATED_ELF_FILE" $UIMAGE_FILENAME
mkimage -A arm -O linux -T kernel -C none -n $UIMAGE_NAME -d "$THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/$KERNEL_GENERATED_ELF_FILE" $UIMAGE_FILENAME
echo "Move $UIMAGE_FILENAME to $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY"
sudo mv $UIMAGE_FILENAME $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY
fi

echo " "; echo "Compile device trees"
cd $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY
make -j8 dtbs

#Build modules
echo " "; echo "Build modules"
sudo make -j8 ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE modules

echo "Copy compiled dtb file from $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/boot/dts/$PROCESSOR_SOC/$RPI4_DTB to $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY"
sudo cp $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/boot/dts/$PROCESSOR_SOC/$RPI4_DTB $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY

#copy overlays TODO
#echo " "; echo "Copy dtbo Files to SD card"
#  echo "Copy overlays dtbo from $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/dts/overlays/*.dtbo to $MOUNT_BOOT_DIRECTORY/overlays"
#  if [ ! -d $MOUNT_BOOT_DIRECTORY/overlays ]; then
#    sudo mkdir $MOUNT_BOOT_DIRECTORY/overlays
#  fi
  sudo cp -v $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/boot/dts/overlays/*.dtbo $MOUNT_BOOT_DIRECTORY/overlays
#mount usb device
echo " "; echo "Copy all resulting files to SD Card"
sudo cp -v $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY/* $THIS_SCRIPT_DIR/../$MOUNT_BOOT_DIRECTORY
echo " "; echo $(ls $THIS_SCRIPT_DIR/../$MOUNT_BOOT_DIRECTORY -la)