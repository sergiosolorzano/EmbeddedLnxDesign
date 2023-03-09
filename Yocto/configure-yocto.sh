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

#echo " "; echo "Delete download related log files in log dir"
#find $LOG_FILE_PATH -name "*download.html*" -type f -delete
#find $LOG_FILE_PATH -name "*Releases" -type f -delete
#find $LOG_FILE_PATH -name "index.html*" -type f -delete

YoctoIssue1() {
if cat /proc/version | egrep -i -q "centos|fedora|redhat"
then 
   echo "for fixes, see FIXES/README.txt"
fi
}

# 0a. figure out which version is latest stable release.
cd $LOG_FILE_PATH
wget -q https://wiki.yoctoproject.org/wiki/Releases
LatestRelease="`egrep -A 12 \"Release notes\" Releases | sed 's/ *<.*> *//g' | egrep -v "^$" | sed -n '2p' | tr [A-Z] [a-z]`"
echo "using Yocto Project : $LatestRelease as latest stable release"

# 2. chdir to directory inside raspberrypi BSP layer
#    and, list the Raspberry Pi images
echo "Board Support Package (BSP) for raspberry pi: Images available"
cd $YOCTO_DIR_PATH/meta-raspberrypi/recipes-core/images
ls -l
sleep 6

# 3. setup BitBake work environmnet
cd $YOCTO_DIR_PATH
echo " "; echo "Change source of working environment to build-rpi working directory. "
echo "All configuration and intermediate/target image files will go to this dir."
source oe-init-build-env $BITBAKE_WORKING_DIR

# 4. add BitBake layers to the image.
echo "Add layers: meta-raspberrypi and /meta-openembedded/meta-oe, /meta-openembedded/meta-python, /meta-openembedded/meta-networking, /meta-openembedded/meta-multimedia"
cd $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-networking
bitbake-layers add-layer ../meta-openembedded/meta-multimedia
bitbake-layers add-layer ../meta-raspberrypi

# 5. show BitBake layers
echo "  "; echo "Show me the layers for $BITBAKE_WORKING_DIR"
bitbake-layers show-layers

# 6. verify assignment of BBLAYERS variable
cd $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR
echo "See layers have been added to BBLAYERS inconf/bbalyers.conf"
cat conf/bblayers.conf

# 7. List the machines supported by the meta-raspberrypi BSP layer
cd $YOCTO_DIR_PATH
echo "List machines supported by the meta-raspberrypi BSP layer"
ls meta-raspberrypi/conf/machine
echo " var is $rpi"
# 8. add rpi and ssh to local.conf
{ egrep -q "$rpi" $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf; } || \
	{ sed "s/#MACHINE ?= \"qemuarm\"/MACHINE = \"$rpi\"/" ~/el/poky/build-rpi/conf/local.conf >> ~/el/poky/build-rpi/conf/local.conf.new; \
	  mv $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf.old; \
    mv $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf.new $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf; }
{ egrep -q "ssh-server-openssh" ~/el/poky/build-rpi/conf/local.conf; } || \
	{ sed 's/debug-tweaks/& ssh-server-openssh/' ~/el/poky/build-rpi/conf/local.conf > ~/el/poky/build-rpi/conf/local.conf.new; \
	  mv $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf.old; \
    mv $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf.new $YOCTO_DIR_PATH/$BITBAKE_WORKING_DIR/conf/local.conf; }


