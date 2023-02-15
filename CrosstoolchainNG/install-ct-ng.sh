#!/bin/bash
set -e	  

#INSTALL TOOLCHAIN
#Variables
MAKE_CORES=16

ROOT_X_TOOL_DIR="el"
X_TOOL_NG_DIR="crosstool-ng" #install git repo here
ROOT_X_TOOL_LIBS_DIR="src"
INSTALL_CT_LOG_DIR="log"

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`

PKGLIST="" #lib package list for toolchain installation
X_TOOL_NG_GIT_REPO="https://github.com/crosstool-ng/crosstool-ng.git"
X_TOOL_NG_GIT_REPO_QUERY="https://crosstool-ng.github.io/"

#BUILD CROSS TOOLCHAIN
X_TOOL_GENERAL_TARGET_ARCHICTURE="rpi"
X_TOOL_MODEL_TARGET_ARCHICTURE="rpi4"
X_TOOL_TARGET_ARCHITECTURE="aarch64-rpi4-linux-gnu" #CPU-Vendor-Kernel-OS
#X_TOOL_TARGET_ARCHITECTURE="armv8-rpi4-linux-gnueabihf"
X_TOOL_TARGET_CONFIG_FILENAME=""
X_TOOL_TARGET_CONFIG_FILENAME_PATH=""

#Test Compiles
C_SRC_FILENAME=""
C_SRC_FILENAME_PATH=""
C_COMPILED_FILENAME_PATH=""
CPP_SRC_FILENAME=""
CPP_SRC_FILENAME_PATH=""
CPP_COMPILED_FILENAME_PATH=""
COMPILE_BOOL_C=0
COMPILE_BOOL_CPP=0

##  Store directory where this script executes from
echo "Starting $THIS_SCRIPT_NAME script stored at at $THIS_SCRIPT_DIR"

echo " "; echo "-----------------------------------------------------"
echo "CREATE AND BUILD CROSSTOOL-NG"
echo " "

sudo chmod a+rwx $THIS_SCRIPT_DIR

#Get user input to continue because the $ROOT_X_TOOL_LIBS_DIR folder will be deleted with this script 
echo " "; echo "WARNING: This script will delete $ROOT_X_TOOL_LIBS_DIR folder due to a bug with tarballs. Choose to continue or exit."
read -p "Continue (y/n)?" choice
case "$choice" in 
  y|Y ) echo "yes";;
  n|N ) echo "no. Exiting."; exit 1;;
  * ) echo "invalid choice, exiting."; exit 1;;
esac

echo " "; echo "This script will build x-tool and is work in progress"; echo " "; echo "Target architecture for this crosstool currently setup in script for:"
echo "$X_TOOL_TARGET_ARCHITECTURE"
echo " "

#Get target config filename from user
while getopts c:p: flag
do
    case "${flag}" in
				c) C_SRC_FILENAME=${OPTARG};;
				p) CPP_SRC_FILENAME=${OPTARG};;
    esac
done

#Get user input to continue because the $ROOT_X_TOOL_LIBS_DIR folder will be deleted with this script 
if [[ -z "$C_SRC_FILENAME" || -z "$CPP_SRC_FILENAME" ]] ; then 
echo "Execute shell script by providing optionally c and cpp scripts filenames stored in the $THIS_SCRIPT_DIR directory to test cross-compilation at the end of the crosstool build.";
echo  "Use ./$THIS_SCRIPT_NAME -c c_script_filename.c -p cpp_filename_script.cpp"
echo " "; read -p "Continue (y/n)?" choice
case "$choice" in 
  y|Y ) echo "yes";;
  n|N ) echo "no. Exiting."; exit 1;;
  * ) echo "invalid choice, exiting."; exit 1;;
esac
fi

#Set filename paths

if [ -n "$C_SRC_FILENAME" ] ; then 
	C_SRC_FILENAME_PATH=$(dirname "$(readlink -f $C_SRC_FILENAME)")/$C_SRC_FILENAME;
fi

if [ -n "$CPP_SRC_FILENAME" ] ; then 
	CPP_SRC_FILENAME_PATH=$(dirname "$(readlink -f $CPP_SRC_FILENAME)")/$CPP_SRC_FILENAME;
fi

#echo "bash source ${BASH_SOURCE[0]}";
#echo "c file is $C_SRC_FILENAME_PATH"
#echo "cpp file is $CPP_SRC_FILENAME_PATH"

if [[ -n "$C_SRC_FILENAME" && -f $C_SRC_FILENAME ]] ; then 
		COMPILE_BOOL_C=1
		echo "I will also run local and cross compile test $C_SRC_FILENAME_PATH"
	else
		echo "No c file found to compile $C_SRC_FILENAME"
fi
if [[ -n "$CPP_SRC_FILENAME" && -f $CPP_SRC_FILENAME ]] ; then 
		echo "I will also run local and cross compile test $CPP_SRC_FILENAME_PATH"
		COMPILE_BOOL_CPP=1
	else
		echo "No cpp file found to compile $CPP_SRC_FILENAME"
fi

##  create a directories  locally
echo " "
if [ ! -d ~/"$ROOT_X_TOOL_DIR" ]; then
	mkdir -p ~/$ROOT_X_TOOL_DIR 
	echo "Created Directory ~/$ROOT_X_TOOL_DIR"
else
	echo "Directory ~/$ROOT_X_TOOL_DIR exists. Deleting its contents."
	rm -rf ~/$ROOT_X_TOOL_DIR
fi

if [ ! -d ~/"$ROOT_X_TOOL_LIBS_DIR" ]; then
	mkdir -p ~/$ROOT_X_TOOL_LIBS_DIR 
	echo "Created Directory ~/$ROOT_X_TOOL_LIBS_DIR"
else
	echo "Directory ~/$ROOT_X_TOOL_LIBS_DIR exists. Deleting its contents."
	rm -rf ~/$ROOT_X_TOOL_LIBS_DIR
fi

if [ ! -d ~/"$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR" ]; then
	mkdir -p ~/"$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR"
	echo "Created Directory ~/$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR"
else
	echo "Directory ~/$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR exists. Deleting its contents."
	rm -rf ~/$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR
fi

## Grab my system name
DIST="`cat /proc/version | sed -e 's/.*Ubuntu.*/Ubuntu/g' -e 's/.*Red *Hat.*/RedHat/g'`"

## Determine and download relevant libraries required for the toolchain
echo " "
if echo $DIST | grep -i ubuntu >> /dev/null
then
	echo "I have determined this system is using ${DIST}. I'll target this version when downloading the toolchain and libs."
	echo "Downloading packages $PKGLIST"
	PKGLIST="automake bison chrpath flex gcc make perl g++ git gperf gawk help2man libexpat1-dev libncurses5-dev libsdl1.2-dev libtool libtool-bin libtool-doc python2.7-dev libglib2.0-dev python3-dev texinfo"
	sudo apt-get update && sudo apt-get upgrade
	sudo apt -y update
	sudo apt -y install $PKGLIST
else
  # for the following packages: AlmaLinux, ALT Linux, CentOS, Fedora, Mageia, OpenMandriva, openSUSE, PCLinuxOS, Rocky Linux, Solus
	echo "I have determined this system is using ${DIST}. I'll target this version when downloading the toolchain and libs."
	echo "Downloading packages $PKGLIST"
	PKGLIST="glib2-devel texinfo help2man python3-devel"
	sudo apt -y update
	sudo dnf -y install glib2-devel texinfo help2man python3-devel
fi

##  Determine LatestRelease & LatestRelease date for the Toolchain
echo " "
wget -q $X_TOOL_NG_GIT_REPO_QUERY
LatestRelease="`grep -i released index.html | grep -v rc | head -1 | sed -e 's/\/a//g' -e 's/[<>]/ /g' -e 's/ed/e/g' | awk '{print $NF}'`"
LatestRelDT="`grep -i released index.html | head -1 | sed -e 's/.*href=\"\///g' -e 's/\/release.*//g' -e 's/\//-/g'`"

if [[ -z "$LatestRelease" ]] ; then 
		echo "Could not get Toolchain LatestRelease" ;
		exit 1
fi
rm index.html
echo "I have determined the Toolchain version is ${bold}crosstool-ng${normal} $LatestRelease released $LatestRelDT"

#  Create Toolchain git download directory, clone and checkout
if [ ! -d ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/" ]; then
	mkdir -p ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR 
	echo "Created Directory to download toolchain from repo ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR"
else
	echo "Toolchain directory ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR exists. Deleting its contents."
	rm -rf ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR
fi

cd ~/$ROOT_X_TOOL_DIR
echo "git clone $X_TOOL_NG_GIT_REPO into directory $ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR"
git clone $X_TOOL_NG_GIT_REPO 2>&1 | tee log/git_clone.log >/dev/null
cd $X_TOOL_NG_DIR
echo "I've git checked out Toolchain branch crosstool-ng-${LatestRelease}"
git checkout crosstool-ng-${LatestRelease} 2>&1 | tee  ../log/git_checkout_crosstool-ng-${LatestRelease}.log >/dev/null

#  Configure Toolchain & install
echo " "
echo "Configure Toolchain and install to build cross toolchains."
echo "Execute ./bootstrap in toolchain $ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR. Adding output to ~/$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR/bootstrap.log file."
./bootstrap 2>&1 | tee ~/"$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR/bootstrap.log" >/dev/null
echo "Execute ./configure --prefix=${PWD}. Prefix to install the toolchain for independent architecture in $PWD to avoid root permissions which otherwise would be needed if installed in default location /usr/local/share.."
echo "Adding .configure output to ~/$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR/configure--prefix.log"
./configure --prefix=${PWD} | tee ~/"$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR/configure--prefix.log" >/dev/null

echo "Execute Makefile -- make -- in ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR. to ??TBC-configure the crosstool installation configuration file-TBC??"
echo "Adding Makefile log output to ~/$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR/make.log"
make 2>&1 | tee ../log/make.log >/dev/null
echo "Execute Makefile -- make install Makefile target-- in ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR."
echo "Adding Makefile log output to ~/$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR/make-install.log"
make -j$MAKE_CORES install 2>&1 | tee ~/$ROOT_X_TOOL_DIR/$INSTALL_CT_LOG_DIR/make-install.log >/dev/null

echo " "
echo "Export in sub-shell (for current shell man availability run this script with command source) crosstool cli manual pages. I execute MANPATH=\$MANPATH:~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/share/man"
echo "Access man pages with Show man 1 ct-ng"
#echo "pwd is:"`pwd`""
#export MANPATH="\$MANPATH:`pwd`/share/man"
#echo "manpath is ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/share/man"
#export MANPATH="\$MANPATH:~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/share/man"
cd ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR
export MANPATH="\$MANPATH:`pwd`/share/man"

echo "Show man 1 ct-ng"
man 1 ct-ng | head -60

# Now we install
echo " "
echo "-------------------------------"
echo " "
# initial steps to create X-Tool configuration
## if crosstool config file exists and no backup of this file exists, then create backup
if [[ -f ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/.config" && ! -f ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/.config.orig" ]]; then
	echo "Created backup for crosstool config file because it didn't exist"
	mv ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/.config" ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/.config.orig" 2>/dev/null
fi

echo "Delete existing config crosstool file $ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/.config"
rm -f ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/.config

# Create .config file with ct-ng for target architecture
echo "Creating X-Tool Config file for target architecture: Not using menuconfig but config file: ~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/.config"
~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/bin/ct-ng $X_TOOL_TARGET_ARCHITECTURE

echo "Copy newly generated .config to $THIS_SCRIPT_DIR as "$THIS_SCRIPT_DIR"/config-"$X_TOOL_MODEL_TARGET_ARCHICTURE".txt"
cp ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR"/.config "$THIS_SCRIPT_DIR"/config-"$X_TOOL_MODEL_TARGET_ARCHICTURE".txt
X_TOOL_TARGET_CONFIG_FILENAME=config-$X_TOOL_MODEL_TARGET_ARCHICTURE.txt
# echo "X_TOOL_TARGET_CONFIG_FILENAME is $X_TOOL_TARGET_CONFIG_FILENAME"
X_TOOL_TARGET_CONFIG_FILENAME_PATH=$(dirname "$(readlink -f $X_TOOL_TARGET_CONFIG_FILENAME)")/$X_TOOL_TARGET_CONFIG_FILENAME;
echo "I will use target configuration ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR"/.config to install and build toolchain cross-compile tool."

# check .config was correctly created
if [ -z ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR"/.config ] ; then 
	echo "crosstool .config file didn't create correctly at directory ~/"$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR", exiting.";
	echo " " ; echo "Exiting."
	exit 1
fi

echo " "
echo "List of available architecture targets of general target $X_TOOL_GENERAL_TARGET_ARCHICTURE and to build cross tool:"
~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/bin/ct-ng list-samples | grep -i $X_TOOL_GENERAL_TARGET_ARCHICTURE
echo "Show details for target architecture of this build: $X_TOOL_TARGET_ARCHITECTURE"
~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/bin/ct-ng show-$X_TOOL_TARGET_ARCHITECTURE

echo " "
echo "Hack because zlib package doesn't install correctly from crosstool into Ubuntu:"
#Get zlib name
ZLIB=$(~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/bin/ct-ng show-$X_TOOL_TARGET_ARCHITECTURE | egrep -i "Companion libs" | sed 's/.*zlib/zlib/')
#Get package
if [ ! -f ~/"$ROOT_X_TOOL_LIBS_DIR/${ZLIB}.tar.gz" ]; then
	echo "Hack zlib: Target zlib:$ZLIB. Download ${ZLIB} and copy it to $ROOT_X_TOOL_LIBS_DIR folder."
	mkdir -p ~/$ROOT_X_TOOL_LIBS_DIR
	echo "Downloading https://zlib.net/fossils/${ZLIB}.tar.gz"
	wget -O ~/$ROOT_X_TOOL_LIBS_DIR/${ZLIB}.tar.gz https://zlib.net/fossils/${ZLIB}.tar.gz
else
	echo "zlib version $ZLIB already present in $ROOT_X_TOOL_LIBS_DIR"
fi

# build crosstool with config for target
echo " "
echo "Building crosstool for $X_TOOL_GENERAL_TARGET_ARCHICTURE. Standby, process takes 30-60 minutes."
~/$ROOT_X_TOOL_DIR/$X_TOOL_NG_DIR/bin/ct-ng build
echo "---------Build Completed Successfully-------------"

# -- test compiles
if [[ -n "$C_SRC_FILENAME" ||  -n "$CPP_SRC_FILENAME" ]]; then
	echo ""
	echo "Test Compiles:"

	export PATH=$PATH:~/x-tools/$X_TOOL_TARGET_ARCHITECTURE/bin

	## C & C++ compile locally
	if [[ -n "$C_SRC_FILENAME" && COMPILE_BOOL_C==1 ]]; then
		echo " "
		echo "Testing local c gcc compile for $C_SRC_FILENAME_PATH"
		C_COMPILED_FILENAME_PATH="$C_SRC_FILENAME_PATH"_execute
		gcc -o $C_COMPILED_FILENAME_PATH /$C_SRC_FILENAME_PATH
		echo "Determine type of shell script for compiled file $C_COMPILED_FILENAME_PATH:"
		file $C_COMPILED_FILENAME_PATH
		echo "Execute gcc compiled shell script:"
		$C_COMPILED_FILENAME_PATH
	fi

	if [[ -n "$CPP_SRC_FILENAME" && COMPILE_BOOL_CPP==1 ]]; then
		echo " "
		echo "Testing local cpp g++ compile for $CPP_SRC_FILENAME_PATH."
		CPP_COMPILED_FILENAME_PATH="$CPP_SRC_FILENAME_PATH"_execute
		g++ -o $CPP_COMPILED_FILENAME_PATH $CPP_SRC_FILENAME_PATH
		echo "Determine type of shell script for compiled file $CPP_COMPILED_FILENAME_PATH:"
		file $CPP_COMPILED_FILENAME_PATH
		echo "Execute g++ compiled shell script:"
		$CPP_COMPILED_FILENAME_PATH
	fi

	# C & C++ cross compile for rpi4
	if [[ -n "$C_SRC_FILENAME" && COMPILE_BOOL_C==1 ]] ; then
		echo " "
		case "$X_TOOL_TARGET_ARCHITECTURE" in 
		  aarch64-rpi4-linux-gnu ) echo "Testing c file $C_SRC_FILENAME_PATH cross compilation for $X_TOOL_TARGET_ARCHITECTURE-gcc";
			{
				C_COMPILED_FILENAME_PATH="$C_SRC_FILENAME_PATH"_"$X_TOOL_MODEL_TARGET_ARCHICTURE"_execute
				aarch64-rpi4-linux-gnu-gcc $C_SRC_FILENAME_PATH -o $C_COMPILED_FILENAME_PATH
				echo "cross-compiled filename $C_COMPILED_FILENAME_PATH , type of shell script:"
				file $C_COMPILED_FILENAME_PATH			
			};;
		esac
	fi

	if [[ -n "$CPP_SRC_FILENAME" && COMPILE_BOOL_CPP==1 ]]; then
		echo " "
		case "$X_TOOL_TARGET_ARCHITECTURE" in 
		  aarch64-rpi4-linux-gnu ) echo "Testing cpp file $CPP_SRC_FILENAME_PATH cross compilation for $X_TOOL_TARGET_ARCHITECTURE-g++";
			{
				CPP_COMPILED_FILENAME_PATH="$CPP_SRC_FILENAME_PATH"_"$X_TOOL_MODEL_TARGET_ARCHICTURE"_execute
				aarch64-rpi4-linux-gnu-g++ $CPP_SRC_FILENAME_PATH -o $CPP_COMPILED_FILENAME_PATH
				echo "cross-compiled filename $CPP_COMPILED_FILENAME_PATH , type of shell script:"
				file $CPP_COMPILED_FILENAME_PATH			
			};;
		esac
	fi
fi

#updatedb
echo " "; echo "Update db of file names use by locate"
sudo updatedb

echo " "; echo "End of $THIS_SCRIPT_NAME Script"
