#C_TEST_SCRIPT=hello.c CPP_TEST_SCRIPT=hello.cpp make xtools
#UBOOT_GIT_VERSION=v2023.01 CONFIG_FILENAME=bootloader_config_src.txt make uboot
#C_TEST_SCRIPT=hello.c CPP_TEST_SCRIPT=hello.cpp UBOOT_GIT_VERSION=v2023.01 CONFIG_FILENAME=bootloader_config_src.txt make all

#all_rlnx_kernel-> C_TEST_SCRIPT=hello.c CPP_TEST_SCRIPT=hello.cpp UBOOT_GIT_VERSION=v2023.01 CONFIG_FILENAME=bootloader_config_src.txt make all
#uboot_kernel_rfs -> make uboot_kernel_rfs

#VARIABLES
THIS_SCRIPT_DIR=$(CURDIR)

X_TOOLS_ROOT_DIR=$(THIS_SCRIPT_DIR)/CrosstoolchainNG
X_TOOLS_INSTALL_SCRIPT="install-ct-ng.sh"

UBOOT_ROOT_DIR="$(THIS_SCRIPT_DIR)/U-Boot"
UBOOT_INSTALL_SCRIPT="install_uboot.sh"

RLNX_KERNEL_ROOT_DIR="$(THIS_SCRIPT_DIR)/Kernel"
RLNX_KERNEL_INSTALL_SCRIPT="install-rlnx-kernel-sh"
RFS_ROOT_DIR="$(THIS_SCRIPT_DIR)/Rootfs"
RFS_INSTALL_SCRIPT="install_rfs.sh"

all_rlnx_kernel: ##Command and optional args: C_TEST_SCRIPT e.g. hello.c and CPP_TEST_SCRIPT e.g hello.cpp UBOOT_GIT_VERSION e.g. v2023.01 and CONFIG_FILENAME e.g bootloader_config_source_file.txt followed by make all
	cd $(X_TOOLS_ROOT_DIR);	./$(X_TOOLS_INSTALL_SCRIPT) -c $(C_TEST_SCRIPT) -p $(CPP_TEST_SCRIPT); cd $(UBOOT_ROOT_DIR); ./$(UBOOT_INSTALL_SCRIPT) -v $(UBOOT_GIT_VERSION) -f $(CONFIG_FILENAME); cd $(RLNX_KERNEL_ROOT_DIR); ./$(RLNX_KERNEL_INSTALL_SCRIPT); cd $(RFS_ROOT_DIR); ./$(RFS_INSTALL_SCRIPT)

xtools: ##Command and optional args: C_TEST_SCRIPT e.g. hello.c and CPP_TEST_SCRIPT e.g hello.cpp followed by make xtools
	cd $(X_TOOLS_ROOT_DIR);	./$(X_TOOLS_INSTALL_SCRIPT) -c $(C_TEST_SCRIPT) -p $(CPP_TEST_SCRIPT)

uboot: ##Requires x-tools built. Command and optional args: UBOOT_GIT_VERSION e.g. v2023.01 and CONFIG_FILENAME e.g bootloader_config_source_file.txt followed by make uboot
	cd $(UBOOT_ROOT_DIR); ./$(UBOOT_INSTALL_SCRIPT) -v $(UBOOT_GIT_VERSION) -f $(CONFIG_FILENAME)

rlnx_kernel: ##generate rpi kernel
	cd $(RLNX_KERNEL_ROOT_DIR); ./$(RLNX_KERNEL_INSTALL_SCRIPT)

root_fs: ##generate root file system with busybox
	cd $(RFS_ROOT_DIR); ./$(RFS_INSTALL_SCRIPT)

uboot_kernel_rfs: ##Run bootloader, kernel and root file system
	cd $(UBOOT_ROOT_DIR); ./$(UBOOT_INSTALL_SCRIPT) -v $(UBOOT_GIT_VERSION) -f $(CONFIG_FILENAME); cd $(RLNX_KERNEL_ROOT_DIR); ./$(RLNX_KERNEL_INSTALL_SCRIPT); cd $(RFS_ROOT_DIR); ./$(RFS_INSTALL_SCRIPT)

help: ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | sed -e 's/\(\:.*\#\#\)/\:\ /' | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'


