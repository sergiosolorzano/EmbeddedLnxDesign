#!/bin/bash -a

#derived from to https://www.ucsc-extension.edu/courses/embedded-linux-design-and-programming/

set -e

source "paths.sh" || (echo "Failed to load environment variables, exiting." && exit 1)

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`
source "$THIS_SCRIPT_DIR/paths.sh" || (echo "Unable to load paths, exiting" && exit 1)

EMBEDDED_LINUX_PATH="$HOME/el"

STORED_IMAGES="$THIS_SCRIPT_DIR/Images"

ORIGINAL_BUILDROOT_DIR_NAME="buildroot"
BUILDROOT_DIR_PATH="$EMBEDDED_LINUX_PATH/$ORIGINAL_BUILDROOT_DIR_NAME"
RENAMED_BUILDROOT_DIR_NAME="buildroot.rpi4"

TARGET_DEVICE="raspberrypi4"

LOG_FILENAME="log_rpi4_configure.log"
LOG_FILE_PATH=$THIS_SCRIPT_DIR/$LOG_FILENAME

UTILITIES_DIR="$THIS_SCRIPT_DIR/../Utilities"

IMAGE_FILENAME="sdcard.img"
IMAGE_DIR="$EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME/output/images"
POST_IMAGE_FILENAME="post-image.sh"
POST_IMAGE_DIR="$EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME/board/raspberrypi"
GENIMAGE_FILENAME="genimage-raspberrypi4-64.cfg"
GENIMAGE_DIR="$EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME/board/raspberrypi"

echo see "buildroot_instructions.txt" for next steps.

#Get Etcher
echo " "; read -p "Install Etcher? (y/n)" choice
case "$choice" in 
    y|Y ) 	echo "yes"; 
			echo "Install packages:"
			sudo apt install zenity;
			sudo apt-get install fuse libfuse2;
			sudo apt-get install firefox;
			echo " "; 
			echo "Download Ubuntu 22.04 working version balena-etcher-electron-1.7.9-linux-x64.zip Close Firefox when done.";
			firefox https://github.com/balena-io/etcher/releases?page=10 ;
			#read -p "Press a key when done to continue" continue; 
			echo "Unzip balena-etcher-electron-1.7.9-linux-x64.zip to $UTILITIES_DIR";
			unzip $HOME/Downloads/balena-etcher-electron-1.7.9-linux-x64.zip -d $THIS_SCRIPT_DIR/../Utilities;
			echo "Set properties to allow Execute (https://phoenixnap.com/kb/etcher-ubuntu). Press when done to continue?";
			nautilus $UTILITIES_DIR;;
    n|N ) echo "no, execute Etcher";;
    * ) echo "invalid choice, exiting."; exit 1;;
esac

echo " "; echo "Copy image files to $STORED_IMAGES"
if [ ! -d $STORED_IMAGES ]; then 
	sudo mkdir -v -p $STORED_IMAGES
else
	if ls $STORED_IMAGES/* 1> /dev/null 2>&1; then
    	sudo rm -v $STORED_IMAGES/*
	else
    	echo "No image files to delete at $STORED_IMAGES"
	fi
fi

if [ -f "$IMAGE_DIR/$IMAGE_FILENAME" ]; then
    if [ ! -f "$STORED_IMAGES/$IMAGE_FILENAME" ]; then
        sudo cp -v "$IMAGE_DIR/$IMAGE_FILENAME" "$STORED_IMAGES"
        #sudo rm -v "$IMAGE_DIR/$IMAGE_FILENAME"
    fi
fi

if [ -f "$POST_IMAGE_DIR/$POST_IMAGE_FILENAME" ]; then 
	if [ ! -f "$STORED_IMAGES/$POST_IMAGE_FILENAME" ]; then
		sudo cp -v "$POST_IMAGE_DIR/$POST_IMAGE_FILENAME" "$STORED_IMAGES"
		#sudo rm -v $POST_IMAGE_DIR/$POST_IMAGE_FILENAME
	fi
fi

if [ -f "$GENIMAGE_DIR/$GENIMAGE_FILENAME" ]; then 
	if [ ! -f "$STORED_IMAGES/$GENIMAGE_FILENAME" ]; then
		sudo cp -v "$GENIMAGE_DIR/$GENIMAGE_FILENAME" "$STORED_IMAGES"
		#sudo rm -v $GENIMAGE_DIR/$GENIMAGE_FILENAME
	fi
fi

echo " "
echo "Instructions to copy via Etcher to SD Card and kick off rpi4"
echo "Click on Flash from File on Etcher."
echo "Locate and Select the sdcard.img file built for the RPi."
echo "Click Select target on Etcher."
echo "Select the microSD card inserted in Step #1."
echo "Click Flash on Etcher to write the image."
echo "Eject the microSD card once Etcher is done."
echo "Insert the microSD card into the RPi4."
echo "Apply power and start the RPi4."
echo " "
echo "Confirm that the Pi4 booted successfully. "
echo "Plug it into the network and the network activity lights should blink."
echo "You can add an ssh server such as dropbear or openssh "
echo "to the buildroot image configuration."

echo " "; echo "Executing Etcher image"
$UTILITIES_DIR/balenaEtcher-1.7.9-x64.AppImage --no-sandbox --disable-gpu-sandbox --disable-seccomp-filter-sandbox