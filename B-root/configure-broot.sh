#!/bin/bash -a

#derived from to https://www.ucsc-extension.edu/courses/embedded-linux-design-and-programming/

set -e

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`
source "$THIS_SCRIPT_DIR/paths.sh" || (echo "Unable to load paths, exiting" && exit 1)

EMBEDDED_LINUX_PATH="$HOME/el"

ORIGINAL_BUILDROOT_DIR_NAME="buildroot"
BUILDROOT_DIR_PATH="$EMBEDDED_LINUX_PATH/$ORIGINAL_BUILDROOT_DIR_NAME"
RENAMED_BUILDROOT_DIR_NAME="buildroot.rpi4"

TARGET_DEVICE="raspberrypi4"

LOG_FILENAME="log_rpi4_configure.log"
LOG_FILE_PATH=$THIS_SCRIPT_DIR/$LOG_FILENAME


echo " "; echo "Clear log file"
> $LOG_FILE_PATH

# Step #1: see if build root is already installed and rename it to device target
echo " "; echo "Rename $BUILDROOT_DIR_PATH to device target if it exists"
cd $EMBEDDED_LINUX_PATH

if [ -d $BUILDROOT_DIR_PATH ]; then 
	mv $ORIGINAL_BUILDROOT_DIR_NAME $RENAMED_BUILDROOT_DIR_NAME
	BUILDROOT_DIR_PATH=$EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME
	echo "buildroot directory renamed to $BUILDROOT_DIR_PATH" 2>&1 | tee log_rpi4_configure.log
else if [ -d $EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME ]; then
	echo "$ORIGINAL_BUILDROOT_DIR_NAME already renamed to device target $BUILDROOT_DIR_PATH."
	BUILDROOT_DIR_PATH=$EMBEDDED_LINUX_PATH/$RENAMED_BUILDROOT_DIR_NAME
	else
		echo "Can't find path, please install"
		exit 1
	fi
fi
#[ -d $BUILDROOT_DIR_PATH ] || { echo "no $RENAMED_BUILDROOT_DIR_NAME installed. pls install from example 1 in ch3."; exit 1; }

# Step #2: ok. it is there; list configs and set the defconfig
echo " "; echo "List and set defconfig"
cd $BUILDROOT_DIR_PATH
# { egrep -i -q ubuntu /proc/version; } && { libtoolize; }
make list-defconfigs | grep $TARGET_DEVICE
make "$TARGET_DEVICE"_64_defconfig

# Step #3: now make
echo " "; echo "Install packages:"
cat <<EOF


# perl needs perl-ExtUtils-MakeMaker
yum -y install perl-ExtUtils-MakeMaker perl
# or
apt-get -y install perl-ExtUtils-MakeMaker perl
# kill script now and install as above, if needed.

# otherwise, take a break! get some rest!
# It will take about 1.5hrs (~3-4hrs Ubuntu VM), for this step to complete. 

#
# configuration written to ~/el/buildroot.rpi4/.config
#

sleep 12
EOF

sudo apt -y update
#sudo apt -y install perl-ExtUtils-MakeMaker perl
sudo apt-get -y install perl
sudo cpan ExtUtils::MakeMaker

sleep 12
# ubuntu idiosyncracy.
# { egrep -i -q ubuntu /proc/version; } && \
# 	{ filewatchCP $HOME/el/buildroot.rpi4/ltmain.sh ${HOME}/el/buildroot.rpi4/output/build/host-fakeroot-1.25.3/ltmain.sh 0.5; }
sleep .5

echo "Make buildroot"
time make
  
echo see "buildroot_instructions.txt" for next steps.
exit 1
cat >$THIS_SCRIPT_DIR/buildroot_instructions.txt<<EOF
Now that buildroot step is successfully complete in `pwd`

# Step #4:
# when the build finishes the image is written to a file named
# output/images/sdcard.img

# there are two other important files:
# post-image.sh, and
# genimage-raspberrypi4-64.cfg 
# it is a script and a config file - both used to write the image file
# and are located in the board/raspberrypi/ directory and board/

# e.g. to write the sdcard.img to an microSD card and boot it on 
# the raspberrypi follow these steps.
# 1. insert the microSD card into the host machine card reader
# 2. Launch Etcher 
# 3. Click on Flash from File on Etcher.
# 4. Locate and Select the sdcard.img file built for the RPi.
# 5. Click Select target on Etcher.
# 6. Select the microSD card inserted in Step #1.
# 7. Click Flash on Etcher to write the image.
# 8. Eject the microSD card once Etcher is done.
# 9. Insert the microSD card into the RPi4.
#10. Apply power and start the RPi4.
##
# Confirm that the Pi4 booted successfully. 
# Plug it into the network and the network activity lights should blink.
# You can add an ssh server such as dropbear or openssh 
# to the buildroot image configuration.
EOF