all: clean install configure build-buildroot save #clean, install, configure, build, save2SDcard

config-stop: clean install configure #clean, install, configure

config-end: configure build-buildroot save #configure build, save

addpack-and-build: add-package build-buildroot save #user add package in menuconfig

install: #Download and Install buildroot
	# perl needs perl-ExtUtils-MakeMaker
	if [ -f /etc/lsb-release ] && grep -qi "ubuntu" /etc/lsb-release; \
	then \
		echo "Ubuntu, install packages"; \
		sudo su -c "apt -y install libextutils-makemaker-cpanfile-perl perl"; \
	else \
		echo "Not Ubuntu, install packages"; \
		sudo su -c "yum -y install perl-ExtUtils-MakeMaker perl"; \
	fi

	# see "https://deardevices.com/2019/04/18/how-to-crosscompile-raspi/"
	@echo ">>>>>    This step takes about 1min."
	./install-broot.sh
	@echo ">>>>>    buildroot installed to ~/el/buildroot"

configure: #Continue editing broot config file instead of deleting all and creating a new one
	@echo ">>>>>>  Configure broot settings"
	./configure-broot.sh #2>&1 | tee log_rpi4_configure.log

add-package: #Add a package to buildroot and rebuild the package
	@echo ">>>>>>  Add a package to buildroot"
	./add-package.sh #2>&1 | tee log_rpi4_addpackage.log

build-buildroot: #Build Buildroot
	@echo ">>>>>>  This step takes about 1 hr."
	./build-broot.sh 2>&1 | tee log_rpi4_build.log

save: #Save images to SD card
	@echo ">>>>>>  Saving Images to SD card"
	./save_images_tosdcard.sh 2>&1 | tee log_rpi4_save.log

clean: #Clear buildroot files
	cd ~/el; time -p rm -fr buildroot*
	#cd ~/el/buildroot.rpi4; make distclean

