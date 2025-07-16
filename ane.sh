#!/bin/bash

if [[ "$1" == "--enabled" ]]; then
     cat inventories/supernas/group_vars/nas.yml |grep 'enabled: true'
     exit
fi

# git info
if [ "$1" = "--git" ]; then
    echo "# of commits behind:"
    git fetch
    git rev-list --count HEAD..@{u}
    exit
fi

# git force pull
if [ "$1" = "--gitforcepull" ]; then
    git fetch --all
    git reset --hard origin/main
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

# update.sh help menu
if [ "$1" = "--help" ]; then
    echo "--help"
    echo "  This menu"
    echo "--enabled"
    echo "  List enabled apps"
    echo "--git"
    echo "  Check # of git commits you are behind"
    echo "--prune"
    echo "  Prune docker unused images and volumes"
    echo "--requirements"
    echo "  Install ANE requirements"
    echo "--settings"
    echo "  Edit ANE settings"
    exit
fi

# --tags "taskname"
ansible-playbook -i inventories/supernas/inventory nas.yml -b -K $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10}
