#!/bin/bash
# Install Chromebook develop environment script
# Created by Yu-An Chen on 2024/03/26
# Last modified on 2024/04/08
# Vertion: 1.0

# How to use: Run this script in Ubuntu 22.04

#############################################
# Config                                    #
#############################################

# User name and email address for setup git
USEREMAL="foo@quanta.corp-partner.google.com"
USERNAME="foo"


# run apt-get update and apt-get upgrade before install
UPDATE_UBUNTU="Y"

# Install useful tool config("Y" or other):
INSTALL_CHROME_BROWSER="Y"      # Google Chrome Browser
INSTALL_VSCODE="Y"              # Visual Studio Code
INSTALL_TABBY="Y"               # Tabby (terminal tool)
INSTALL_MINICOM="Y"             # Minicom (serial communication tool)
INSTALL_MELD="Y"                # Meld (text compare tool)
INSTALL_GPARTED="Y"             # Gparted (disk partition editor)
INSTALL_NETTOOL="Y"             # Net-tool (for ifconfig command)
INSTALL_GHEX="Y"                # Ghex (hex editor)
INSTALL_TREE="Y"                # Tree (for tree command)
INSTALL_SCREENSHOT="Y"          # Gnome-Screenshot (screenshot tool)
INSTALL_CHEWING="Y"             # Chewing (Chinese Input Method)
INSTALL_DEV_TOOL="Y"            # chromium releate tools

# sync tast-tests-private repo
# Note: config gerrit ssh key is necessary for sync private repo
SYNC_TAST_TESTS_PRIVATE="N"


# Chroot config:
CHROOT_REPO_INIT="Y"            # init repo folder
CHROOT_REPO_SYNC="Y"            # sync source code
CHROOT_SYNC_JOBS=8              # Allow N jobs at repo sync
CHROOT_CREATE="Y"               # create chroot after repo sync
CHROOT_SETUP_BOARD="Y"          # run setup board after create chroot
CHROOT_TATGET_BOARD="brya"      # Board for setup_board command

# Setup docker Servod
SETUP_DOCKER_SERVOD="Y"


#############################################
# Internal gerrit ssh key                   #
#############################################

# Internal gerrit ssh key
# for download private repo, e.g. tast-tests-private
#
# Chromium Gerrit key:
# https://chromium-review.googlesource.com/settings/#HTTPCredentials
# HTTP Credentials > Obtain password (opens in a new tab) > Configure Git
#
# Chromium Internal Gerrit key:
# https://chrome-internal-review.googlesource.com/settings/#HTTPCredentials
# HTTP Credentials > Obtain password (opens in a new tab) > Configure Git

ssh_key="N"

# Chromium Gerrit key:
function chromium_gerrit_key(){
    return
}

# Chromium Internal Gerrit key:
function chromium_internal_gerrit_key(){
    return
}

function setup_ssh_key(){
    chromium_gerrit_key
    chromium_internal_gerrit_key

    FILE=~/.gitcookies
    if [ -f "$FILE" ]; then
        LOG "Setup ssh key done"
    else
        LOG_W "Setup ssh key fail! Please check ssh_key"
    fi
}


#############################################
# Print function                            #
#############################################


# +----------------+----------------+
# | Log Type       | Tag Color      |
# +----------------+----------------+
# | Normal log     | Green          |
# | Warning log    | Yellow         |
# | Error log      | Red            |
# | Command log    | Cyan           |
# +----------------+----------------+

# print green color text
function green(){
    echo -e "\033[32m\033[01m$1\033[0m \c"
}

# print yellow color text
function yellow(){
    echo -e "\033[33m\033[01m$1\033[0m \c"
}

# print red color text
function red(){
    echo -e "\033[41m\033[01m$1\033[0m \c"
}

# print cyan color text
function cyan(){
    echo -e "\033[96m\033[01m$1\033[0m \c"
}

# log info message
function LOG(){
    green "[INFO ]"
    echo $2 $1 
}

# log warning message
function LOG_W(){
    yellow "[WARN ]"
    echo $2 $1 
}

# log error message
function LOG_E(){
    red "[ERROR]"
    echo $2 $1 
}

# log command message
function LOG_C(){
    cyan "[CMD  ]"
    echo $2 $1
    eval $1
}


#############################################
# check os version                          #
#############################################

# get os name
OS_NAME=$(cat /etc/lsb-release |grep DISTRIB_ID |cut -d'=' -f 2)

# get os version
OS_VERSION=$(cat /etc/lsb-release |grep DISTRIB_RELEASE |cut -d'=' -f 2)

LOG "Detect OS version: $OS_NAME $OS_VERSION"

if [[ "$OS_NAME" != "Ubuntu" || "$OS_VERSION" != "22.04" ]]
then

    # this script only verified on Ubuntu 22.04 LTS, 
    # show the warning message if run in not verified version.
    LOG_W "Wronging! This script only verified on Ubuntu 22.04."
    
    # check user input to continue
    read -p "press y to continue..." re
    echo
    if [[ "$re" != "y" && "$re" != "Y" ]]
    then
        LOG "Exit script..."
        exit 0
    fi
fi


#############################################
# print configs                             #
#############################################


LOG "Script Configs:"
echo "
Config Git user name: $USEREMAL
Config Git user mail: $USERNAME
Run apt update and upgrade: $UPDATE_UBUNTU
Install Google Chrome Browser: $INSTALL_CHROME_BROWSER
Install Visual Studio Code: $INSTALL_VSCODE
Install Tabby: $INSTALL_TABBY
Install Minicom: $INSTALL_MINICOM
Install Meld: $INSTALL_MELD
Install Gparted: $INSTALL_GPARTED
Install Net-tool: $INSTALL_NETTOOL
Install Tree: $INSTALL_TREE
Install Gnome-Screenshot: $INSTALL_SCREENSHOT
Sync tast-tests-private repo: $SYNC_TAST_TESTS_PRIVATE
Chroot dev tools: $INSTALL_DEV_TOOL
Chroot repo sync: $CHROOT_REPO_SYNC
Chroot sync jobs: $CHROOT_SYNC_JOBS
Chroot run cros_sdk: $CHROOT_CREATE
Chroot run setup_board: $CHROOT_SETUP_BOARD
Chroot setup_board target: $CHROOT_SETUP_BOARD
Setup docker Servod: $SETUP_DOCKER_SERVOD
"

# check user input to continue
read -p "press y to continue..." re
echo
if [[ "$re" != "y" && "$re" != "Y" ]]
then
    LOG "Exit script..."
    exit 0
fi

#############################################
# alias                                     #
#############################################

# defend themselves against accidentally deleting files by creating an alias
echo "alias rm='rm -i'" >> ~/.bashrc

# always clear known_hosts to prevent issue "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"
echo "alias scp='rm -f /home/$USER/.ssh/known_hosts;scp'" >> ~/.bashrc
echo "alias ssh='rm -f /home/$USER/.ssh/known_hosts;ssh'" >> ~/.bashrc

# Use nano when edit commit message
echo "alias EDITOR='nano'" >> ~/.bashrc

# Use gitlog to quickly print oneline git log
echo "alias gitlog='git log --pretty=oneline'" >> ~/.bashrc

source ~/.bashrc

#############################################
# Install useful tool
# e.g. google chrome, visual studio code, etc.
#############################################


LOG "Start to install useful tool..."


cd ~

# update and upgrade ubuntu package
if [[ "$UPDATE_UBUNTU" == "Y" ]]
then
    LOG "Update and upgrade ubuntu package"
    sudo apt-get update && sudo apt-get -y upgrade
fi

# install Google Chrome Browser
if [[ "$INSTALL_CHROME_BROWSER" == "Y" ]]
then
    LOG "Install Google Chrome Browser"
    wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb
    rm ./google-chrome-stable_current_amd64.deb
fi

# install Visual Studio Code
if [[ "$INSTALL_VSCODE" == "Y" ]]
then
    LOG "Install Visual Studio Code"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    sudo apt install apt-transport-https
    sudo apt update
    sudo apt install code

    # install vscode extensions
    LOG "Install Visual Studio Code extensions"
    code --install-extension ms-ceintl.vscode-language-pack-zh-hant   # Chinese :)
    code --install-extension ms-vscode.cpptools                       # C/C++
    code --install-extension ms-vscode.cpptools-extension-pack        # C/C++ Extension Pack
    code --install-extension ms-vscode.cpptools-themes                # C/C++ Themes
    code --install-extension streetsidesoftware.code-spell-checker    # Code Spell Checker
    code --install-extension plorefice.devicetree                     # DeviceTree

    # setup settings.json
    settings="{
    \"editor.fontFamily\": \"Consolas, 'Courier New', monospace\",
    \"editor.mouseWheelZoom\": true,
    \"editor.tabSize\": 8,
    \"window.zoomLevel\": 1.2
}"
    echo "$settings" > ~/.config/Code/User/settings.json

    # setup keybindings.json
    keybindings="[
        {
                \"key\": \"ctrl+left\",
                \"command\": \"workbench.action.nextEditorInGroup\"
        },
        {
                \"key\": \"ctrl+k ctrl+pagedown\",
                \"command\": \"-workbench.action.nextEditorInGroup\"
        },
        {
                \"key\": \"ctrl+right\",
                \"command\": \"workbench.action.previousEditorInGroup\"
        },
        {
                \"key\": \"ctrl+k ctrl+pageup\",
                \"command\": \"-workbench.action.previousEditorInGroup\"
        },
        {
                \"key\": \"alt+x\",
                \"command\": \"workbench.action.navigateBack\",
                \"when\": \"canNavigateBack\"
        },
        {
                \"key\": \"ctrl+alt+-\",
                \"command\": \"-workbench.action.navigateBack\",
                \"when\": \"canNavigateBack\"
        }
]"

    echo "$keybindings" > ~/.config/Code/User/keybindings.json

fi

# install Tabby (terminal tool)
if [[ "$INSTALL_TABBY" == "Y" ]]
then
    LOG "Install Tabby"
    sudo apt install wget apt-transport-https
    sudo snap install curl
    curl -s https://packagecloud.io/install/repositories/eugeny/tabby/script.deb.sh | sudo bash
    sudo apt install -y tabby-terminal
fi

if [[ "$INSTALL_MINICOM" == "Y" ]]
then
    LOG "Install Minicom"
    sudo apt install -y minicom
fi

if [[ "$INSTALL_MELD" == "Y" ]]
then
    LOG "Install Meld"
    sudo apt-get install -y meld 
fi

if [[ "$INSTALL_GPARTED" == "Y" ]]
then
    LOG "Install Gparted"
    sudo apt-get install -y gparted
fi

if [[ "$INSTALL_NETTOOL" == "Y" ]]
then
    LOG "Install Net-tools"
    sudo apt-get install -y net-tools 
fi

if [[ "$INSTALL_GHEX" == "Y" ]]
then
    LOG "Install Ghex"
    sudo apt-get install -y ghex 
fi

if [[ "$INSTALL_TREE" == "Y" ]]
then
    LOG "Install Tree"
    sudo apt-get install -y tree 
fi

if [[ "$INSTALL_SCREENSHOT" == "Y" ]]
then
    LOG "Install Gnome-Screenshot"
    sudo apt-get install -y gnome-screenshot
fi

if [[ "$INSTALL_CHEWING" == "Y" ]]
then
    LOG "Install Chewing"
    sudo apt install -y ibus-chewing
fi


#############################################
# Install development tools
# https://chromium.googlesource.com/chromiumos/docs/+/HEAD/developer_guide.md#install-development-tools
#############################################

if [[ "$INSTALL_DEV_TOOL" == "Y" ]]
then
    LOG "Start to install development tool..."
    sudo add-apt-repository universe
    sudo apt-get install -y git gitk git-gui curl xz-utils python3-pkg-resources python3-virtualenv python3-oauth2client
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    echo "export PATH=$PATH:~/depot_tools" >> ~/.bashrc
    # If you plan to work with chroot frequently, Adding an alias to enter chroot will be convenient.
    echo "alias ch='cd ~/chromiumos;cros_sdk --no-ns-pid'" >> ~/.bashrc
    source ~/.bashrc
    git config --global user.email $USEREMAL
    git config --global user.name $USERNAME
    mkdir -p ~/chromiumos
    cd ~/chromiumos
fi



#############################################
# Start to download source code and build chroot
# https://chromium.googlesource.com/chromiumos/docs/+/HEAD/developer_guide.md#install-development-tools
#############################################

LOG "Start to download source code and build chroot..."

# 
# 'source ~/.bashrc' will not working in same script
# Some platforms come with a ~/.bashrc that has a conditional at 
# the top that explicitly stops processing if the shell is found to be non-interactive.
# https://stackoverflow.com/questions/43659084/source-bashrc-in-a-script-not-working
#
export PATH=$PATH:~/depot_tools

if [[ "$CHROOT_REPO_INIT" == "Y" ]]
then
    repo init -u https://chromium.googlesource.com/chromiumos/manifest -b stable
fi

# Get private repo tast-tests-private
# internal gerrit ssh key is necessary for sync private repo

private_repo_xml="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<manifest>
<remote name=\"cros-internal\"
fetch=\"https://chrome-internal.googlesource.com\"
review=\"https://chrome-internal-review.googlesource.com\">
<annotation name=\"public\" value=\"false\" />
</remote>
<remote name=\"chrome\"
alias=\"cros-internal\"
fetch=\"https://chrome-internal.googlesource.com\">
<annotation name=\"public\" value=\"false\" />
</remote>
<project path=\"src/platform/tast-tests-private\"
remote=\"cros-internal\"
name=\"chromeos/platform/tast-tests-private\" />
</manifest>
"

# setup ssh key and sync tast-tests-private repo
if [[ "$SYNC_TAST_TESTS_PRIVATE" == "Y" && "$ssh_key" == "Y" ]]
then

    LOG "Try to sync tast-tests-private repo"

    # setup ssh key
    LOG "Setup ssh key..."
    setup_ssh_key

    # Add tast-tests-private in local_manifests
    LOG "Add tast-tests-private in local_manifests"
    mkdir -p ~/chromiumos/.repo/local_manifests
    touch ~/chromiumos/.repo/local_manifests/tast-tests-private.xml
    echo "$private_repo_xml" > ~/chromiumos/.repo/local_manifests/tast-tests-private.xml

fi

# sync source code
if [[ "$CHROOT_REPO_SYNC" == "Y" ]]
then
    LOG "sync source code"
    repo sync -j $CHROOT_SYNC_JOBS
fi

# create chroot after repo sync
if [[ "$CHROOT_CREATE" == "Y" ]]
then
    LOG "create chroot"
    cros_sdk --create
fi

# run setup board after create chroot
if [[ "$CHROOT_SETUP_BOARD" == "Y" && "$BOARD" != "" ]]
then
    LOG "setup board"
    cros_sdk setup_board --board=$CHROOT_TATGET_BOARD
fi


#############################################
# Servod Outside of Chroot
# https://chromium.googlesource.com/chromiumos/third_party/hdctools/+/main/docs/servod_outside_chroot.md
#############################################

if [[ "$SETUP_DOCKER_SERVOD" == "Y" ]]
then

    LOG "Setup docker Servod"

    #  Install Docker Engine on Ubuntu
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Test Docker Engine
    LOG "Test Docker Engine..."
    re=$(sudo docker run hello-world|grep "Hello from Docker!")
    if [[ "$re" == "" ]]
    then
        LOG "Install Docker Engine fail!"
        exit 0
    fi

    # Setup run Docker without sudo
    # sometime this blocks script, run this command in background
    # https://unix.stackexchange.com/questions/18897/problem-while-running-newgrp-command-in-script
    # sudo groupadd docker
    # sudo usermod -aG docker $USER
    # newgrp docker

    re=$(getent group|grep docker)
    if [[ "$re" == "" ]]
    then
        sudo groupadd docker &
    fi

    # fix automatically exited after running
    sudo usermod -aG docker $USER &
    newgrp docker &

    # Test Docker Engine without sudo
    LOG "Test Docker Engine without sudo..."

    re=$(docker run hello-world|grep "Hello from Docker!")
    if [[ "$re" == "" ]]
    then
        LOG_E " Setup run Docker without sudo fail!"
        exit 0
    fi

    # Config Docker to start via systemd
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    # Setup tty group, PATH and docker API
    sudo usermod -aG tty $USER

    # install python3-docker and
    # check python able to import docker class
    sudo apt install python3-docker
    LOG "Test import docker in python3..."
    re=$(echo "import docker" | python3)
    if [[ "$re" != "" ]]
    then
        LOG_E "import docker fail:"
        echo $re
        LOG "Exit script..."
        exit 0
    fi

    # Add hdctools path to $PATH
    echo "export PATH=~/chromiumos/src/third_party/hdctools/scripts:$PATH" >> ~/.bashrc
    source ~/.bashrc

    echo "Config Servod Done!"

fi

echo "Install Finish!"
