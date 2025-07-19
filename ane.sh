#!/bin/bash
##
##      _    _   _ _____
##     / \  | \ | | ____|
##    / _ \ |  \| |  _|
##   / ___ \| |\  | |___
##  /_/   \_\_| \_|_____|
##
##  Ansible-NAS-Enhanced - https://github.com/bcurran3/ansible-nas-enhanced

function help {
# ANE help menu
    echo "Ansible-NAS-Enhanced (ANE) Help:"
    echo "  --help"
    echo "    What you see now!"
############ should probably merge this to just one switch
    echo "  --app <app_name>"
    echo "    Install/Update one app by tag."
    echo "  --apps <app_name> <app_name> <app_name> <app_name>"
    echo "    Install/Update multiple apps by tag."
############
    echo "  --enabled"
    echo "    List ANE enabled apps."
    echo "  --install"
    echo "    Install ANE (first time or reset)."
    echo "  --inventory"
    echo "    Edit ANE inventory file."
    echo "  --outdated, --updates"
    echo "    Check # of git commits your install of ANE is behind."
    echo "  --permissions"
    echo "    Reset permissions on all shared files."
    echo "  --prune"
    echo "    Prune unused Docker images and volumes."
    echo "  --requirements"
    echo "    Install/Re-install ANE requirements."
    echo "  --run"
    echo "    Run ANE full playbook."
    echo "  --settings"
    echo "    Edit ANE settings/overrides."
    echo "  --update"
    echo "    Update ANE files from git"
    exit
}

if [[ -z "$1" ]]; then
       echo "  ** Run \"./ane.sh --help\" for help :-)"
     exit
fi

if [[ "$1" = "--ap" || "$1" = "-ap" || "$1" = "--aps" || "$1" = "-aps" ]]; then
     echo "  ** You typoed! :-("
     exit
fi

if [[ "$1" = "--app" || "$1" = "-app" ]]; then
     if [ "$2" = '' ]; then
        echo "  ** You need to specify an app name/tag."
        exit
     fi
     ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t $2
     exit
fi

if [[ "$1" = "--apps" || "$1" = "-apps" ]]; then
     if [ "$2" = '' ]; then
        echo "  ** You need to specify an app name/tag."
        exit
     fi
   appslist=""
   for arg in "$@"; do
     if [[ "$1" = "--apps" || "$1" = "-apps" ]]; then
       continue
     fi
       appslist+="-t $arg "
   done
   appslist=$(echo "$appslist" | sed 's/ $//')
   ansible-playbook -i inventories/ANE/inventory nas.yml -b -K $appslist
   exit
fi

if [[ "$1" = "--enabled" || "$1" = "-enabled" ]]; then
     echo "ANE enabled apps:"
     cat inventories/ANE/group_vars/nas.yml |grep 'enabled: true'
     exit
fi

# git force pull
# DO NOT USE! - for dev use only
if [[ "$1" = "--gitforcepull" || "$1" = "-gitforcepull" ]]; then
    git fetch --all
    git reset --hard origin/main
    exit
fi

if [[ "$1" = "--help" || "$1" = "-help" ]]; then
   help
fi
# Install ANE
if [[ "$1" = "--install" || "$1" = "-install" ]]; then
    if [ -d "inventories/ANE" ]; then
       echo "  ** WARNING: inventories/ANE exists!"
       echo "  ** \"rm inventories/ANE -R\" first if you really wish to reset."
       exit
    fi
    cp -rfp inventories/sample inventories/ANE
    echo "  ** Time to configure!"
    echo "  ** \"./ane.sh --inventory\" to edit your inventory file"
    echo "  ** \"./ane.sh --settings\" to edit your settings/overrides file"
    exit
fi

# Edit inventory file
if [[ "$1" = "--inventory" || "$1" = "-inventory" ]]; then
    nano inventories/ANE/inventory
    exit
fi

# git check commits
if [[ "$1" = "--outdated" || "$1" = "-outdated" || "$1" = "--updates" || "$1" = "-updates" ]]; then
#TDL: add --updates
    git fetch --quiet
    BEHIND=$(git rev-list --count HEAD..@{u})
    echo "  ** Your ANE installation is $BEHIND git commits behind."
    if [ $BEHIND -gt 1 ]; then
       echo "  ** \"./ane.sh --update\" or \"git pull\" to update"
    fi
    exit
fi

# reset shared file permissions
if [[ "$1" = "permissions" || "$1" = "-permissions" ]]; then
    ansible-playbook -i inventories/ANE/inventory permission_data.yml -b -K
    exit
fi

# prune docker stuff to save space
if [[ "$1" = "--prune" || "$1" = "-prune" ]]; then
    echo "  ** Pruning images..."
    docker image prune -f
    echo "  ** Pruning volumes..."
    docker volume prune -f
    exit
fi

# install ANE requirements
if [[ "$1" = "--requirements" || "$1" = "-requirements" ]]; then
    ansible-galaxy install -r requirements.yml
    exit
fi

# Run ANE full playbook
if [[ "$1" = "--run" || "$1" = "-run" ]]; then
    ansible-playbook -i inventories/ANE/inventory nas.yml -b -K $2 $3 $4 $5 $6 $7 $8 $9 ${10}
    exit
fi

# edit ANE settings/variables
if [[ "$1" = "--settings" || "$1" = "-settings" ]]; then
    nano inventories/ANE/group_vars/nas.yml
    exit
fi

# update ANE files
if [[ "$1" = "--update" || "$1" = "-update" ]]; then
    git pull
    exit
fi

# show help for all bad arguments
echo "  ** Ansible-NAS-Enhanced (ANE) unrecognized switch."
echo "  ** Run \"./ane.sh --help\" for help :-)"
