#!/bin/bash

# get private tool key from ~/key.txt
if [ ! -f ~/key.txt ]; then
    LOG_W "private tool key not found!"
    exit 0
else
    echo "private tool key exist!"
    key=$(cat ~/key.txt)
fi

# pack 
if [[ "$1" == "-p" ]]
then
    zip -rP $key console_tool.zip console_tool.sh
    zip -rP $key extract.zip extract.sh
    zip -rP $key flashdisk.zip flashdisk.sh

    echo "script pack finish!"

# release
elif [[ "$1" == "-r" ]]
then
    unzip -P $key console_tool.zip
    unzip -P $key extract.zip
    unzip -P $key flashdisk.zip

    echo "script release finish!"
fi


