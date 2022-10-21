#!/bin/bash

#helper function to get path of a file
fp () {
	case "$1" in
		/*) printf '%s\n' "$1";;
		*) printf '%s\n' "$PWD/$1";;
	esac
}
#helper function to get absolute path of a file
abspath () {
	if [ -d "$1" ]; then
		(cd "$1"; pwd)
	elif [ -f "$1" ]; then
		if [[ $1 = /* ]]; then
			echo "$1"
		elif [[ $1 == */* ]]; then
			echo "$(cd "${1%/*}"; pwd)/${1##*/}"
		else
			echo "$(pwd)/$1"
		fi
	fi
}

#Color codes
WARNING='\033[1;33m' #yellow
ERROR='\033[0;31m' #red
SUCCESS='\033[0;32m' #green
NC='\033[0m' #no color
ERROR_STRING="${ERROR}ERROR:$NC"
WARNING_STRING="${WARNING}Warning:$NC"

#Set default values
RELEASE_NAME="UNNAMED"
ROOT_DIR="not set"
SCRIPT_PATH=$(dirname "$SCRIPT")
#if true: call uninstall if any of the apply or install commands fail
AUTO_REVERT=true
TARGET_DIR="not set"
#only handles parameters of: -k=value or --key=value type
for i in "$@" #go through all given parameters starting at the first (not 0 as 0 is the script called from apth)
do
	case $i in
		-r=*|--release-name=*) #if starts with -r= or --release-name= handle
			RELEASE_NAME="${i#*=}" #${string#substring} resolves to string without substring (substring removal)
			shift #remove handled argument
			;; #finish case
		-a=*|--auto-revert=*)
			AUTO_REVERT_TMP="${i#*=}"
			if [ "$AUTO_REVERT_TMP" == "true" ];
			then
				AUTO_REVERT=true
			elif [ "$AUTO_REVERT_TMP" == "false" ];
			then
				AUTO_REVERT=false
			else
				echo -e "$ERROR_STRING Autorevert expects value 'true' or 'false'. Unknown value $AUTO_REVERT_TMP."
				exit 1
			fi
			shift
			;;
		-d=*|--target-dir=*)
			TARGET_DIR="${i#*=}"
			shift
			;;
		-r=*|--root-dir=*)
			ROOT_DIR="${i#*=}"
			shift
			;;
		*)
			echo -e "$ERROR_STRING Couldn't recognize option $i." #Unkown option
			exit 1
	esac
done

#if target dir not set or not existing: exit
if [ "$TARGET_DIR" == "not set" ] | [ ! -e "$TARGET_DIR" ];
then
	echo -e "$ERROR_STRING Target dir not set or not existing. Exiting."
	exit 1
fi

if [ "$ROOT_DIR" == "not set" ] | [ ! -e "$ROOT_DIR" ];
then
	echo "Root dir not set or not existing. Trying to find root directory"
	TMP=$(pwd)
	cd $TARGET_DIR
	while [ ! $(pwd) -ef "/" ];
	do
		if [ -e .rootmarker ];
		then
			ROOT_DIR=$(pwd)
			cd $TMP
			echo -e "${SUCCESS}Root dir found. Set to $ROOT_DIR${NC}"
			break
		fi
		cd .. > /dev/null
		if [ $? != 0 ];
		then
			echo -e "$ERROR_STRING Errors occured during search for the root dir. Couldn't enter sup-dir. Exiting."
			exit 1
		fi
		echo $(pwd)
	done
	if [ ! $? -eq 0 ];
	then
		echo -e "$ERROR_STRING Errors occured during search of the root dir. Exiting"
		exit 1
	fi
	if [ "$ROOT_DIR" == "not set" ] | [ ! -e "$ROOT_DIR" ];
	then
		echo -e "$ERROR_STRING Root dir still not set or not existing. Exiting"
		exit 1
	fi
fi

#make pathes absolut
TARGET_DIR=$(abspath $TARGET_DIR)
ROOT_DIR=$(abspath $ROOT_DIR)

#Go through folders starting at caller dir and find password_values.yaml files.
HELM_ARGS=""
cd $TARGET_DIR > /dev/null
while [ ! $(pwd) -ef "/" ];
do
	if [ -e "password_values.yaml" ];
	then
		HELM_ARGS+="--values $(fp "password_values.yaml") "
	elif [ -e "password_values.yaml.example" ];
	then
		echo -e "$WARNING_STRING Password values example file exists but password values doesn't. Please check $(pwd)"
	fi
	if [ $(pwd) -ef $ROOT_DIR ];
	then
		break
	fi
	cd .. > /dev/null
	if [ ! $? -eq 0 ];
	then
		echo -e "$ERROR_STRING Couldn't go directory upwards. Current dir $(pwd). Exiting"
		exit 1
	fi
done
echo "Done scanning for password files. Found $HELM_ARGS"


#Extra apply folder
cd $TARGET_DIR
if [ -d extra_apply ];
then
	#if folder exists go into and go through yaml files
	echo "Extra filed folder exists"
	cd extra_apply
	for f in *.yaml
	do
		# apply file to namespace
		echo "Applying $f..."
		kubectl apply -f $f --namespace=$RELEASE_NAME
		if [ $? != 0 ];
		then
			#if applying didn't work check if we should revert
			echo -e "$ERROR_STRING Applying $f failed."
			if $AUTO_REVERT ;
			then
				#revert ...
				echo "Reverting enabled. Reverting."
				cd $TARGET_DIR
				if [ ! -e uninstall.sh ];
				then
					#if can't revert print error message
					echo -e "$ERROR_STRING Uninstall script missing. Can't revert..."
					exit 1
				fi
				./uninstall.sh $RELEASE_NAME
				if [ $? == 0 ];
				then
					#Reverting worked
					echo -e "$SUCCESS Uninstall script successful"
				else
					echo -e "$ERROR_STRING Uninstall script returned non 0 exit code."
				fi
				exit 1
			fi
			# No revert, just exit
			exit 1
		fi
	done
fi

cd $TARGET_DIR
helm install --name $RELEASE_NAME --namespace $RELEASE_NAME $HELM_ARGS .
if [ $? == 0 ];
then
	echo -e "$SUCCESS Helm install and applying successful."
	exit 0
else
	echo -e "$ERROR_STRING Helm install unsuccessful."
	if $AUTO_REVERT ;
	then
		#revert ...
		echo "Reverting enabled. Reverting."
		cd $TARGET_DIR
		if [ ! -e uninstall.sh ];
		then
			#if can't revert print error message
			echo -e "$ERROR_STRING Uninstall script missing. Can't revert..."
			exit 1
		fi
		./uninstall.sh $RELEASE_NAME
		if [ $? == 0 ];
		then
			#Reverting worked
			echo -e "$SUCCESS Uninstall script successful"
		else
			echo -e "$ERROR_STRING Uninstall script returned non 0 exit code."
		fi
		exit 1
	fi
fi
exit 0
