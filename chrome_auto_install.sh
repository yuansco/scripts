#!/bin/bash
# chrome auto install script
# https://github.com/yuansco/scripts
# Created by Yu-An Chen on 2024/08/23
# Last modified on 2024/08/29
# Vertion: 1.0
#
# How to use:
#    (1) Run this script in Ubuntu 22.04:
#
#        chmod a+x ./chrome_auto_install.sh
#        ./chrome_auto_install.sh
#
#    (2) The script will download defconfig.sh, please edit and save it.
#        You can also use the default without editing it.
#
#    (3) The script will download and execute install_chrome_dev_environment.sh
#

# ping github.com
internet_ok=$(ping github.com -c 1 |grep "0% packet loss")

if [[ "$internet_ok" == "" ]]
then
    echo "internet check fail!"
    read -p "press any key to continue..." re
fi

# download defconfig.sh
FILE=./defconfig.sh
if [ ! -f "$FILE" ]; then
    wget https://raw.githubusercontent.com/yuansco/scripts/main/defconfig.sh
fi

# allow user to modify defconfig
echo "please update defconfig.sh if needed..."

if command -v gedit &> /dev/null
then
    gedit ./defconfig.sh
fi
read -p "press any key to continue..." re

# download install_chrome_dev_environment.sh
FILE=./install_chrome_dev_environment.sh
if [ ! -f "$FILE" ]; then
    wget https://raw.githubusercontent.com/yuansco/scripts/main/install_chrome_dev_environment.sh
fi

# run install_chrome_dev_environment.sh
chmod a+x ./install_chrome_dev_environment.sh
./install_chrome_dev_environment.sh

