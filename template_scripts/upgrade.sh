#!/bin/bash

RELEASE_NAME={{enter release name(space) here}}

if [ -e password_values.yaml ]
then
    echo "Password file found"
    if [ -d extra_apply ]
    then
        echo "Extra files folder exist"
        cd extra_apply
        for f in *.yaml
        do
            echo "Applying $f file..."
            # take action on each file. $f store current file name
            kubectl apply -f $f --namespace=$RELEASE_NAME
        done
        cd -
    else
        echo "No extra files directory found."
    fi
    helm upgrade $RELEASE_NAME . --values password_values.yaml  --values values.yaml
else
    echo "No password file found. Exiting without actions. If no passwords are required please create an empty 'password_values.yaml' file."
fi
