#!/bin/bash

[ -n "$BASH_VERSION" ] || { echo "please run this script with bash"; exit 1; }

if [ $# != 2 ]; then
	echo "Usage: googledown.sh ID save_name"
	exit 0
fi
confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certi>
echo $confirm
wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$conf>


