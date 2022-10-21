#!/bin/bash

# script to fill out password value files

# SYNOPSIS
#quoteSubst <text>
quoteSubst() {
	IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"$1")
	printf %s "${REPLY%$'\n'}"
}


read -r -p "Show passwords in clear text? *Warning: this may be unsecure* [y/N]: " clearText
if [ $clearText == "y" ]; then
	showClearText=true
else
	showClearText=false
fi

# search for password_values.yaml.example files
for f in $(find . -name 'password_values.yaml.example');
do
	# for each check if corresponding password_values file exists
	DIR=$(dirname "${f}")
	echo "==== Found password example file in path ${DIR} ===="
	cd $DIR > /dev/null
	if [ -f "password_values.yaml" ]; then
		# if exists: exit because we can't update/edit currently
		echo "Password file already created."
		echo "Edit anyway? [y/N] - currently not supported. skipping"
		cd - > /dev/null
		continue
	fi
	# else, password_values file not existing yet: create it as a copy
	cp password_values.yaml.example password_values.yaml

	# repeate until no string equal to "{{password}}" exists, these need to be replaced.
	# currently no way of helpful user informations exists, we need something like a comment field there
	while grep "{{password}}" password_values.yaml > /dev/null;
	do
		#print lines and get user input. this prints the first line in the current file containing {{password}}.
		# depending on user choice input is in cleartext or not (-s)
		if [ "$showClearText" = false ]; then
			read -s -r -p "$(grep -m 1 "{{password}}" password_values.yaml | awk '{print $1'}) " password
		else
			read -r -p "$(grep -m 1 "{{password}}" password_values.yaml | awk '{print $1'}) " password
		fi
		# if no password was entered: autogenerate one
		if [ -z "$password" ]; then
			password=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 13)
		fi
		# escape some characters, this must be valid yaml
		passwordEscaped=$(sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\'$'\n''\\n' <<<"$password" | tr -d '\n')
		echo ""
		# replace first occurence of the {{password}} string.
		sed -i "0,/{{password}}/{s/{{password}}/$(quoteSubst "$password")/}" password_values.yaml
	done
	cd - > /dev/null
done
