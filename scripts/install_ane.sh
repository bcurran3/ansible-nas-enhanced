#!/bin/bash
##
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
}

function print_info {
    echo -e " **** \033[01mAnsible-NAS-Enhanced (ANE) installation script. ****\033[0m"
    print1 "This script will make the directory $(pwd)/$INSTALL_DIR"
    print1 "and clone the files from $REPO into it."
    print1 "apt will be used to install required packages (Ansible, nano, etc.)."
    print1 "That pretty much covers it. Enjoy!"
    while true; do
        read -p "Do you want to continue (y/n)? " -n 1 -r yn
        case "$yn" in
            [Yy]* ) printf "\n"; return 0;;
            [Nn]* ) printf "\n"; print3 "Aborting..."; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

function get_os {
    if [ -f /etc/lsb-release ]; then
       print1 "Getting OS and version..."
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
        print2 "Found $OS $VER"
    fi
}

function install_git {
    print1 "Updating apt cache..."
    sudo apt update
    print1 "Installing git..."
    sudo apt install git -y
    print2 "git installed."
}

function clone_repo {
    if [ -d ./$INSTALL_DIR ]; then
       print3 "Please remove ./$INSTALL_DIR and try again."
       exit
    fi
    print1 "Making directory for git files..."
    mkdir ./$INSTALL_DIR
    cd ./$INSTALL_DIR
    print1 "Cloning ANE repo..."
    git clone $REPO
    print2 "ANE repo cloned."
}

function install_packages {
    print1 "Updating apt cache..."
    sudo apt update
    print1 "Installing required packages (Ansible and nano)..."
    if [[ "$VER" = "22.04" ]]; then
# ansible requires adding the repo to get a newer version
        sudo apt install git nano -y
    fi
    if [[ "$VER" = "24.04" ]]; then
        sudo apt install ansible nano -y
    fi
    if [[ "$VER" = "25.04" ]]; then
        sudo apt install ansible nano -y
    fi
    print2 "Required packages installed."
}

print_info
get_os
install_git
clone_repo
install_packages
