#!/bin/bash
# Download, Update and Backup scripts
# https://github.com/yuansco/scripts
# Version: 2.0
#
# How to use:
#
#   (1) install scripts:
#
#      git clone https://github.com/yuansco/scripts.git && cd scripts
#      ./script_update.sh -r
#      source ~/.bashrc
#
#   (2) download and update scripts:
#
#      ./script_update.sh -d -r
#

# clean up
function clean_up(){
    rm -f ./tools/*.zip
}

# download
function download(){
    clean_up

    mkdir -p tools
    wget https://raw.githubusercontent.com/yuansco/scripts/main/tools/console_tool_v2.sh -O ./tools/console_tool_v2.sh
    chmod a+x ./tools/console_tool_v2.sh

    echo "script download finish!"
}

# pack
function pack(){
    mkdir -p tools

    if [ -f ~/workspace/console_tool_v2.sh ]; then
        cp ~/workspace/console_tool_v2.sh ./tools/console_tool_v2.sh
        chmod a+x ./tools/console_tool_v2.sh
    elif [ -f ~/console_tool_v2.sh ]; then
        cp ~/console_tool_v2.sh ./tools/console_tool_v2.sh
        chmod a+x ./tools/console_tool_v2.sh
    fi

    echo "script pack finish!"
}

# release
function release(){
    mkdir -p ~/workspace

    if [ -f ./tools/console_tool_v2.sh ]; then
        cp ./tools/console_tool_v2.sh ~/workspace/console_tool_v2.sh
        chmod a+x ~/workspace/console_tool_v2.sh
    fi

    if grep -q "console_tool.sh" ~/.bashrc 2>/dev/null; then
        sed -i 's|~/workspace/console_tool.sh|~/workspace/console_tool_v2.sh|g' ~/.bashrc
    elif ! grep -q "console_tool_v2.sh" ~/.bashrc 2>/dev/null; then
        echo "alias console='~/workspace/console_tool_v2.sh'" >> ~/.bashrc
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

