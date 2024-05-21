#!/bin/bash

# sha1sum ~/workspace/console_tool.sh |cut -d ' ' -f 1
# sha1sum ~/workspace/cpfe/extract.sh |cut -d ' ' -f 1
# sha1sum ~/workspace/cpfe/flashdisk.sh |cut -d ' ' -f 1
sha_console_tool="d5075aaecd6fef1d32fe40caf800771f455e3008"
sha_extract_tool="c8e1a71ff97269fa2bc5f892c854bddf21bcc825"
sha_console_tool="f94db86665771abbe5f74a051e6d2d588ecd99c4"


# get private tool key from ~/.key.txt
if [ ! -f ~/.key.txt ]; then
    LOG_W "private tool key not found!"
    exit 0
else
    echo "private tool key exist!"
    key=$(cat ~/.key.txt)
fi

# pack
if [[ "$1" == "-p" ]]
then
    zip -rP $key ./console_tool.zip ./console_tool.sh
    zip -rP $key ./extract.zip ./extract.sh
    zip -rP $key ./flashdisk.zip ./flashdisk.sh

    echo "script pack finish!"

# release
elif [[ "$1" == "-r" ]]
then
    unzip -P $key console_tool.zip
    unzip -P $key extract.zip
    unzip -P $key flashdisk.zip

    #mv ./console_tool.sh ~/workspace/console_tool.sh
    #mv ./extract.sh ~/workspace/cpfe/extract.sh
    #mv ./flashdisk.sh ~/workspace/cpfe/flashdisk.sh

    echo "script release finish!"

# download
elif [[ "$1" == "-d" ]]
then
    wget https://github.com/yuansco/scripts/raw/main/console_tool.zip
    wget https://github.com/yuansco/scripts/raw/main/extract.zip
    wget https://github.com/yuansco/scripts/raw/main/flashdisk.zip
    echo "script download finish!"
else
    echo "Invalid option: $1"
fi
