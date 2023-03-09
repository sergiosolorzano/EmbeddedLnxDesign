#!/bin/bash -a

#derived from to https://www.ucsc-extension.edu/courses/embedded-linux-design-and-programming/

#source "paths.sh" || (echo "Failed to load environment variables, exiting." && exit 1)

set -e

THIS_SCRIPT_DIR="`pwd`"
THIS_SCRIPT_NAME=`basename "$0"`
source "$THIS_SCRIPT_DIR/paths.sh" || (echo "Unable to load paths, exiting" && exit 1)

YOCTO_VERSION_QUERY="https://wiki.yoctoproject.org/wiki/Releases"
YOCTO_GIT="git://git.buildroot.org/buildroot"


LOG_FILE_PATH="$THIS_SCRIPT_DIR/log-yocto"

#Create log directory
if [ ! -d $LOG_FILE_PATH ]; then
	echo " "; echo "Create log directory"
	mkdir -v -p $LOG_FILE_PATH
fi

echo " "; echo "Delete download related log files in log dir"
find $LOG_FILE_PATH -name "*download.html*" -type f -delete
find $LOG_FILE_PATH -name "*Releases" -type f -delete
find $LOG_FILE_PATH -name "index.html*" -type f -delete

## Step 1: figure out which version is latest stable release.
echo " "; echo "Determine latest stable release for yocto"
cd $LOG_FILE_PATH
wget -q $YOCTO_VERSION_QUERY
LatestRelease="`egrep -A 12 \"Release notes\" Releases | sed 's/ *<.*> *//g' | egrep -v "^$" | sed -n '2p' | tr [A-Z] [a-z]`"
echo "using yocto : $LatestRelease as latest stable release"
echo $EMBEDDED_LINUX_PATH

## Step 2: Install Yocto by cloning the repository.
echo " "; echo "Download Yocto"
if [ ! -d "$YOCTO_DIR_PATH" ]; then
	echo " "; echo "Clone Yocto in path $EMBEDDED_LINUX_PATH"
  git clone -b $LatestRelease git://git.yoctoproject.org/poky.git
else
  echo "Yocto already cloned at directory $BUILDROOT_DIR_PATH, skip cloning."
fi
  
cd $YOCTO_DIR_PATH
if [ ! -d meta-openembedded ]; then
  echo "Clone meta-openembedded BSP layer"
  git clone -b $LatestRelease git://git.openembedded.org/meta-openembedded
else
  echo " ";echo "meta-openembedded directory exists, skip clone"
fi

if [ ! -d meta-raspberrypi ]; then
  echo "Clone meta-raspberrypi BSP layer"
  git clone -b $LatestRelease git://git.yoctoproject.org/meta-raspberrypi
else
  echo " "; echo "meta-raspberrypi directory exists, skip clone"
fi

cd $YOCTO_DIR_PATH
	
## Step 3:
echo " "; echo "Install packages:"
if egrep -i -q "ubuntu|debian" /proc/version
then
  echo " "; echo "Ubuntu packages installing:"
  sudo apt -y install \
      gawk wget git-core diffstat unzip \
      at build-essential chrpath cpio debianutils diffstat \
      gcc gcc-multilib git iputils-ping libegl1-mesa liblz4-tool \
      libsdl1.2-dev libsqlite3-dev mesa-common-dev perl \
      python3 python3-git python3-jinja2 python3-passlib \
      python3-pexpect python3-pip python3-subunit python-is-python3 \
      socat sqlite3 texinfo unzip xterm xz-utils zstd 

else
  echo " "
  cat <<EOF
  For RHEL/Centos/Fedora
  install packages these packages:
EOF

  sudo dnf -y install \
  gawk make wget tar bzip2 gzip \
  at automake ccache chrpath cpio cpp diffstat \
  diffutils file findutils gawk gcc gcc-c++ git \
  git-core glibc-devel kernel-devel libsqlite3x \
  libsqlite3x-devel libstdc++-devel lz4 make mesa-libGL-devel \
  patch perl perl-bignum perl-Data-Dumper perl-File-Compare \
  perl-File-Copy perl-FindBin perl-locale perl-open \
  perl-Text-ParseWords perl-Thread-Queue python python3 \
  python3-devel python3-GitPython python3-jinja2 \
  python3-passlib python3-pexpect python3-pip \
  rpcgen SDL-devel socat sqlite-devel texinfo unzip \
  wget which xterm xz zstd 
  sudo dnf install -y make python3-pip which inkscape texlive-fncychap
  sudo pip3 install sphinx sphinx_rtd_theme pyyaml

fi

cat <<EOF
see - https://docs.yoctoproject.org/ref-manual/system-requirements.html 
and https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html

Then, running ..
EOF
  # /usr/local/lib/python3.10
  PYTHON3=$(which python3)
  echo $PYTHON3
  ${PYTHON3} -m pip install --upgrade pip
  pip install wheel pysqlite3

cat <<EOF
.. for more details
.. see https://docs.yoctoproject.org/ref-manual/system-requirements.html 

Done.
EOF

echo " "; echo "Add env var path /home/sergio/.local/bin where pip, pip3 and pip3.10 are installed"
export PATH=/home/sergio/.local/bin/:$PATH
echo $PATH

#install packages for Fedora
if egrep -i -q "ubuntu|debian" /proc/version
then
  :
else
  ##
  ##  - FEDORA 35/36 is unsupported. for honister.
  ##  - you will see
  ##  - WARNING: Host distribution "fedora-36" has not been validated with this version of the build system; you may possibly experience unexpected failures. It is recommended that you use a tested distribution.
  ##  so, 
  cat <<EOF
  ##  - FEDORA 35/36 is unsupported. for honister.
  ##  - so, using "FIXES"/commands as below, to ensure build.
EOF

  ## -- add prefix  "from pysqlite3._sqlite3" on line 27
  sudo su -c "sed 's/from *_sqlite3/from pysqlite3._sqlite3/' \
    /usr/local/lib/python3.10/sqlite3/dbapi2.py > \
    /usr/local/lib/python3.10/sqlite3/dbapi2.py.bak"
  sudo su -c "mv /usr/local/lib/python3.10/sqlite3/dbapi2.py.bak \
    /usr/local/lib/python3.10/sqlite3/dbapi2.py"

  ## -- comment WAL mode pragma on line 97 in ~/el/poky/bitbake/lib/bb/persist_data.py 
  sed '/cursor.execute.*WAL/s/^.*/# &/' $YOCTO_DIR_PATH/bitbake/lib/bb/persist_data.py > \
    ~/el/poky/bitbake/lib/bb/persist_data.py.bak 
  mv $YOCTO_DIR_PATH/bitbake/lib/bb/persist_data.py.bak \
    $YOCTO_DIR_PATH/bitbake/lib/bb/persist_data.py 

  ## -- comment WAL mode pragma on line 72 in ~/el/poky/bitbake/lib/hashserv/__init__.py
  sed '/cursor.execute.*WAL/s/^.*/# &/' $YOCTO_DIR_PATH/bitbake/lib/hashserv/__init__.py > \
    ~/el/poky/bitbake/lib/hashserv/__init__.py.bak
  mv $YOCTO_DIR_PATH/bitbake/lib/hashserv/__init__.py.bak \
    $YOCTO_DIR_PATH/bitbake/lib/hashserv/__init__.py
fi
