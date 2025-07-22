#!/bin/bash
# Ansible-NAS-Enhanced (ANE) installation script

##      _    _   _ _____
##     / \  | \ | | ____|
##    / _ \ |  \| |  _|
##   / ___ \| |\  | |___
##  /_/   \_\_| \_|_____|
##
##  Ansible-NAS-Enhanced - https://github.com/bcurran3/ansible-nas-enhanced

### VARS

REPO="https://gitea.mrbillsabode.org/bill/supernas"
INSTALL_DIR="ANE"

### FUNCTIONS

# print intention
function print1 {
  echo -e "\033[36m ** INFO: $1\033[0m"
}

# print success
function print2 {
  echo -e "\033[32m ** SUCCESS: $1\033[0m"
}

# print error
function print3 {
  echo -e "\033[31m ** ERROR: $1\033[0m"
  exit 1
}

function print_info {
    echo -e " **** \033[01mAnsible-NAS-Enhanced (ANE) installation script. ****\033[0m"
    print1 "This script will:"
    print1 "  - Upgrade apt packages and install required packages (Ansible, git, nano, etc.)."
    print1 "  - Clone the ANE files from $REPO to $(pwd)/$INSTALL_DIR."
    print1 "  - Setup ANE for first time use."
    print1 "  - That pretty much covers it. Enjoy!"
    while true; do
        read -p "Do you want to continue (y/n)? " -n 1 -r yn
        case "$yn" in
            [Yy]* ) printf "\n"; return 0;;
            [Nn]* ) printf "\n"; print3 "Aborting...";;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

function get_os {
    if [ -f /etc/lsb-release ]; then
       print1 "Getting OS and version..."
        . /etc/lsb-release
        if [ $? -ne 0 ]; then print3 "Unknown distribution. Aborting..."; fi
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
        print2 "Found $OS $VER"
    fi
}

function install_git {
    print1 "Updating apt cache and upgrading packages..."
    sudo apt update && sudo apt upgrade -y
    if [ $? -ne 0 ]; then print3 "Aborting..."; fi
    print2 "apt packages upgraded."
    print1 "Installing git..."
    sudo apt install git -y
    if [ $? -ne 0 ]; then print3 "Aborting..."; fi
    print2 "git installed."
}

function clone_repo {
    print1 "Cloning ANE repo..."
    git clone $REPO $INSTALL_DIR
    if [ $? -ne 0 ]; then print3 "Aborting..."; fi
    print2 "ANE repo cloned to $(pwd)/$INSTALL_DIR."
}

function install_packages {
    print1 "Installing ANE required packages (Ansible and nano)..."
        sudo apt-add-repository ppa:ansible/ansible -y
        sudo apt update && sudo apt install ansible nano -y
        if [ $? -ne 0 ]; then print3 "Aborting..."; fi
    fi
    print2 "Required packages installed."
}

function default_config {
    cd $INSTALL_DIR
    print1 "Copying ANE default config files..."
    cp -rfp inventories/sample inventories/ANE
    if [ $? -ne 0 ]; then print3 "Aborting..."; fi
    print2 "ANE default config files copied."
    print1 "Installing ANE required Ansible Galaxy roles..."
    ansible-galaxy install -r requirements.yml
    if [ $? -ne 0 ]; then print3 "Aborting..."; fi
    print2 "ANE required Ansible Galaxy roles installed."
    print1 "Ensuring ane.sh is executable."
    sudo chmod +x ./ane.sh
    if [ $? -ne 0 ]; then print3 "Aborting..."; fi
    print2 "ane.sh is executable."
}

function setup_instructions {
    echo -e " **** \033[01mAnsible-NAS-Enhanced (ANE) installed! ****\033[0m"
    print1 "\"cd $INSTALL_DIR\" to enter the ANE installation location."
    print1 "\"./ane.sh --inventory\" to edit your inventory file"
    print1 "\"./ane.sh --settings\" to edit your settings/overrides file (enable apps)"
    print1 "\"./ane.sh --run\" to run the ANE playbook"
    print1 "\"./ane.sh --help\" for more options"
}

### INSTALL

if [ "$1" ]; then
  INSTALL_DIR="$1"
fi

if [ -d ./$INSTALL_DIR ]; then
    print3 "Please remove or rename ./$INSTALL_DIR and try again."
fi

print_info
get_os
install_git
clone_repo
install_packages
default_config
setup_instructions
