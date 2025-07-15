#!/bin/bash

# prune docker stuff to save space
if [ "$1" = "--prune" ]; then
    echo y | docker image prune
    echo y | docker volume prune
    exit
fi

# git info
if [ "$1" = "--git" ]; then
    echo not implemented yet
# BEHIND=`git rev-list ...@{u} --count`
# git log -$BEHIND ...@{u} --pretty=format:"%h - %an, %ar : %s"
    exit
fi

# install ansible-nas requirements
if [ "$1" = "--requirements" ]; then
    ansible-galaxy install -r requirements.yml
    exit
fi

# update.sh help menu
if [ "$1" = "--help" ]; then
    echo "--help menu placeholder"
    exit
fi

# --tags "taskname"
ansible-playbook -i inventories/supernas/inventory nas.yml -b -K $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10}
