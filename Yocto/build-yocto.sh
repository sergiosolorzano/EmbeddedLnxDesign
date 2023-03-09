#!/bin/bash -a

#derived from to https://www.ucsc-extension.edu/courses/embedded-linux-design-and-programming/

source "paths.sh" || (echo "Failed to load environment variables, exiting." && exit 1)

set -e

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`
source "$THIS_SCRIPT_DIR/paths.sh" || (echo "Unable to load paths, exiting" && exit 1)

rpi=${1:-"raspberrypi4-64"}

BITBAKE_WORKING_DIR="build-rpi"
TARGET_BUILD_IMAGE="rpi-test-image"

LOG_FILE_PATH="$THIS_SCRIPT_DIR/log-yocto"

#Create log directory
if [ ! -d $LOG_FILE_PATH ]; then
	echo " "; echo "Create log directory"
	mkdir -v -p $LOG_FILE_PATH
fi

# build & bitbake
echo "this part takes ~6hours."
time bitbake $TARGET_BUILD_IMAGE 2>&1 

#10. image file location
echo "Flash image with balena at $BITBAKE_WORKING_DIR/tmp/deploy/images/${rpi}/rpi-test*wic.bz2"
cd $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR
ls -l tmp/deploy/images/${rpi}/rpi-test*wic.bz2


