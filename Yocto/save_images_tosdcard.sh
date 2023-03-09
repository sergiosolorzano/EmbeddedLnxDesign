#!/bin/bash -a

#derived from to https://www.ucsc-extension.edu/courses/embedded-linux-design-and-programming/

set -e

source "paths.sh" || (echo "Failed to load environment variables, exiting." && exit 1)

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`
source "$THIS_SCRIPT_DIR/paths.sh" || (echo "Unable to load paths, exiting" && exit 1)

UTILITIES_DIR="$THIS_SCRIPT_DIR/../Utilities"

rpi=${1:-"raspberrypi4-64"}

IMAGE_FILENAME="$YOCTO_DIR_PATH/tmp/deploy/images/${rpi}/rpi-test*wic.bz2"

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

echo " "
echo "Instructions to copy via Etcher to SD Card and kick off rpi4"
echo "Click on Flash from File on Etcher."
echo "Locate and Select the image file $IMAGE_FILENAME built for the RPi."
echo "Click Select target on Etcher."
echo "Select the microSD card inserted."
echo "Click Flash on Etcher to write the image."
echo "Eject the microSD card once Etcher is done."
echo "Insert the microSD card into the RPi4."
echo "Apply power and start the RPi4."
echo " "
echo "Confirm that the Pi4 booted successfully. "

echo " "; echo "Executing Etcher image"
$UTILITIES_DIR/balenaEtcher-1.7.9-x64.AppImage --no-sandbox --disable-gpu-sandbox --disable-seccomp-filter-sandbox