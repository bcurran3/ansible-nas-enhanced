#!/bin/bash
# Ansible-NAS-Enhanced helper script

##      _    _   _ _____
##     / \  | \ | | ____|
##    / _ \ |  \| |  _|
##   / ___ \| |\  | |___
##  /_/   \_\_| \_|_____|
##
##  Ansible-NAS-Enhanced - https://github.com/bcurran3/ansible-nas-enhanced

EDITOR="nano"

function help {
# ANE help menu
    echo "Ansible-NAS-Enhanced (ANE) Help:"
    echo "  --help"
    echo "    What you see now!"
    echo "  --app, --apps <app_name> <app_name> <app_name> <app_name>"
    echo "    Install/Update apps by tag."
    echo "  --behind, --outdated, --updates"
    echo "    Check # of git commits behind your install of ANE is."
    echo "  --enabled"
    echo "    List ANE enabled apps."
    echo "  --install"
    echo "    Install ANE (first time or reset)."
    echo "  --inventory"
    echo "    Edit ANE inventory file."
    echo "  --permissions"
    echo "    Reset permissions on all shared files."
    echo "  --prune"
    echo "    Prune unused Docker images and volumes."
    echo "  --pull"
    echo "    Update ANE files from git"
    echo "  --requirements"
    echo "    Install/Re-install ANE requirements."
    echo "  --run, --update"
    echo "    Run ANE full playbook."
    echo "  --settings"
    echo "    Edit ANE settings/overrides."
    exit
}

# offer help when no switches provided
if [[ -z "$1" ]]; then
       echo "  ** Run \"./ane.sh --help\" for help :-)"
     exit 1
fi

# check for nano or other editor
$EDITOR --version > /dev/null
if [ $? -ne 0 ]; then
   echo "  ** ERROR:"
   echo "  ** $EDITOR not installed. \"sudo apt install $EDITOR\" to install."
   echo "  ** OR you can edit the script and change the EDITOR env var to your preferred editor."
   exit 1
fi

# Install/update only specified ANE apps
if [[ "$1" = "--app" || "$1" = "-app" ||  "$1" = "--apps" || "$1" = "-apps" ]]; then
     if [ "$2" = '' ]; then
        echo "  ** You need to specify at least one app name/tag."
        exit 1
     fi
    appslist=""
    shift
    for arg in "$@"; do
        appslist+=" -t $arg"
    done
   ansible-playbook -i inventories/ANE/inventory nas.yml -b -K $appslist
   exit
fi

# Check git commits ANE is behind
if [[ "$1" = "--behind" || "$1" = "-behind" || "$1" = "--outdated" || "$1" = "-outdated" || "$1" = "--updates" || "$1" = "-updates" ]]; then
    git fetch --quiet
    if [ $? -ne 0 ]; then echo "  ** ERROR fetching repo delta!"; exit 1; fi
    BEHIND=$(git rev-list --count HEAD..@{u})
    echo "  ** Your ANE installation is $BEHIND git commits behind."
    if [ $BEHIND -gt 0 ]; then
       echo "  ** \"./ane.sh --pull\" or \"git pull\" to update"
    fi
    exit
fi

# List ANE enabled apps
if [[ "$1" = "--enabled" || "$1" = "-enabled" ]]; then
     echo "ANE enabled apps:"
     cat inventories/ANE/group_vars/nas.yml |grep 'enabled: true'
     exit
fi

# git force pull
# DO NOT USE! - for dev use only
if [[ "$1" = "--gitforcepull" || "$1" = "-gitforcepull" ]]; then
    git fetch --all
    if [ $? -ne 0 ]; then echo "  ** ERROR fetching repo delta!"; exit 1; fi
    git reset --hard origin/main
    exit
fi

# Display ANE help menu
if [[ "$1" = "--help" || "$1" = "-help" || "$1" = "--?" || "$1" = "-?" ]]; then
   help
fi

# Install ANE (or reset)
if [[ "$1" = "--install" || "$1" = "-install" ]]; then
    if [ -d "inventories/ANE" ]; then
       echo "  ** WARNING: inventories/ANE exists!"
       echo "  ** \"rm inventories/ANE -R\" first if you really wish to reset."
       exit 1
    fi
    cp -rfp inventories/sample inventories/ANE
    echo "  ** Time to configure!"
    echo "  ** \"./ane.sh --inventory\" to edit your inventory file"
    echo "  ** \"./ane.sh --settings\" to edit your settings/overrides file"
    exit
fi

# Edit ANE inventory file
if [[ "$1" = "--inventory" || "$1" = "-inventory" ]]; then
    $EDITOR inventories/ANE/inventory
    exit
fi

# Reset ANE shared file permissions
if [[ "$1" = "permissions" || "$1" = "-permissions" ]]; then
    ansible-playbook -i inventories/ANE/inventory permission_data.yml -b -K
    exit
fi

# Prune docker stuff to save space
if [[ "$1" = "--prune" || "$1" = "-prune" ]]; then
    echo "  ** Pruning images..."
    docker image prune -f
    echo "  ** Pruning volumes..."
    docker volume prune -f
    exit
fi

# Install ANE requirements
if [[ "$1" = "--requirements" || "$1" = "-requirements" ]]; then
    ansible-galaxy install -r requirements.yml --force
    exit
fi

# Run ANE full playbook
if [[ "$1" = "--run" || "$1" = "-run" || "$1" = "--update" || "$1" = "-update" ]]; then
    ansible-playbook -i inventories/ANE/inventory nas.yml -b -K $2 $3 $4 $5 $6 $7 $8 $9 ${10}
    exit
fi

# Edit ANE settings/variables
if [[ "$1" = "--settings" || "$1" = "-settings" ]]; then
    $EDITOR inventories/ANE/group_vars/nas.yml
    exit
fi

# Update ANE files
if [[ "$1" = "--pull" || "$1" = "-pull" ]]; then
    git pull
    exit
fi

# Show help for all bad arguments
echo "  ** Ansible-NAS-Enhanced (ANE) unrecognized switch."
echo "  ** Run \"./ane.sh --help\" for help :-)"
exit 1
