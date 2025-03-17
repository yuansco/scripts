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
        echo "zip key not found!"
        exit 0
    else
        ZIPKEY=$(cat ~/.key.txt)
    fi
fi

#echo "zip key: $ZIPKEY"

# clean up
function clean_up(){

    rm -rf ./tools/console_tool.zip
    rm -rf ./tools/extract.zip
    rm -rf ./tools/flashdisk.zip
}

# download
function download(){

    clean_up

    wget https://github.com/yuansco/scripts/raw/main/tools/console_tool.zip
    wget https://github.com/yuansco/scripts/raw/main/tools/extract.zip
    wget https://github.com/yuansco/scripts/raw/main/tools/flashdisk.zip

    mkdir -p tools

    mv ./console_tool.zip  ./tools/console_tool.zip
    mv ./extract.zip  ./tools/extract.zip
    mv ./flashdisk.zip  ./tools/flashdisk.zip

    echo "script download finish!"
}

# pack
function pack(){

    mkdir -p tools

    cp ~/workspace/console_tool.sh ./tools/console_tool.sh
    cp ~/workspace/cpfe/extract.sh ./tools/extract.sh
    cp ~/workspace/cpfe/flashdisk.sh ./tools/flashdisk.sh

    zip -rP $ZIPKEY ./tools/console_tool.zip ./tools/console_tool.sh
    zip -rP $ZIPKEY ./tools/extract.zip ./tools/extract.sh
    zip -rP $ZIPKEY ./tools/flashdisk.zip ./tools/flashdisk.sh

    rm -rf ./tools/console_tool.sh
    rm -rf ./tools/extract.sh
    rm -rf ./tools/flashdisk.sh

    echo "script pack finish!"
}

# release
function release(){

    mkdir -p ~/workspace/cpfe/

    unzip -P $ZIPKEY tools/console_tool.zip
    unzip -P $ZIPKEY tools/extract.zip
    unzip -P $ZIPKEY tools/flashdisk.zip

    mv ./tools/console_tool.sh ~/workspace/console_tool.sh
    mv ./tools/extract.sh ~/workspace/cpfe/extract.sh
    mv ./tools/flashdisk.sh ~/workspace/cpfe/flashdisk.sh

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
}


for i in "$@"
do

    # loop all argument
    case $i in
    # clean up
    -c|--clean_up)
        clean_up
    ;;
    # download
    -d|--download)
        download
    ;;
    # pack
    -p|--pack)
        pack
    ;;
    # release
    -r|--release)
        release
    ;;
    *)
        # Invalid argument
        echo "Invalid argument: $i"
    ;;
    esac

done

