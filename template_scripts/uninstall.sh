#!/bin/bash

RELEASE_NAME={{enter release name(space) here}}
echo "Warning, this script does *not* only call helm uninstall but also remove persistent volumes and such from the extra_apply folder."

read -p "Are you sure you wish to continue? [y/n] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

    echo "Password file found"
    if [ -d extra_apply ]
    then
        echo "Extra files exist"
        cd extra_apply
        for f in *.yaml
        do
            echo "Deleting from $f."
            # take action on each file. $f store current file name
            kubectl delete -f $f --wait=false --namespace=$RELEASE_NAME
        done
        cd -
    else
        echo "No extra files directory found."
    fi
    helm delete --purge $RELEASE_NAME
    echo "Deletion started. This process may take some extra time after the script finished working."
fi
