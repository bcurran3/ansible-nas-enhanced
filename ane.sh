#!/bin/bash

if [[ "$1" == "--enabled" ]]; then
     echo "*** ANE enabled apps:"
     cat inventories/supernas/group_vars/nas.yml |grep 'enabled: true'
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
    echo "Not implemented yet. (Sorry!)"
# copy default group_vars and inventory stuff here
    exit
fi

# git info
if [ "$1" = "--outdated" ]; then
#TDL: add --updates
    echo "# of git commits behind:"
    git fetch
    git rev-list --count HEAD..@{u}
# TDL: save commits to varialbe and then display the following if greater than 1
    echo "\"./ANE.sh --update\" or \"git pull\" to update"
    exit
fi

# prune docker stuff to save space
if [ "$1" = "--prune" ]; then
    echo y | docker image prune
    echo y | docker volume prune
    exit
fi

# install ansible-nas requirements
if [ "$1" = "--requirements" ]; then
    ansible-galaxy install -r requirements.yml
    exit
fi

# edit ansible-nas variables
if [ "$1" = "--settings" ]; then
    nano inventories/supernas/group_vars/nas.yml
    exit
fi

# update ANE with a git pull
if [ "$1" = "--update" ]; then
    git pull
    exit
fi

# update.sh help menu
if [ "$1" = "--help" ]; then
    echo "ANE HELP:"
    echo "--help"
    echo "  This menu!"
    echo "--enabled"
    echo "  List enabled apps"
    echo "--install"
    echo "  Install ANE \(first time or reset\)"
    echo "--outdated, --updates"
    echo "  Check # of git commits your install of ANE is behind"
    echo "--prune"
    echo "  Prune unused Docker images and volumes"
    echo "--requirements"
    echo "  Install/reinstall ANE requirements"
    echo "--settings"
    echo "  Edit ANE settings/overrides"
    echo "--update"
    echo "  Update ANE files from git"
    exit
fi

# --tags "taskname"
ansible-playbook -i inventories/supernas/inventory nas.yml -b -K $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10}
