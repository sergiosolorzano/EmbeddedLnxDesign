#!/bin/bash
#Script to install linux kernel
#unmount sd card boot partition e.g. dev/sdb1
TARGET_DEVICE="sdb1"
echo " "; echo "Unmount $TARGET_DEVICE"
if findmnt /dev/"$TARGET_DEVICE"; then
  echo "SD found. Unmount $THIS_SCRIPT_DIR/../$MOUNT_BOOT_DIRECTORY"
  sudo umount /dev/"$TARGET_DEVICE"
fi
