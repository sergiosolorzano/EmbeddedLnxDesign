#!/bin/bash -a

#derived from to https://www.ucsc-extension.edu/courses/embedded-linux-design-and-programming/

source "paths.sh" || (echo "Failed to load environment variables, exiting." && exit 1)

EMBEDDED_LINUX_PATH="$HOME/el"

BUILDROOT_DIR_PATH="$EMBEDDED_LINUX_PATH/buildroot.rpi4"

#Add Env variables
#echo " "; echo "Add Environment variables:"
#export PATH=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/:$PATH #using this one to x-compile with x-tool-ng
#echo " "; echo "Added $PATH/bin/ to PATH env var"
#export ARCH=$X_TOOLCHAIN_ARCH
#echo " "; echo "Added $ARCH to ARCH env var"

cat <<EOF


# perl needs perl-ExtUtils-MakeMaker
yum -y install perl-ExtUtils-MakeMaker perl
# or
apt-get -y install perl-ExtUtils-MakeMaker perl
# kill script now and install as above, if needed.

# It will take about 1 hr, for this step to complete. 

#
# configuration written to ~/el/buildroot.rpi4/.config
#

sleep 12
EOF

echo "Add ExtUtils::MakeMaker packages"
sudo apt -y update
#sudo apt -y install perl-ExtUtils-MakeMaker perl
sudo apt-get -y install perl
sudo cpan ExtUtils::MakeMaker

sleep 12
# ubuntu idiosyncracy.
# { egrep -i -q ubuntu /proc/version; } && \
# 	{ filewatchCP $HOME/el/buildroot.rpi4/ltmain.sh ${HOME}/el/buildroot.rpi4/output/build/host-fakeroot-1.25.3/ltmain.sh 0.5; }
sleep .5

cd $BUILDROOT_DIR_PATH
echo " "; echo "Build buildroot with the selected configuration."

echo "Make buildroot"
time make
 