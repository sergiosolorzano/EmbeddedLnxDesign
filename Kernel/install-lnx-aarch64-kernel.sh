#!/bin/bash
#Script to install linux kernel

set -e

X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED="aarch64-rpi4-linux-gnu"
X_TOOLCHAIN_DIRECTORY="$HOME/x-tools"
X_TOOLCHAIN_ARCH="arm64"

KERNEL_ARCH="arm64"
KERNEL_SOURCE_DIRECTORY="linux-ltr"
#KERNEL_DEFAULT_CONFIG_FILE="defconfig" #this is linux kernel config file not used here

KERNEL_DEFAULT_CONFIG_FILE="bcm2711_defconfig" #this is raspberry pi config file used
KERNEL_DTB_FILE="bcm2711-rpi-4-b.dtb" #this is raspberry pi config file used

KERNEL_MAKE_REQUEST_IMAGE="Image.gz"
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

DEFAULT_LINUX_KERNEL_VERSION="5.14.9" #5.16 #6.2.2
DEFAULT_LINUX_KERNEL_MAJOR_VERSION="5" #5 #6
USER_SELECTED_LINUX_KERNEL_VERSION=""

LINUX_KERNEL_GIT_REPO="https://cdn.kernel.org/pub/linux/kernel/v$DEFAULT_LINUX_KERNEL_MAJOR_VERSION.x/linux-"

RASPBERRYPI_LINUXOS_GIT_REPO="https://github.com/raspberrypi/linux.git"
RASPBERRYPI_LINUXOS_DIRECTORY_NAME="raspberrypi_linuxos"
RASPBERRYPI_FIRMWARE_ROOT_DIRECTORY="firmware"
RASPBERRYPI_PROCESSOR="BCM2711"
PROCESSOR_SOC="broadcom"

MOUNT_BOOT_DIRECTORY="/media/sergio/boot"

UTILITIES_DIRECTORY="../Utilities"
KERNEL_LOG_FILENAME="log_kernel.txt"

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
  echo "Execute this shell script by optionally providing linux kernel v6.x long term release version, default is $DEFAULT_LINUX_KERNEL_VERSION.";
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
echo "Toolchain Arch: $X_TOOLCHAIN_ARCH"
echo "Kernel Arch: $KERNEL_ARCH"
echo "crosstoolNG triplet: $X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED at $X_TOOLCHAIN_DIRECTORY"
echo "Kernel config file used for $RASPBERRYPI_PROCESSOR-based models (ARM64) will be copied from the raspberrypiOS"

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
delete_file $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY/System.map
delete_file $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY/$UIMAGE_FILENAME
delete_file $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/System.map
delete_file $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/$KERNEL_GENERATED_ELF_FILE

#Download kernel and decompress
echo " "
if [[ ! -d "$THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY" ]] ; then 
  echo "Download Linux Kernel $LINUX_KERNEL_GIT_REPO and decompress."
  wget -q $LINUX_KERNEL_GIT_REPO
  tar xf linux-$USER_SELECTED_LINUX_KERNEL_VERSION.tar.xz
  echo "Rename linux clone to $KERNEL_SOURCE_DIRECTORY"
  sudo mv linux-$USER_SELECTED_LINUX_KERNEL_VERSION $KERNEL_SOURCE_DIRECTORY
  echo "Delete linux kernel tar file"
  sudo rm linux-$USER_SELECTED_LINUX_KERNEL_VERSION.tar.xz
else
  echo "Skip download Linux kernel, already present."
fi

##get stable
#echo "Now get stable"
#git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git --depth=1
#  git branch

echo " "
#Clone RaspberryPi linux OS
if [ ! -d "$THIS_SCRIPT_DIR"/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME ]; then
  echo "Clone Raspberry Pi OS to get system files."
  echo "Cloning $RASPBERRYPI_LINUXOS_GIT_REPO into directory $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME"
  sudo git clone $RASPBERRYPI_LINUXOS_GIT_REPO
  sudo mv $THIS_SCRIPT_DIR/linux $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME
  echo "I've cloned Raspberry Pi Linux OS, current branch is:"
  git branch
else
  echo "Skip Raspberry Pi Linux OS clone: clone directory already present at branch"
fi

#install menuconfig required libraries
echo " "; echo "Install menuconfig required libraries"
sudo apt -y update
sudo apt install libncurses5-dev flex bison libgmp3-dev libmpc-dev
#sudo apt-get install libgmp3-dev

#Add Env variables
echo " "; echo "Add Environment variables:"
PATH=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/bin/:$PATH
echo " "; echo "Added $PATH/bin/ to PATH env var"
export ARCH=$KERNEL_ARCH
echo " "; echo "Added $ARCH to ARCH env var"
export CROSS_COMPILE=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/bin/"$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED"-
echo " "; echo "Added $CROSS_COMPILE to CROSS_COMPILE env var"

cd $KERNEL_SOURCE_DIRECTORY

if [ ! -f $KERNEL_GENERATED_ELF_FILE ]; then
  echo "vmlinux not present. Build kernel."
  #clean files
  echo " "; echo "Clean files with make mrproper"
  make mrproper 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"

  #Show default config file to use to build Kernel
  echo " "; echo "We use raspberry pi default config file." 
  echo "Kernel build config file used for $KERNEL_ARCH located at $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/configs/$KERNEL_DEFAULT_CONFIG_FILE"
  if [ ! -f $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/configs/$KERNEL_DEFAULT_CONFIG_FILE ]; then
    echo "Copy $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/configs/$KERNEL_DEFAULT_CONFIG_FILE to $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/configs/" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
    sudo cp -v $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/configs/$KERNEL_DEFAULT_CONFIG_FILE $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/configs/ 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
  else
    echo "A copy of the kernel config file $KERNEL_DEFAULT_CONFIG_FILE already exists at $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/configs/" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
  fi

  echo " "; echo "Configure Linux with config file $THIS_SCRIPT_DIR/$RASPBERRYPI_LINUXOS_DIRECTORY_NAME/arch/$KERNEL_ARCH/configs/$KERNEL_DEFAULT_CONFIG_FILE"
  make $KERNEL_DEFAULT_CONFIG_FILE 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"

  echo " "; echo "Set specific debug variables in .config file"
  set_kernel_config_variables CONFIG_DEBUG_INFO y
  set_kernel_config_variables CONFIG_DEBUG_CONFIG y
  set_kernel_config_variables CONFIG_DEBUG_INFO_REDUCED n
  set_kernel_config_variables CONFIG_DEBUG_INFO_COMPRESSED n
  set_kernel_config_variables CONFIG_DEBUG_INFO_SPLIT n
  set_kernel_config_variables CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT y
  set_kernel_config_variables CONFIG_DEBUG_INFO_DWARF4 n
  set_kernel_config_variables CONFIG_DEBUG_INFO_DWARF5 n
  set_kernel_config_variables CONFIG_DEBUG_INFO_BTF n
  set_kernel_config_variables CONFIG_GDB_SCRIPTS n
  set_kernel_config_variables CONFIG_DEBUG_EFI n

  #echo "confirm variables changed: "
  #cat .config | grep CONFIG_DEBUG_INFO
  #cat .config | grep CONFIG_DEBUG_CONFIG

  #not using menuconfig
  #make menuconfig

  #Build linux kernel
  echo " "; echo "Build compressed kernel Image: $KERNEL_MAKE_REQUEST_IMAGE" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
  make -j8 $KERNEL_MAKE_REQUEST_IMAGE 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"

  #Move System.map to Results folder
  echo " "; echo "Move System.map to $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
  sudo mv -v "System.map" $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
fi

#if [ 0 == 1 ]; then
#convert vmlinux to uImage for u-boot
cd $ROOT_UBOOT_DIR/$UBOOT_DIR
echo " ";echo "Convert $KERNEL_GENERATED_ELF_FILE to uImage for u-boot using u-boot's mkimage:" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
#echo "Kernel generated ELF file: $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/$KERNEL_GENERATED_ELF_FILE - Image Name: $UIMAGE_NAME - Image filename $UIMAGE_FILENAME - Image Stored Address:$UIMAGE_LOAD_ADDRESS - located at $PWD"
#mkimage -A arm -O linux -T kernel -C none -a $UIMAGE_LOAD_ADDRESS -e $UIMAGE_LOAD_ADDRESS -n $UIMAGE_NAME -d "$THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/$KERNEL_GENERATED_ELF_FILE" $UIMAGE_FILENAME
mkimage -A arm -O linux -T kernel -C none -n $UIMAGE_NAME -d "$THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/$KERNEL_GENERATED_ELF_FILE" $UIMAGE_FILENAME 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
echo "Move $UIMAGE_FILENAME to $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
sudo mv -v $UIMAGE_FILENAME $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
#fi

echo " "; echo "Compile device trees" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
cd $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY
#Build dtbs
sudo make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
echo "Copy compiled dtb files from $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/boot/dts/$PROCESSOR_SOC/*.dtb to $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
sudo cp -v $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/boot/dts/$PROCESSOR_SOC/$KERNEL_DTB_FILE $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"

echo " "; echo "Copy dtbo Files to SD card" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
echo "Copy overlays dtbo from $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/boot/dts/overlays/*.dtbo to $MOUNT_BOOT_DIRECTORY/overlays" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
if [ ! -d $MOUNT_BOOT_DIRECTORY/overlays ]; then
  sudo mkdir -v $MOUNT_BOOT_DIRECTORY/overlays 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
fi
  sudo cp -v $THIS_SCRIPT_DIR/$KERNEL_SOURCE_DIRECTORY/arch/$KERNEL_ARCH/boot/dts/overlays/*.dtbo $MOUNT_BOOT_DIRECTORY/overlays 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"

#Build modules
  echo " "; echo "Build modules" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
  sudo make -j$MAKE_CORES ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE modules 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"


#mount usb device
echo " "; echo "Let's load files to SD card" 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"
sudo cp -v $THIS_SCRIPT_DIR/$RESULT_FILES_DIRECTORY/* $MOUNT_BOOT_DIRECTORY 2>&1 | tee -a "$THIS_SCRIPT_DIR/$KERNEL_LOG_FILENAME"