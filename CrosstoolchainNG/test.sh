#exit on error.
#set -e	  

#INSTALL TOOLCHAIN
#Variables
ROOT_X_TOOL_DIR="el2"
X_TOOL_NG_DIR="crosstool-ng" #install git repo here
ROOT_X_TOOL_LIBS_DIR="src2"
INSTALL_CT_LOG_DIR="log"

THIS_SCRIPT_DIR="`pwd`"

THIS_SCRIPT_NAME=`basename "$0"`

#BUILD CROSS TOOLCHAIN
X_TOOL_GENERAL_TARGET_ARCHICTURE="rpi"
X_TOOL_TARGET_ARCHITECTURE="aarch64-rpi4-linux-gnu"
X_TOOL_TARGET_CONFIG_FILENAME=""
X_TOOL_TARGET_CONFIG_FILENAME_PATH=""
X_TOOL_MODEL_TARGET_ARCHICTURE="rpi4"

#Test Compiles
C_SRC_FILENAME=""
C_SRC_FILENAME_PATH=""
C_COMPILED_FILENAME_PATH=""
CPP_SRC_FILENAME=""
CPP_SRC_FILENAME_PATH=""
CPP_COMPILED_FILENAME_PATH=""

##  Store directory where this script executes from
echo "Starting $THIS_SCRIPT_NAME script stored at at $THIS_SCRIPT_DIR"

#Get user input to continue because the $ROOT_X_TOOL_LIBS_DIR folder will be deleted with this script 
echo "WARNING: This script will delete $ROOT_X_TOOL_LIBS_DIR folder due to a bug with tarballs. Choose to continue or exit."
read -p "Continue (y/n)?" choice
case "$choice" in 
  y|Y ) echo "yes";;
  n|N ) echo "no. Exiting."; exit 1;;
  * ) echo "invalid choice, exiting."; exit 1;;
esac

echo " "; echo "This script is work in progress: Target architecture for this crosstool currently setup in script for:"
echo "$X_TOOL_TARGET_ARCHITECTURE"
echo " "

#Get target config filename from user
while getopts f:c:p: flag
do
    case "${flag}" in
        f) X_TOOL_TARGET_CONFIG_FILENAME=${OPTARG};;
				c) C_SRC_FILENAME=${OPTARG};;
				p) CPP_SRC_FILENAME=${OPTARG};;
    esac
done

if [ -z "$X_TOOL_TARGET_CONFIG_FILENAME" ] || [ $X_TOOL_TARGET_CONFIG_FILENAME == "/" ] ; then 
	echo "Execute shell script by providing target configuration filename stored in the $THIS_SCRIPT_DIR directory";
	echo "and optionally c and cpp scripts filenames stored in the $THIS_SCRIPT_DIR directory to test cross-compilation at the end of the crosstool build.";
	echo  "Use ./$THIS_SCRIPT_NAME -f config_filename -c c_script_filename.c -p cpp_filename_script.cpp"

	echo "bash source ${BASH_SOURCE[0]}";
echo "target file is $X_TOOL_TARGET_CONFIG_FILENAME_PATH"
echo "c file is $C_SRC_FILENAME_PATH"
echo "cpp file is $CPP_SRC_FILENAME_PATH"

	echo " " ; echo "Exiting."
	exit 1
fi

#Set filename paths
X_TOOL_TARGET_CONFIG_FILENAME_PATH=$(dirname "$(readlink -f $X_TOOL_TARGET_CONFIG_FILENAME)")/$X_TOOL_TARGET_CONFIG_FILENAME;

if [ -n "$C_SRC_FILENAME" ] ; then 
	C_SRC_FILENAME_PATH=$(dirname "$(readlink -f $C_SRC_FILENAME)")/$C_SRC_FILENAME;
fi

if [ -n "$CPP_SRC_FILENAME" ] ; then 
	CPP_SRC_FILENAME_PATH=$(dirname "$(readlink -f $CPP_SRC_FILENAME)")/$CPP_SRC_FILENAME;
fi

echo "bash source ${BASH_SOURCE[0]}";
echo "target file is $X_TOOL_TARGET_CONFIG_FILENAME_PATH"
echo "c file is $C_SRC_FILENAME_PATH"
echo "cpp file is $CPP_SRC_FILENAME_PATH"

echo "I will use target configuration $X_TOOL_TARGET_CONFIG_FILENAME_PATH to create toolchain cross-compile tool."

if [[ -n "$C_SRC_FILENAME" ]] ; then 
		echo "I will also run local and cross compile test $C_SRC_FILENAME_PATH"
fi
if [[ -n "$CPP_SRC_FILENAME" ]] ; then 
		echo "I will also run local and cross compile test $CPP_SRC_FILENAME_PATH"
fi




# -- test compiles
if [[ -n "$C_SRC_FILENAME" ||  -n "$CPP_SRC_FILENAME" ]]; then
	echo ""
	echo "Test Compiles:"

	export PATH=$PATH:~/x-tools/$X_TOOL_TARGET_ARCHITECTURE/bin

	# C & C++ cross compile for rpi4
	if [ -n "$C_SRC_FILENAME" ]; then
		echo " "
		case "$X_TOOL_TARGET_ARCHITECTURE" in 
		  aarch64-rpi4-linux-gnu ) echo "Testing c file $C_SRC_FILENAME_PATH cross compilation for $X_TOOL_TARGET_ARCHITECTURE-gcc";
			{
				C_COMPILED_FILENAME_PATH="$X_TOOL_MODEL_TARGET_ARCHICTURE-$C_SRC_FILENAME"_execute
				aarch64-rpi4-linux-gnu-gcc $C_SRC_FILENAME_PATH -o $C_COMPILED_FILENAME_PATH
				echo "cross-compiled filename $C_COMPILED_FILENAME_PATH , type of shell script:"
				file $C_COMPILED_FILENAME_PATH			
			};;
		esac
	fi

	if [ -n "$CPP_SRC_FILENAME" ]; then
		echo " "
		case "$X_TOOL_TARGET_ARCHITECTURE" in 
		  aarch64-rpi4-linux-gnu ) echo "Testing cpp file $CPP_SRC_FILENAME_PATH cross compilation for $X_TOOL_TARGET_ARCHITECTURE-g++";
			{
				CPP_COMPILED_FILENAME_PATH="$X_TOOL_MODEL_TARGET_ARCHICTURE-$CPP_SRC_FILENAME"_execute
				aarch64-rpi4-linux-gnu-g++ $CPP_SRC_FILENAME_PATH -o $CPP_COMPILED_FILENAME_PATH
				echo "cross-compiled filename $CPP_COMPILED_FILENAME_PATH , type of shell script:"
				file $CPP_COMPILED_FILENAME_PATH			
			};;
		esac
	fi

	else
		echo "No c or cpp filename provided"
fi


echo " "; echo "End of script"
ls



