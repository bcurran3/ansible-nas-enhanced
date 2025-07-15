#!/bin/bash

if [[ "$1" == "--enabled" ]]; then
cat inventories/supernas/group_vars/nas.yml |grep 'enabled: true'
exit
fi

nano inventories/supernas/group_vars/nas.yml
