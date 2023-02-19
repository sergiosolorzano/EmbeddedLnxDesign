#!/bin/bash

X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED="aarch64-rpi4-linux-gnu"
X_TOOLCHAIN_DIRECTORY="$HOME/x-tools"
X_TOOLCHAIN_ARCH="aarch64"

#Add Env variables
echo " "; echo "Add Environment variables:"
export PATH=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/:$PATH
echo " "; echo "Added $PATH/ to PATH env var"
export ARCH=$X_TOOLCHAIN_ARCH
echo " "; echo "Added $ARCH to ARCH env var"
