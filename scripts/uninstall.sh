#!/bin/bash

#Echo to std error instead of std out
echoerr () {
	echo "$@" 1>&2; 
}

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

#set default values
RELEASE_NAME="UNNAMED"
TARGET_DIR="not set"

ASK_USER=true

#handle parameters of type: --key=value and -k=value
for i in "$@";
do
	case $i in
		-d=*|--target-dir=*)
			TARGET_DIR="${i#*=}"
			shift
			;;
		-r=*|--release-name=*)
			RELEASE_NAME="${i#*=}"
			shift
			;;
		-y|--yes|--assume-yes)
			echo "Script mode. Scipping user Questions."
			ASK_USER=false
			shift
			;;
		*)
			echoerr -e "$ERROR_STRING Couldn't recognize option $i."
			exit 1
	esac
done

if [ "$TARGET_DIR" == "not set" ] | [ ! -e "$TARGET_DIR" ];
then
	echoerr -e "$ERROR_STRING Target dir not set or not found. Exiting."
	exit 1
fi

TARGET_DIR=$(abspath $TARGET_DIR)

echo -e "Deleting release ${WARNING}$RELEASE_NAME${NC}."


echo "Warning, this script does *not* only call helm uninstall but also remove persistent volumes and such from the extra_apply folder."
if $ASK_USER;
then
	read -p "Are you sure you wish to continue? [y/n] " -n 1 -r
	echo    # (optional) move to a new line
else
	REPLY="y"
fi

ERRORS_OCCURED=false

if [[ $REPLY =~ ^[Yy]$ ]]
then

    echo "Password file found"
    if [ -d extra_apply ]
    then
        echo "Extra files exist"
        cd extra_apply
        for f in *.yaml
        do
            echo "Deleting $f."
            # take action on each file. $f store current file name
            kubectl delete -f $f --wait=false --namespace=$RELEASE_NAME
	    if [ $? != 0 ];
	    then
		    echo -e "$WARNING_STRING Couldn't delete ressource $f."
		    ERRORS_OCCURED=true
	    fi
        done
        cd - > /dev/null
    else
        echo "No extra files directory found."
    fi
    helm del --purge $RELEASE_NAME
    if [ $? != 0 ];
    then
	    echo -e "$WARNING_STRING Couldn't delete release name $RELEASE_NAME from helm."
	    ERRORS_OCCURED=true
    fi
    kubectl delete namespace $RELEASE_NAME
    if [ $? != 0 ];
    then
	    echo -e "$WARNING_STRING Couldn't delete namespace $RELEASE_NAME."
	    ERRORS_OCCURED=true
    fi
    if $ERRORS_OCCURED;
    then
	    echo -e "$WARNING_STRING Couldn't delete all ressources."
    fi
    echoerr -e "${SUCCESS}Deletion started. This process may take some extra time after the script returned.${NC}"
fi
