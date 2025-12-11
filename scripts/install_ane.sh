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

REPO="https://gitea.mrbillsabode.org/bill/ansible-nas-enhanced"
#REPO="https://github.com/bcurran3/ansible-nas-enhanced"
INSTALL_DIR="ANE"

### FUNCTIONS

# print intention
function print_info {
  echo -e "\033[36m ** INFO: $1\033[0m"
}

# print success
function print_success {
  echo -e "\033[32m ** SUCCESS: $1\033[0m"
}

# print error
function print_error {
  echo -e "\033[31m ** ERROR: $1\033[0m"
  exit 1
}

function print_info {
    echo -e " **** \033[01mAnsible-NAS-Enhanced (ANE) installation script. ****\033[0m"
    print_info "This script will:"
    print_info "  - Upgrade apt packages and install required packages (Ansible, git, nano, etc.)."
    print_info "  - Clone the ANE files from $REPO to $(pwd)/$INSTALL_DIR."
    print_info "  - Setup ANE for first time use."
    print_info "  - That pretty much covers it. Enjoy!"
    while true; do
        read -p "Do you want to continue (y/n)? " -n 1 -r yn
        case "$yn" in
            [Yy]* ) printf "\n"; return 0;;
            [Nn]* ) printf "\n"; print_error "Aborting...";;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# check if run with sudo
function check_sudo {
  if ! [ $(id -u) = 0 ]; then
    print_info "You MAY need to use sudo."
  fi
}

function get_os {
    if [ -f /etc/lsb-release ]; then
       print_info "Getting OS and version..."
        . /etc/lsb-release
        if [ $? -ne 0 ]; then print_error "Unknown distribution. Aborting..."; fi
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
        print_success "Found $OS $VER"
    fi
}

function install_git {
    print_info "Updating apt cache and upgrading packages..."
    sudo apt update && sudo apt upgrade -y
    if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    print_success "apt packages upgraded."
    print_info "Installing git..."
    sudo apt install git -y
    if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    print_success "git installed."
}

function clone_repo {
    print_info "Cloning ANE repo..."
    git clone $REPO $INSTALL_DIR
    if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    print_success "ANE repo cloned to $(pwd)/$INSTALL_DIR."
}

function install_packages {
    print_info "Installing ANE required packages (Ansible and nano)..."
    if [[ "$VER" = "22.04" ]]; then
        sudo apt-add-repository ppa:ansible/ansible -y
        if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    fi
    if [[ "$VER" = "24.04" ]]; then
        sudo apt-add-repository ppa:ansible/ansible -y
        if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    fi
        sudo apt update && sudo apt install ansible nano -y
        if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    print_success "Required packages installed."
}

function default_config {
    cd $INSTALL_DIR
    print_info "Copying ANE default config files..."
    cp -rfp inventories/sample inventories/ANE
    if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    print_success "ANE default config files copied."
    print_info "Installing ANE required Ansible Galaxy roles..."
    ansible-galaxy install -r requirements.yml
    if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    print_success "ANE required Ansible Galaxy roles installed."
    print_info "Ensuring ane.sh is executable."
    sudo chmod +x ./ane.sh
    if [ $? -ne 0 ]; then print_error "Aborting..."; fi
    print_success "ane.sh is executable."
}

function setup_instructions {
    echo -e " **** \033[01mAnsible-NAS-Enhanced (ANE) installed! ****\033[0m"
    print_info "\"./ane.sh --inventory\" to edit your inventory file"
    print_info "\"./ane.sh --settings\" to edit your settings/overrides file (enable apps)"
    print_info "\"./ane.sh --run\" to run the ANE playbook"
    print_info "\"./ane.sh --help\" for more options"
}

### INSTALL

if [ "$1" ]; then
  INSTALL_DIR="$1"
fi

if [ -d ./$INSTALL_DIR ]; then
    print_error "Please remove or rename ./$INSTALL_DIR and try again."
fi

check_sudo
print_info
get_os
install_git
clone_repo
install_packages
default_config
cd $INSTALL_DIR
setup_instructions
