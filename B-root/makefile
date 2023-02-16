all: run

run:
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

build:
	@echo ">>>>>>  This step takes about 1.5hrs."
	./configure-broot.sh 2>&1 | tee log_rpi4_configure.log

clean:
	cd ~/el; time -p rm -fr buildroot*