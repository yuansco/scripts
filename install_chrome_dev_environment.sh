#!/bin/bash
# Install Chromebook develop environment script
# https://github.com/yuansco/scripts
# Created by Yu-An Chen on 2024/03/26
# Last modified on 2024/11/19
# Vertion: 1.0

# How to use: Run this script in Ubuntu 22.04

#############################################
# Config                                    #
#############################################

# Set the git global config, including username and email ("Y" or "N"):
# Note: It is necessary for download source code
SETUP_GIT_GLOBAL_CONFIG="Y"

# TODO: (1) update your name amd mail if needed
GIT_USER_EMAIL="foo@gmail.com"
GIT_USER_NAME="foo"


# run apt-get update and apt-get upgrade before install
UPDATE_UBUNTU="Y"

# Install useful tool config ("Y" or "N"):
INSTALL_CHROME_BROWSER="Y"      # Google Chrome Browser (web browser)
INSTALL_VSCODE="Y"              # Visual Studio Code (source code editor)
INSTALL_NOTEPAD="Y"             # Notepad++ (source code editor)
INSTALL_TABBY="Y"               # Tabby (terminal tool)
INSTALL_MINICOM="Y"             # Minicom (serial communication tool)
INSTALL_PICOCOM="Y"             # Picocom (serial communication tool)
INSTALL_MELD="Y"                # Meld (text compare tool)
INSTALL_GPARTED="Y"             # Gparted (disk partition editor)
INSTALL_NETTOOL="Y"             # Net-tool (for ifconfig command)
INSTALL_GHEX="Y"                # Ghex (hex editor)
INSTALL_TREE="Y"                # Tree (for tree command)
INSTALL_SCREENSHOT="Y"          # Gnome-Screenshot (screenshot tool)
INSTALL_CHEWING="Y"             # Chewing (Chinese input method)
INSTALL_WINE="Y"                # Wine (for run Windows applications)


# Chroot config:
CHROOT_DEV_TOOL="Y"                           # Chromium development tools
CHROOT_REPO_INIT="Y"                          # init repo folder
CHROOT_REPO_FOLDER="chromiumos"               # init folder name, default is ~/chromiumos/

# all branch: https://chromium.googlesource.com/chromiumos/manifest.git/+refs
CHROOT_REPO_BRANCH="stable"                   # stable branch (default)
#CHROOT_REPO_BRANCH="main"                    # main branch
#CHROOT_REPO_BRANCH="release-R130-16033.B"    # release branch
#CHROOT_REPO_BRANCH="release-R131-16063.B"    # release branch
#CHROOT_REPO_BRANCH="release-R132-16093.B"    # release branch

# sync manifest groups (minilayout+labtools)
# If you are on a slow network connection or have low disk space, you can use this option.
# https://chromium.googlesource.com/chromiumos/manifest/
CHROOT_REPO_MINILAYOUT="N"

CHROOT_REPO_SYNC="Y"                          # sync source code
CHROOT_SYNC_JOBS=8                            # allow N jobs at repo sync
CHROOT_CREATE="Y"                             # create chroot after repo sync
CHROOT_SETUP_BOARD="Y"                        # run setup board after create chroot

# TODO: (2) select a baseboard name for setup_board, default is rex
CHROOT_TATGET_BOARD="rex"                     # baseboard for setup_board command

# sync tast-tests-private repo
# Note: config gerrit key is necessary for sync private repo
CHROOT_SYNC_TAST_TESTS_PRIVATE="N"

# Setup docker Servod
# https://chromium.googlesource.com/chromiumos/third_party/hdctools/+/main/docs/servod_outside_chroot.md
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

# TODO: (3) Add your Gerrit HTTP Credentials if needed

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
        LOG_W "gerrit key not found! Please check gerrit key if you want to sync private repo"
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

# ping google source code server
internet_ok=$(ping chromium.googlesource.com -c 1 |grep "0% packet loss")

if [[ "$internet_ok" == "" ]]
then
    LOG_W "internet connection check fail!"
    read -p "press any key to continue..." re
fi


#############################################
# load defconfig                            #
#############################################

FILE=$(ls | grep def | grep .sh)

if [ -f "$FILE" ]; then
    LOG "loading $FILE"
    source ./$FILE
fi


#############################################
# print configs                             #
#############################################


LOG "Script Configs: (Y or other)"
echo "
Config Git user name: $GIT_USER_EMAIL
Config Git user mail: $GIT_USER_NAME
Run apt update and upgrade: $UPDATE_UBUNTU
Install Google Chrome Browser: $INSTALL_CHROME_BROWSER
Install Visual Studio Code: $INSTALL_VSCODE
Install Notepad++: $INSTALL_NOTEPAD
Install Tabby: $INSTALL_TABBY
Install Minicom: $INSTALL_MINICOM
Install Picocom: $INSTALL_PICOCOM
Install Meld: $INSTALL_MELD
Install Gparted: $INSTALL_GPARTED
Install Net-tool: $INSTALL_NETTOOL
Install Tree: $INSTALL_TREE
Install Gnome-Screenshot: $INSTALL_SCREENSHOT
Install Chewing: $INSTALL_CHEWING
Install Wine: $INSTALL_WINE
Chroot dev tools: $CHROOT_DEV_TOOL
Chroot branch: $CHROOT_REPO_BRANCH
Chroot repo sync: $CHROOT_REPO_SYNC
Chroot sync jobs: $CHROOT_SYNC_JOBS
Chroot sync minilayout: $CHROOT_REPO_MINILAYOUT
Chroot sync tast-tests-private repo: $CHROOT_SYNC_TAST_TESTS_PRIVATE
Chroot sync strauss repo: $CHROOT_SYNC_STRAUSS
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

alias_note="
# ========================================================
# following config is set through the auto install scripts
# See https://github.com/yuansco/scripts
# ========================================================
"

config_github=$(cat ~/.bashrc |grep github)

if [[ "$config_github" == "" ]]
then
    echo "$alias_note" >> ~/.bashrc
fi

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

config_gitlog=$(cat ~/.bashrc |grep gitlog)

if [[ "$config_gitlog" == "" ]]
then
    echo "alias gitlog='git log --pretty=oneline'" >> ~/.bashrc
fi

# Use ch to quickly enter cros_sdk

config_ch=$(cat ~/.bashrc |grep ch=)

if [[ "$config_ch" == "" ]]
then
    echo "alias ch='cd ~/$CHROOT_REPO_FOLDER;cros_sdk --no-ns-pid --no-update'" >> ~/.bashrc
fi

echo >> ~/.bashrc
echo >> ~/.bashrc

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
    code --install-extension ms-python.python                         # Python
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

# install Notepad++
if [[ "$INSTALL_NOTEPAD" == "Y" ]]
then
    LOG "Install Notepad++"
    sudo snap install notepad-plus-plus
fi

# install Tabby (terminal tool)
if [[ "$INSTALL_TABBY" == "Y" ]]
then
    LOG "Install Tabby"
    sudo apt install -y wget apt-transport-https
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

if [[ "$INSTALL_WINE" == "Y" ]]
then
    LOG "Install Wine"
    sudo apt-get install -y wine
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
if [[ "$CHROOT_DEV_TOOL" == "Y" ]]
then
    LOG "Start to install development tool..."
    sudo add-apt-repository -y universe
    sudo apt-get install -y git gitk git-gui curl
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    echo "export PATH=$PATH:~/depot_tools" >> ~/.bashrc
fi

if [[ "$SETUP_GIT_GLOBAL_CONFIG" == "Y" ]]
then
    LOG "Setup git global config"
    git config --global user.email $GIT_USER_EMAIL
    git config --global user.name $GIT_USER_NAME
    git config --global core.autocrlf false
    git config --global core.filemode false
    git config --global color.ui true
fi

#############################################
# Start to download source code and build chroot
# https://chromium.googlesource.com/chromiumos/docs/+/HEAD/developer_guide.md#install-development-tools
#############################################

LOG "Start to download source code and build chroot..."

mkdir -p ~/$CHROOT_REPO_FOLDER
cd ~/$CHROOT_REPO_FOLDER

# 
# 'source ~/.bashrc' will not working in same script
# Some platforms come with a ~/.bashrc that has a conditional at 
# the top that explicitly stops processing if the shell is found to be non-interactive.
# https://stackoverflow.com/questions/43659084/source-bashrc-in-a-script-not-working
#
export PATH=$PATH:~/depot_tools


if [[ "$CHROOT_REPO_MINILAYOUT" == "Y" ]]
then
    REPO_GROUP="-g minilayout,labtools"
fi

if [[ "$CHROOT_REPO_INIT" == "Y" ]]
then
    if [[ "$CHROOT_REPO_BRANCH" == "main" || "$CHROOT_REPO_BRANCH" == "stable" ]]
    then
        repo init -u https://chromium.googlesource.com/chromiumos/manifest -b $CHROOT_REPO_BRANCH $REPO_GROUP
    else
        repo init -u https://chromium.googlesource.com/chromiumos/manifest -b $CHROOT_REPO_BRANCH $REPO_GROUP --repo-url https://chromium.googlesource.com/external/repo.git
    fi
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
if [[ "$CHROOT_SYNC_TAST_TESTS_PRIVATE" == "Y" && "$have_gerrit_key" == "Y" ]]
then

    # Add tast-tests-private in local_manifests
    LOG "Add tast-tests-private repo in local_manifests"
    mkdir -p ~/$CHROOT_REPO_FOLDER/.repo/local_manifests
    touch ~/$CHROOT_REPO_FOLDER/.repo/local_manifests/tast-tests-private.xml
    echo "$private_repo_xml" > ~/$CHROOT_REPO_FOLDER/.repo/local_manifests/tast-tests-private.xml
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
mkdir -p ~/$CHROOT_REPO_FOLDER/src/myfile
mkdir -p ~/$CHROOT_REPO_FOLDER/src/myfile/firmware
mkdir -p ~/$CHROOT_REPO_FOLDER/src/myfile/cbi
mkdir -p ~/$CHROOT_REPO_FOLDER/src/myfile/scripts


# Always show debug logs when building ec firmware through zmake
# Add environment variables in cros_sdk's bashrc

FILE="$HOME/$CHROOT_REPO_FOLDER/out/home/$USER/.bashrc"

zmake_alias=$(cat $FILE |grep zmake)

if [ -f "$FILE" ]
then
    if [ -z "$zmake_alias" ]
    then
        LOG "Setup zmake alias"
        echo "alias zmake='zmake -l DEBUG'" >> $FILE
    else
        LOG "zmake alias is ready"
    fi
else
    LOG_W "Setup alias zmake fail! file not exists: $FILE"
fi


#############################################
# Servod Outside of Chroot
# https://chromium.googlesource.com/chromiumos/third_party/hdctools/+/main/docs/servod_outside_chroot.md
#############################################

if [[ "$SETUP_DOCKER_SERVOD" == "Y" ]]
then

    LOG "Setup docker Servod"

    # Add hdctools path to $PATH
    echo "export PATH=~/$CHROOT_REPO_FOLDER/src/third_party/hdctools/scripts:$PATH" >> ~/.bashrc
    source ~/.bashrc

    #  Install Docker Engine on Ubuntu
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
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

