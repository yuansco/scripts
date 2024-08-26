#!/bin/bash
# Install Chromebook develop environment script
# https://github.com/yuansco/scripts
# Created by Yu-An Chen on 2024/03/26
# Last modified on 2024/08/27
# Vertion: 1.0

# How to use: Run this script in Ubuntu 22.04

#############################################
# Config                                    #
#############################################

# User name and email address for setup git
# TODO: (1) update your name amd mail
USEREMAL="foo@gmail.com"
USERNAME="foo"


# run apt-get update and apt-get upgrade before install
UPDATE_UBUNTU="Y"

# Install useful tool config("Y" or other):
INSTALL_CHROME_BROWSER="Y"      # Google Chrome Browser
INSTALL_VSCODE="Y"              # Visual Studio Code
INSTALL_TABBY="Y"               # Tabby (terminal tool)
INSTALL_MINICOM="Y"             # Minicom (serial communication tool)
INSTALL_PICOCOM="Y"             # Picocom (serial communication tool)
INSTALL_MELD="Y"                # Meld (text compare tool)
INSTALL_GPARTED="Y"             # Gparted (disk partition editor)
INSTALL_NETTOOL="Y"             # Net-tool (for ifconfig command)
INSTALL_GHEX="Y"                # Ghex (hex editor)
INSTALL_TREE="Y"                # Tree (for tree command)
INSTALL_SCREENSHOT="Y"          # Gnome-Screenshot (screenshot tool)
INSTALL_CHEWING="Y"             # Chewing (Chinese Input Method)
INSTALL_DEV_TOOL="Y"            # chromium releate tools


# sync tast-tests-private repo
# Note: config gerrit key is necessary for sync private repo
# TODO: (2) turn on sync tast-tests-private repo if needed
SYNC_TAST_TESTS_PRIVATE="N"

# sync strauss repo
# Note: config gerrit key is necessary for sync private repo
# TODO: (3) turn on sync strauss repo if needed
SYNC_STRAUSS="N"


# Chroot config:
CHROOT_REPO_INIT="Y"                          # init repo folder

# all branch: https://chromium.googlesource.com/chromiumos/manifest.git/+refs
CHROOT_REPO_BRANCH="stable"                   # stable branch (default)
#CHROOT_REPO_BRANCH="main"                    # main branch
#CHROOT_REPO_BRANCH="release-R128-15964.B"    # release branch
#CHROOT_REPO_BRANCH="release-R129-16002.B"    # release branch

CHROOT_REPO_SYNC="Y"                          # sync source code
CHROOT_SYNC_JOBS=8                            # allow N jobs at repo sync
CHROOT_CREATE="Y"                             # create chroot after repo sync
CHROOT_SETUP_BOARD="Y"                        # run setup board after create chroot

# TODO: (4) select a baseboard name for setup_board, default is nissa
CHROOT_TATGET_BOARD="nissa"     # baseboard for setup_board command

# Setup docker Servod
SETUP_DOCKER_SERVOD="Y"


#############################################
# Gerrit HTTP Credentials                   #
#############################################

#
# Chromium Gerrit HTTP Credentials:
# https://chromium-review.googlesource.com/settings/#HTTPCredentials
# HTTP Credentials > Obtain password (opens in a new tab) > Configure Git
#
# Chromium Internal Gerrit HTTP Credentials:
# https://chrome-internal-review.googlesource.com/settings/#HTTPCredentials
# HTTP Credentials > Obtain password (opens in a new tab) > Configure Git

# TODO: (5) Add your Gerrit HTTP Credentials if needed

function chromium_gerrit_key(){
    # TODO: paste your Gerrit HTTP Credentials here
    return
}

function chromium_internal_gerrit_key(){
    # TODO: paste your Internal Gerrit HTTP Credentials here
    return
}

function setup_gerrit_key(){

    FILE=~/.gitcookies
    if [ -f "$FILE" ]; then
        LOG "gerrit key is ready"
        have_gerrit_key="Y"
        return
    fi

    chromium_gerrit_key
    chromium_internal_gerrit_key

    if [ -f "$FILE" ]; then
        LOG "Setup gerrit key done"
        have_gerrit_key="Y"
    else
        LOG_W "Setup gerrit key fail! Please check gerrit key"
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
    exit 0
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
# check internet connection                 #
#############################################

# ping google dns server
internet_ok=$(ping 8.8.8.8 -c 1 |grep "0% packet loss")

if [[ "$internet_ok" == "" ]]
then
    LOG_W "internet connection check fail!"
    read -p "press any key to continue..." re
fi


#############################################
# load defconfig                            #
#############################################

FILE=./defconfig.sh

if [ -f "$FILE" ]; then
    LOG "loading defconfig"
    source ./defconfig.sh
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
Install Picocom: $INSTALL_PICOCOM
Install Meld: $INSTALL_MELD
Install Gparted: $INSTALL_GPARTED
Install Net-tool: $INSTALL_NETTOOL
Install Tree: $INSTALL_TREE
Install Gnome-Screenshot: $INSTALL_SCREENSHOT
Chroot dev tools: $INSTALL_DEV_TOOL
Chroot repo sync: $CHROOT_REPO_SYNC
Chroot sync jobs: $CHROOT_SYNC_JOBS
Chroot sync tast-tests-private repo: $SYNC_TAST_TESTS_PRIVATE
Chroot sync strauss repo: $SYNC_STRAUSS
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

config_rm=$(cat ~/.bashrc |grep rm)

if [[ "$config_rm" == "" ]]
then
    echo "alias rm='rm -i'" >> ~/.bashrc
fi


# always clear known_hosts to prevent issue "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"

config_scp=$(cat ~/.bashrc |grep scp)

if [[ "$config_scp" == "" ]]
then
    echo "alias scp='rm -f /home/$USER/.ssh/known_hosts;scp'" >> ~/.bashrc
    echo "alias ssh='rm -f /home/$USER/.ssh/known_hosts;ssh'" >> ~/.bashrc
fi

# Use nano when edit commit message

config_nano=$(cat ~/.bashrc |grep nano)

if [[ "$config_nano" == "" ]]
then
    echo "alias EDITOR='nano'" >> ~/.bashrc
fi

# Use gitlog to quickly print oneline git log

config_nano=$(cat ~/.bashrc |grep gitlog)

if [[ "$config_gitlog" == "" ]]
then
    echo "alias gitlog='git log --pretty=oneline'" >> ~/.bashrc
fi

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
    \"window.zoomLevel\": 1.2,
    \"github.gitAuthentication\": false,
    \"git.terminalAuthentication\": false,
    \"C_Cpp.workspaceParsingPriority\": \"low\"
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

if [[ "$INSTALL_PICOCOM" == "Y" ]]
then
    LOG "Install Picocom"
    sudo apt install -y picocom
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
# Install private tool
# e.g. console tool, extract and flashdisk
#############################################


install_tool="Y"

# get zip key from $ZIPKEY or ~/.key.txt
if [[ "$ZIPKEY" == "" ]]
then

    if [ ! -f ~/.key.txt ]
    then
        install_tool="N"
    else
        ZIPKEY=$(cat ~/.key.txt)
    fi
fi


if [[ "$install_tool" == "Y" ]]
then

    LOG "Start to install private tool..."

    LOG "zip key: $ZIPKEY"

    # if we don't have whole repo, download expand script from github
    # this allows the script can running individually
    if [ ! -f ./script_update.sh ]
    then
        wget https://raw.githubusercontent.com/yuansco/scripts/main/script_update.sh
    fi

    if [ -f ./script_update.sh ]
    then
        chmod a+x ./script_update.sh

        # download and release scripts
        ./script_update.sh -d -r

        # clean up zip file
        ./script_update.sh -c

        # remove expand script
        rm -f ./script_update.sh
    else
        LOG_W "download expand script fail!"
    fi
fi

#############################################
# Install development tools
# https://chromium.googlesource.com/chromiumos/docs/+/HEAD/developer_guide.md#install-development-tools
#############################################

cd ~
if [[ "$INSTALL_DEV_TOOL" == "Y" ]]
then
    LOG "Start to install development tool..."
    sudo add-apt-repository universe
    sudo apt-get install -y git gitk git-gui curl xz-utils
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
    repo init -u https://chromium.googlesource.com/chromiumos/manifest -b $CHROOT_REPO_BRANCH
fi

# setup gerrit gerrit key
LOG "Setup gerrit key..."
setup_gerrit_key

# Get private repo tast-tests-private
# internal gerrit key is necessary for sync private repo

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

# sync tast-tests-private repo
if [[ "$SYNC_TAST_TESTS_PRIVATE" == "Y" && "$have_gerrit_key" == "Y" ]]
then

    # Add tast-tests-private in local_manifests
    LOG "Add tast-tests-private repo in local_manifests"
    mkdir -p ~/chromiumos/.repo/local_manifests
    touch ~/chromiumos/.repo/local_manifests/tast-tests-private.xml
    echo "$private_repo_xml" > ~/chromiumos/.repo/local_manifests/tast-tests-private.xml
fi

# Get private repo strauss
# internal gerrit key is necessary for sync private repo

strauss_xml="<manifest>
  <project remote=\"cros-internal\"
           path=\"src/platform/feature-x/strauss/ec\"
           name=\"chromeos/platform/strauss/ec\"
           groups=\"firmware\" />
</manifest>
"

# sync strauss repo
if [[ "$SYNC_STRAUSS" == "Y" && "$have_gerrit_key" == "Y" ]]
then

    # Add strauss in local_manifests
    LOG "Add strauss repo in local_manifests"
    mkdir -p ~/chromiumos/.repo/local_manifests
    touch ~/chromiumos/.repo/local_manifests/strauss.xml
    echo "$strauss_xml" > ~/chromiumos/.repo/local_manifests/strauss.xml
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
if [[ "$CHROOT_SETUP_BOARD" == "Y" && "$CHROOT_TATGET_BOARD" != "" ]]
then
    LOG "setup board"
    cros_sdk setup_board --board=$CHROOT_TATGET_BOARD
fi

# Setup folder tree
mkdir -p ~/chromiumos/src/myfile
mkdir -p ~/chromiumos/src/myfile/firmware
mkdir -p ~/chromiumos/src/myfile/cbi
mkdir -p ~/chromiumos/src/myfile/scripts


# Always show debug logs when building ec firmware through zmake
# Add environment variables in cros_sdk's bashrc

FILE="$HOME/chromiumos/out/home/$USER/.bashrc"
if [ -f "$FILE" ]; then
    LOG "Setup alias zmake"
    echo "alias zmake='zmake -l DEBUG'" >> $FILE
else
    LOG_W "Setup alias zmake fail, $FILE not exists!"
fi


#############################################
# Servod Outside of Chroot
# https://chromium.googlesource.com/chromiumos/third_party/hdctools/+/main/docs/servod_outside_chroot.md
#############################################

if [[ "$SETUP_DOCKER_SERVOD" == "Y" ]]
then

    LOG "Setup docker Servod"

    # Add hdctools path to $PATH
    echo "export PATH=~/chromiumos/src/third_party/hdctools/scripts:$PATH" >> ~/.bashrc
    source ~/.bashrc

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
        LOG_E "Install Docker Engine fail!"
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
        LOG_W "Setup run Docker without sudo fail!"
    fi

    # Config Docker to start via systemd
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    # Setup tty group, PATH and docker API
    sudo usermod -aG tty $USER

    # install python3-docker and
    # check python able to import docker class
    sudo apt install -y python3-docker
    LOG "Test import docker in python3..."
    re=$(echo "import docker" | python3)
    if [[ "$re" != "" ]]
    then
        LOG_E "import docker fail: $re"
    fi

    LOG "Config Servod Done!"

fi

LOG "Install Finish!"

