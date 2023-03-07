#!/bin/bash -a

#derived from to https://www.ucsc-extension.edu/courses/embedded-linux-design-and-programming/

source "paths.sh" || (echo "Failed to load environment variables, exiting." && exit 1)

set -e

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`
source "$THIS_SCRIPT_DIR/paths.sh" || (echo "Unable to load paths, exiting" && exit 1)

EMBEDDED_LINUX_PATH="$HOME/el"

BUILDROOT_VERSION_QUERY="https://buildroot.org/download.html"
BUILDROOT_GIT="git://git.buildroot.org/buildroot"
BUILDROOT_DIR_PATH="$EMBEDDED_LINUX_PATH/buildroot"

LOG_FILE_PATH="$THIS_SCRIPT_DIR/log-broot"

#Add Env variables
#echo " "; echo "Add Environment variables:"
#export PATH=$X_TOOLCHAIN_DIRECTORY/$X_TOOLCHAIN_ARCH_TRIPLET_INSTALLED/:$PATH
#echo " "; echo "Added $PATH/bin/ to PATH env var"
#export ARCH=$X_TOOLCHAIN_ARCH
#echo " "; echo "Added $ARCH to ARCH env var"

#Create log directory
if [ ! -d $LOG_FILE_PATH ]; then
	echo " "; echo "Create log directory"
	mkdir -v -p $LOG_FILE_PATH
fi

echo " "; echo "Delete download.html files in log dir"
find $LOG_FILE_PATH -name "*download.html*" -type f -delete

## Step 1: figure out which version is latest stable release.
echo " "; echo "Determine latest stable release for buildroot"
cd $LOG_FILE_PATH
wget -q $BUILDROOT_VERSION_QUERY
LatestRelease="`egrep -i \"Latest stable release\" download.html | grep -v rc | head -1 | sed -e 's/\/a//g' -e 's/[<>]/ /g' -e 's/ed/e/g' | sed 's/\/..//g' | awk '{print $NF}'`"
echo "using buildroot : $LatestRelease as latest stable release"
echo $EMBEDDED_LINUX_PATH

## Step 2: Install Buildroot by cloning the repository.
#echo "Delete $BUILDROOT_DIR_PATH*"
#rm -fr $BUILDROOT_DIR_PATH*
echo " "; echo "Download Buildroot"
if [ ! -d "$BUILDROOT_DIR_PATH" ]; then
	cd $EMBEDDED_LINUX_PATH
	echo " "; echo "Clone buildroot in path $EMBEDDED_LINUX_PATH"
	git clone $BUILDROOT_GIT -b "$LatestRelease"
	cd $BUILDROOT_DIR_PATH
	git branch
else
	echo "Buildroot already cloned at directory $BUILDROOT_DIR_PATH, skip cloning."
fi

## Step 3:
echo " "; echo "Install packages:"
if egrep -i -q "ubuntu|debian" /proc/version
then
cat <<EOF
For Ubuntu
background to the ltmain.sh issue: 
  https://www.gnu.org/software/automake/manual/1.9/html_node/Libtool-Issues.html
  https://stackoverflow.com/questions/8142685/buildroot-applying-a-patch-failed
  libtoolize --automake --copy --debug --force
thus install packages:
and use bash shell for below
  bash libtoolize --automake --copy --debug --force
EOF

echo " "
sudo apt -y install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath at cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping libsdl1.2-dev xterm chrpath diffstat perl python3-passlib libsqlite3-dev sqlite3 zstd liblz4-tool autoconf libtool
#package "python" doesn't exist for Jammy
sudo pip install wheel pysqlite3

echo " "; echo "Libtoolize buildroot:"
set -x #Enable trace of each command
cd $BUILDROOT_DIR_PATH
bash libtoolize --automake --copy --debug --force > $LOG_FILE_PATH/libtoolize.out 2>&1

else
echo " "
cat <<EOF
For RHEL/Centos/Fedora
install packages as below.
  sudo dnf -y install gawk wget git-core diffstat \
        unzip texinfo glibc-devel libstdc++-devel make \
        automake gcc gcc-c++ kernel-devel chrpath at \
        cpio python python3 python3-pip python3-pexpect \
        xterm chrpath diffstat rpcgen perl-open \
        python3-passlib python3-devel sqlite-devel \
        libsqlite3x libsqlite3x-devel
  sudo pip install wheel pysqlite3
EOF

sudo dnf -y install gawk wget git-core diffstat \
        unzip texinfo glibc-devel libstdc++-devel make \
        automake gcc gcc-c++ kernel-devel chrpath at \
        cpio python python3 python3-pip python3-pexpect \
        xterm chrpath diffstat rpcgen perl-open \
        python3-passlib python3-devel sqlite-devel \
        libsqlite3x libsqlite3x-devel
sudo pip install wheel pysqlite3

fi

