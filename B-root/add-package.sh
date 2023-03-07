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

# now make
cd $BUILDROOT_DIR_PATH
echo " "; echo "Add package in menuconfig, e.g openssl->Target Packages->Networking applications->openssh."
echo "N.B. if openssh may need to set root password for openssh to work: at el/buildroot.rpi4/.config set BR2_TARGET_GENERIC_ROOT_PASSWD="setrootpwdhere""
echo " "; read -p "Press a key to launch menuconfig:" go
make menuconfig

echo " "; read -p "Enter name of package (as expected by buildroot, e.g. openssh):" packg

make $packg-rebuild