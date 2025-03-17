#!/bin/bash
# defconfig.sh
# https://github.com/yuansco/scripts
# Created by Yu-An Chen on 2024/08/23
# Last modified on 2025/03/17
# Vertion: 1.0

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
#CHROOT_REPO_BRANCH="release-R133-16151.B"    # release branch
#CHROOT_REPO_BRANCH="release-R134-16181.B"    # release branch
#CHROOT_REPO_BRANCH="release-R135-16209.B"    # release branch

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

# Adding enough swap space during installation can prevent OOM Killer
# from killing the installation process. If the machine has less
# than 16G of RAM, it is recommended to enable this setting.
SETUP_SWAP_DURING_INSTALL="Y"

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

