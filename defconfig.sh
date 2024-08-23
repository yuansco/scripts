#!/bin/bash
# defconfig.sh
# https://github.com/yuansco/scripts
# Created by Yu-An Chen on 2024/08/23
# Last modified on 2024/08/23
# Vertion: 1.0

#############################################
# Config                                    #
#############################################

# User name and email address for setup git
# TODO: (1) update your name amd mail
USEREMAL="foo@quanta.corp-partner.google.com"
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
# Note: config gerrit ssh key is necessary for sync private repo
# TODO: (2) turn on sync tast-tests-private repo if needed
SYNC_TAST_TESTS_PRIVATE="N"

# sync strauss repo
# Note: config gerrit ssh key is necessary for sync private repo
# TODO: (3) turn on sync strauss repo if needed
SYNC_STRAUSS="N"


# Chroot config:
CHROOT_REPO_INIT="Y"            # init repo folder
CHROOT_REPO_SYNC="Y"            # sync source code
CHROOT_SYNC_JOBS=8              # allow N jobs at repo sync
CHROOT_CREATE="Y"               # create chroot after repo sync
CHROOT_SETUP_BOARD="Y"          # run setup board after create chroot

# TODO: (4) select a baseboard name for setup_board, default is nissa
CHROOT_TATGET_BOARD="nissa"     # baseboard for setup_board command

# Setup docker Servod
SETUP_DOCKER_SERVOD="Y"


#############################################
# gerrit ssh key                            #
#############################################

#
# Chromium Gerrit key:
# https://chromium-review.googlesource.com/settings/#HTTPCredentials
# HTTP Credentials > Obtain password (opens in a new tab) > Configure Git
#
# Chromium Internal Gerrit key:
# https://chrome-internal-review.googlesource.com/settings/#HTTPCredentials
# HTTP Credentials > Obtain password (opens in a new tab) > Configure Git

# TODO: (5) Add your gerrit ssh key if needed

# Chromium Gerrit key:
function chromium_gerrit_key(){
    # TODO
    return
}

# Chromium Internal Gerrit key:
function chromium_internal_gerrit_key(){
    # TODO
    return
}

