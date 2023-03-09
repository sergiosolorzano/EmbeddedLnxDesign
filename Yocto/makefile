all: clean install configure build save #clean, install, configure, build, save2SDcard

install: #Download and Install yocto
	./install-yocto.sh
	@echo ">>>>>    yocto installed to ~/el/poky"

configure: #Configures poky
	@echo ">>>>>>  Configure poky settings and install"
	./configure-yocto.sh #2>&1 | tee log_rpi4_configure.log

configure: #Builds linux distro
	@echo ">>>>>>  Builds linux distro"
	./configure-yocto.sh #2>&1 | tee log_rpi4_configure.log

save: #Save images to SD card
	@echo ">>>>>>  Saving Images to SD card"
	./save_images_tosdcard.sh #2>&1 | tee log_rpi4_save.log

clean: #Clear poky files
	cd ~/el; time rm -fr poky

