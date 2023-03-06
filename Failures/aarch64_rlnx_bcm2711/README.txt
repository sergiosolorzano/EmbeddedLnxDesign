using install-rlnx-aarch64-bcm2711_kernel.sh and install_rfs_aarch_from_xtools.sh


I tried with raspberry pi version 5.15, 5.14 but don't work. Error FATAL kernel is too old when booting rpi4.
I tried with raspberry pi version 5.14.21
cat version.h | more
#define LINUX_VERSION_CODE 331285
#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + ((c) > 255 ? 255 : (c)))
#define LINUX_VERSION_MAJOR 5
#define LINUX_VERSION_PATCHLEVEL 14
#define LINUX_VERSION_SUBLEVEL 21

and my host linux 5.15:
sergio@sergio-VirtualBox:/media/sergio/boot$ dpkg --list | grep linux-headers
ii  linux-headers-5.15.0-60                    5.15.0-60.66                            all          Header files related to Linux kernel version 5.15.0
ii  linux-headers-5.15.0-60-generic            5.15.0-60.66                            amd64        Linux kernel headers for version 5.15.0 on 64 bit x86 SMP
ii  linux-headers-5.15.0-67                    5.15.0-67.74                            all          Header files related to Linux kernel version 5.15.0
ii  linux-headers-5.15.0-67-generic            5.15.0-67.74                            amd64        Linux kernel headers for version 5.15.0 on 64 bit x86 SMP
ii  linux-headers-5.19.0-32-generic            5.19.0-32.33~22.04.1                    amd64        Linux kernel headers for version 5.19.0 on 64 bit x86 SMP
ii  linux-headers-5.19.0-35-generic            5.19.0-35.36~22.04.1                    amd64        Linux kernel headers for version 5.19.0 on 64 bit x86 SMP
ii  linux-headers-generic                      5.15.0.67.65                            amd64        Generic Linux kernel headers
ii  linux-headers-generic-hwe-22.04            5.19.0.35.36~22.04.10                   amd64        Generic Linux kernel headers
