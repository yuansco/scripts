#!/bin/bash
# chrome auto install script
# https://github.com/yuansco/scripts
# Created by Yu-An Chen on 2024/08/23
# Last modified on 2024/08/27
# Vertion: 1.0

# How to use: Run this script in Ubuntu 22.04


# ping google dns server
internet_ok=$(ping 8.8.8.8 -c 1 |grep "0% packet loss")

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
gedit ./defconfig.sh
read -p "press any key to continue..." re

# download install_chrome_dev_environment.sh
FILE=./install_chrome_dev_environment.sh
if [ ! -f "$FILE" ]; then
    wget https://raw.githubusercontent.com/yuansco/scripts/main/install_chrome_dev_environment.sh
fi

# run install_chrome_dev_environment.sh
chmod a+x ./install_chrome_dev_environment.sh
./install_chrome_dev_environment.sh

