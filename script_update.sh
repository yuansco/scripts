#!/bin/bash
# Download, Update and Backup scripts
# https://github.com/yuansco/scripts
# Vertion: 1.0
#
# How to use:
#
#   (1) install scripts:
#
#      git clone https://github.com/yuansco/scripts.git && cd scripts
#      ./setup_key.sh $KEY
#      ./script_update.sh -r
#      source ~/.bashrc
#
#   (2) download and update scripts:
#
#      ./script_update.sh -d -r
#


# get zip key from $ZIPKEY or ~/.key.txt
if [[ "$ZIPKEY" == "" ]]
then

    if [ ! -f ~/.key.txt ]
    then
        echo "private tool key not found!"
        exit 0
    else
        ZIPKEY=$(cat ~/.key.txt)
    fi
fi

ZIPKEY=$(cat ~/.key.txt)
#echo "zip key: $ZIPKEY"

for i in "$@"
do

    # pack
    if [[ "$i" == "-p" ]]
    then

        mkdir -p ~/backup/

        mv ./console_tool.zip ~/backup/console_tool.zip
        mv ./extract.zip ~/backup/extract.zip
        mv ./flashdisk.zip ~/backup/flashdisk.zip

        cp ~/workspace/console_tool.sh ./console_tool.sh
        cp ~/workspace/cpfe/extract.sh ./extract.sh
        cp ~/workspace/cpfe/flashdisk.sh ./flashdisk.sh

        zip -rP $ZIPKEY ./console_tool.zip ./console_tool.sh
        zip -rP $ZIPKEY ./extract.zip ./extract.sh
        zip -rP $ZIPKEY ./flashdisk.zip ./flashdisk.sh

        rm -rf ./console_tool.sh
        rm -rf ./extract.sh
        rm -rf ./flashdisk.sh

        echo "script pack finish!"

    # release
    elif [[ "$i" == "-r" ]]
    then

        mkdir -p ~/workspace/cpfe/

        unzip -P $ZIPKEY console_tool.zip
        unzip -P $ZIPKEY extract.zip
        unzip -P $ZIPKEY flashdisk.zip

        mv ./console_tool.sh ~/workspace/console_tool.sh
        mv ./extract.sh ~/workspace/cpfe/extract.sh
        mv ./flashdisk.sh ~/workspace/cpfe/flashdisk.sh

        chmod a+x ~/workspace/console_tool.sh
        chmod a+x ~/workspace/cpfe/extract.sh
        chmod a+x ~/workspace/cpfe/flashdisk.sh

        tool_alias=$(cat ~/.bashrc |grep console_tool.sh)

        if [[ "$tool_alias" == "" ]]
        then
            echo "alias console='~/workspace/console_tool.sh'" >> ~/.bashrc
            source ~/.bashrc
        fi

        echo "script release finish!"

    # download
    elif [[ "$i" == "-d" ]]
    then

        rm -rf ./console_tool.zip
        rm -rf ./extract.zip
        rm -rf ./flashdisk.zip

        wget https://github.com/yuansco/scripts/raw/main/console_tool.zip
        wget https://github.com/yuansco/scripts/raw/main/extract.zip
        wget https://github.com/yuansco/scripts/raw/main/flashdisk.zip

        echo "script download finish!"

    # clean up
    elif [[ "$i" == "-c" ]]
    then

        rm -rf ./console_tool.zip
        rm -rf ./extract.zip
        rm -rf ./flashdisk.zip

    else
        echo "Invalid option: $1"
    fi


done
