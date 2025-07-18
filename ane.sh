#!/bin/bash
##
##      _         _   _       _____
##     / \       | \ | |     | ____|
##    / _ \ _____|  \| |_____|  _|
##   / ___ \_____| |\  |_____| |___
##  /_/   \_\    |_| \_|     |_____|
##
##  Ansible-NAS-Enhanced - https://github.com/bcurran3/ansible-nas-enhanced

if [ "$1" = "--enabled" ]; then
     echo "*** ANE enabled apps:"
     cat inventories/ANE/group_vars/nas.yml |grep 'enabled: true'
     exit
fi

# git force pull
# DO NOT USE: for dev use
if [ "$1" = "--gitforcepull" ]; then
    git fetch --all
    git reset --hard origin/main
    exit
fi

# install ANE
if [ "$1" = "--install" ]; then
    if [ -d "inventories/ANE" ]; then
       echo "WARNING: inventories/ANE exists!"
       echo "         \"rm inventories/ANE -R\" first if you really wish to reset."
       exit
    fi
    cp -rfp inventories/sample inventories/ANE
    echo "Time to configure!"
    echo "\"./ane.sh --inventory\" to edit your inventory file"
    echo "\"./ane.sh --settings\" to edit your settings file"
    exit
fi

# edit inventory file
if [ "$1" = "--inventory" ]; then
    nano inventories/ANE/inventory
    exit
fi

# git check commits
if [ "$1" = "--outdated" ]; then
#TDL: add --updates
    git fetch
    BEHIND=$(git rev-list --count HEAD..@{u})
    echo "Your ANE installation is $BEHIND git commits behind."
    if [ $BEHIND -gt 1 ]; then
       echo "\"./ane.sh --update\" or \"git pull\" to update"
    fi
    exit
fi

# reset shared file permissions
if [ "$1" = "--permissions" ]; then
    ansible-playbook -i inventories/ANE/inventory permission_data.yml -b -K
    exit
fi

# prune docker stuff to save space
if [ "$1" = "--prune" ]; then
    echo y | docker image prune
    echo y | docker volume prune
    exit
fi

# install ANE requirements
if [ "$1" = "--requirements" ]; then
    ansible-galaxy install -r requirements.yml
    exit
fi

# edit ANE settings/variables
if [ "$1" = "--settings" ]; then
    nano inventories/ANE/group_vars/nas.yml
    exit
fi

# update ANE files
if [ "$1" = "--update" ]; then
    git pull
    exit
fi

# ANE help menu
if [ "$1" = "--help" ]; then
    echo "Ansible-NAS-Enhanced (ANE) Help:"
    echo "  --help"
    echo "    This menu!"
    echo "  --enabled"
    echo "    List ANE enabled apps"
    echo "  --install"
    echo "    Install Anisible-NAS-Enhanced (first time or reset)"
    echo "  --inventory"
    echo "    Edit ANE inventory file"
    echo "  --outdated, --updates"
    echo "    Check # of git commits your install of ANE is behind"
    echo "  --permissions"
    echo "    Reset permissions on all shared files"
    echo "  --prune"
    echo "    Prune unused Docker images and volumes"
    echo "  --requirements"
    echo "    Install/re-install ANE requirements"
    echo "  --settings"
    echo "    Edit ANE settings/overrides"
    echo "  -t appname"
###         ^^^^ going to make this more intuitive
    echo "    Update ANE app"
    echo "  --update"
    echo "    Update ANE files from git"
    exit
fi

# --tags "taskname"
ansible-playbook -i inventories/ANE/inventory nas.yml -b -K $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10}
