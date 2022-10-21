#!/bin/bash

RELEASE_NAME="elastic"

if [ ! -z "$1" ];
then
	RELEASE_NAME=$1
	echo "Release name set to $1"
fi

### DO NOT TOUCH ###
abspath(){
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

SCRIPT_PATH=$(dirname "$SCRIPT")
ABS_SCRIPT_PATH=$(abspath $SCRIPT_PATH)
./global_install.sh --release-name=$RELEASE_NAME --auto-revert=true --target-dir=$ABS_SCRIPT_PATH

