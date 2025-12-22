#!/bin/bash
# Ansible-NAS-Enhanced helper script

: "${ANE_EDITOR:="nano"}"
: "${ANE_ALWAYS_CHECK_BEHIND:=false}"
: "${ANE_ALWAYS_PRUNE:=false}"
: "${ANE_ALWAYS_UPGRADE:=false}"
: "${ANE_DISABLE_ALSO_STOPS:=false}"
: "${ANE_DISABLE_ALSO_REMOVES:=false}"
: "${ANE_ENABLE_ALSO_STARTS:=false}"

function print_logo {
echo "      _    _   _ _____"
echo "     / \  | \ | | ____|"
echo "    / _ \ |  \| |  _|"
echo "   / ___ \| |\  | |___"
echo "  /_/   \_\_| \_|_____|"
echo
echo "   Ansible-NAS-Enhanced"
echo
}

# ANE help menu
function help {
    echo "Ansible-NAS-Enhanced (ANE) Help:"
    echo "  --help"
    echo "      What you see now!"
    echo "  --app, --apps, -a, , --up, --tag, --tags, -t <app_name> <app_name> <app_name> <app_name>"
    echo "      Install or update apps by tag."
    echo "  --available"
    echo "      List ANE available apps."
    echo "  --behind, --outdated"
    echo "      Check if your ANE files are up-to-date."
    echo "  --disable <app_name>"
    echo "      Disable an app."
    echo "  --enable <app_name>"
    echo "      Enable an app."
    echo "  --enabled, --installed"
    echo "      List ANE enabled apps."
    echo "  --install"
    echo "      Install or reset ANE config files."
    echo "  --inventory"
    echo "      Edit ANE inventory file."
    echo "  --permissions"
    echo "      Reset permissions on all shared files."
    echo "  --protips"
    echo "      Display ANE \"Pro Tips\""
    echo "  --prune"
    echo "      Prune unused Docker images and volumes."
    echo "  --requirements"
    echo "      Install or re-install ANE requirements."
    echo "  --run, -r, --update, -u"
    echo "      Run ANE full playbook."
    echo "  --settings, -s"
    echo "      Edit ANE settings/overrides."
    echo "  --stop"
    echo "      Stop all running containers."
    echo "  --upgrade, --pull"
    echo "      Upgrade ANE files from repo"
    echo ""
    exit
}

# ANE Pro Tips menu
function protips {
    echo "Ansible-NAS-Enhanced (ANE) Pro Tips:"
    echo "  export ANE_EDITOR=\"editorname\""
    echo "    -- set a different default text editor for ane.sh; i.e. vi, vim, msedit"
    echo "  export ANE_ALWAYS_CHECK_BEHIND=\"true\""
    echo "    -- always check if ANE is up-to-date"
    echo "  export ANE_ALWAYS_PRUNE=\"true\""
    echo "    -- always prune docker images and volumes after running the full playbook"
    echo "  export ANE_ALWAYS_UPGRADE=\"true\""
    echo "    -- always pull the latest ANE files from GitHub before running the full playbook"
    echo "  export ANE_DISABLE_ALSO_STOPS=\"true\""
    echo "    -- stop app container when you disable it"
    echo "  export ANE_DISABLE_ALSO_REMOVES=\"true\""
    echo "    -- remove/delete app container when you disable it"
    echo "  export ANE_ENABLE_ALSO_STARTS=\"true\""
    echo "    -- install app when you enable it"
}

# Check git commits ANE is behind function
function check_behind {
    git fetch --quiet
    if [ $? -ne 0 ]; then echo "  ** ERROR fetching repo delta!"; exit 1; fi
    BEHIND=$(git rev-list --count HEAD..@{u})
    echo "  ** Your ANE installation is $BEHIND git commits behind."
    if [ $BEHIND -gt 0 ]; then
       echo "  ** \"./ane.sh --upgrade\" to update"
    fi
    #echo
}

# prune Docker images and volumes
function prune {
    echo "  ** Pruning images..."
    docker image prune -f
    echo "  ** Pruning volumes..."
    docker volume prune -f
}

# upgrade ANE files
function upgrade {
    git pull
}

# offer help when no switches provided
if [[ -z "$1" ]]; then
    print_logo  
    echo "  ** Run \"./ane.sh --help\" for help :-)"
    echo 
    exit 1
fi

# check for nano or other editor
$ANE_EDITOR --version > /dev/null
if [ $? -ne 0 ]; then
   echo "  ** ERROR:"
   echo "  ** $ANE_EDITOR not installed. \"sudo apt install $ANE_EDITOR\" to install."
   echo "  ** OR you can edit the script and change the ANE_EDITOR env var to your preferred editor."
   exit 1
fi

# Display ANE help menu
if [[ "$1" = "--help" || "$1" = "-help" || "$1" = "--?" || "$1" = "-?" ]]; then
   help
fi

# ANE Pro Tips menu
if [[ "$1" = "--protips" || "$1" = "-protips" ]]; then
    protips
    exit
fi

if $ANE_ALWAYS_CHECK_BEHIND; then check_behind; fi

# Install/update only specified ANE apps
if [[ "$1" = "--app" || "$1" = "--apps" || "$1" = "-a" || "$1" = "--up" || "$1" = "-up" || "$1" = "--tag" || "$1" = "--tags" || "$1" = "-t" ]]; then
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

# List ANE available apps (roles)
if [[ "$1" = "--available" || "$1" = "-available" || "$1" = "--roles" || "$1" = "-roles" ]]; then
     echo "ANE available apps:"
     cat nas.yml |grep 'role:'
     exit
fi

# Check git commits ANE is behind
if [[ "$1" = "--behind" || "$1" = "-behind" || "$1" = "--outdated" || "$1" = "-outdated" ]]; then
    if $ANE_ALWAYS_CHECK_BEHIND; then exit; fi
    check_behind
    exit
fi

# Disable ANE app
if [[ "$1" = "--disable" || "$1" = "-disable" ]]; then
    shift
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg_clean="${arg//-/_}"
        ENABLED_LINE="${arg_clean}_enabled: true"
        DISABLED_LINE="${arg_clean}_enabled: false"
        if [ -f "$FILE" ] && grep -xq "$ENABLED_LINE" "$FILE"; then
            sed -i "s/$ENABLED_LINE/$DISABLED_LINE/" "$FILE"
            if $ANE_DISABLE_ALSO_REMOVES; then
                    echo "  ** ${arg} disabled. Unstalling..."
                    ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t ${arg}
                else
                    echo "  ** ${arg} disabled. \"./ane.sh --app ${arg}\" to install."
                fi
            if $ANE_DISABLE_ALSO_STOPS; then
               docker stop "${arg}" > /dev/null 2>&1
               if [ $? -eq 0 ]; then
                  echo "  ** ${arg} stopped. ${arg} may have linked containers (i.e. DBs) still running."
               else 
                  echo "  ** ${arg} container not found or already stopped."
               fi
               docker stop "${arg}-db" > /dev/null 2>&1
               if [ $? -eq 0 ]; then
                  echo "  ** ${arg}-db stopped."
               fi
               docker stop "${arg}-redis" > /dev/null 2>&1
               if [ $? -eq 0 ]; then
                  echo "  ** ${arg}-redis stopped."
               fi
            fi
            if $ANE_DISABLE_ALSO_REMOVES; then
                appslist=""
                for arg in "$@"; do
                    appslist+=" -t $arg"
                done
                ansible-playbook -i inventories/ANE/inventory nas.yml -b -K $appslist
                exit
            fi
        elif [ -f "$FILE" ] && grep -xq "$DISABLED_LINE" "$FILE"; then
            echo "  ** ${arg} is already disabled."
        else
            echo "  ** ${arg} does not exist in $FILE."
            echo "  ** \"./ane.sh --enabled\" to view enabled apps."
        fi
    done
    exit
fi

# List ANE disabled apps
if [[ "$1" = "--disabled" || "$1" = "-disabled" ]]; then
     echo "ANE disabled apps:"
     cat inventories/ANE/group_vars/nas.yml | grep 'enabled: false'
     exit
fi

# Enable ANE app
if [[ "$1" = "--enable" || "$1" = "-enable" ]]; then
    shift
    APPSLIST="./nas.yml"
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg_clean="${arg//-/_}"
        ENABLED_LINE="${arg_clean}_enabled: true"
        DISABLED_LINE="${arg_clean}_enabled: false"
        VALID_APP="role: ${arg}"
        
        if [ -f "$FILE" ] && grep -xq "$ENABLED_LINE" "$FILE"; then
            echo "  ** ${arg} is already enabled."
        elif [ -f "$FILE" ] && grep -xq "$DISABLED_LINE" "$FILE"; then
            sed -i "s/$DISABLED_LINE/$ENABLED_LINE/" "$FILE"
            if $ANE_ENABLE_ALSO_STARTS; then
                echo "  ** ${arg} re-enabled. Installing..."
                ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t ${arg}
            else
                echo "  ** ${arg} re-enabled. \"./ane.sh --app ${arg}\" to install."
            fi
        else
            if [ -f "$APPSLIST" ] && grep -q "$VALID_APP" "$APPSLIST"; then
                echo -e "\n### ${arg}" >> "$FILE"
                echo "$ENABLED_LINE" >> "$FILE"
                if [ -f "$FILE" ] && grep -xq "traefik_enabled: true" "$FILE"; then
                    echo "${arg_clean}_available_externally: true" >> "$FILE"
                    echo "${arg_clean}_homepage_href: \"https://{{ ${arg_clean}_hostname }}.{{ ansible_nas_domain }}\"" >> "$FILE"
                fi
                if $ANE_ENABLE_ALSO_STARTS; then
                    echo "  ** ${arg} enabled. Installing..."
                    ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t ${arg}
                else
                    echo "  ** ${arg} enabled. \"./ane.sh --app ${arg}\" to install."
                fi
            else
                echo "  ** ${arg} not found in $APPSLIST. ${arg} is not a valid app."
                echo "  ** \"./ane.sh --available\" to view available apps."
            fi
        fi
    done
    exit
fi

# List ANE enabled apps
if [[ "$1" = "--enabled" || "$1" = "-enabled" || "$1" = "--installed" || "$1" = "-installed" ]]; then
     echo "ANE enabled apps:"
     cat inventories/ANE/group_vars/nas.yml | grep 'enabled: true'
     exit
fi

# git force pull
# DO NOT USE! - for dev use only - This will overwrite local changes with current git files
if [[ "$1" = "--gitforcepull" || "$1" = "-gitforcepull" ]]; then
    git fetch --all
    if [ $? -ne 0 ]; then echo "  ** ERROR fetching repo delta!"; exit 1; fi
    git reset --hard origin/main
    exit
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
    $ANE_EDITOR inventories/ANE/inventory
    exit
fi

# Reset ANE shared file permissions
if [[ "$1" = "--permissions" || "$1" = "-permissions" ]]; then
    ansible-playbook -i inventories/ANE/inventory permission_data.yml -b -K
    exit
fi

# Prune docker stuff to save space
if [[ "$1" = "--prune" || "$1" = "-prune" ]]; then
    prune
    exit
fi

# Install ANE requirements
if [[ "$1" = "--requirements" || "$1" = "-requirements" ]]; then
    ansible-galaxy install -r requirements.yml --force
    exit
fi

# Run ANE full playbook
if [[ "$1" = "--run" || "$1" = "-r" || "$1" = "--update" || "$1" = "-update" || "$1" = "-u" ]]; then
    if ($ANE_ALWAYS_UPGRADE); then upgrade; fi
    ansible-playbook -i inventories/ANE/inventory nas.yml -b -K $2 $3 $4 $5 $6 $7 $8 $9 ${10}
    if ($ANE_ALWAYS_PRUNE); then prune; fi
    exit
fi

# Edit ANE settings/variables
if [[ "$1" = "--settings" || "$1" = "-settings" || "$1" = "-s" || "$1" = "--vars" || "$1" = "-vars" || "$1" = "-v" ]]; then
    $ANE_EDITOR inventories/ANE/group_vars/nas.yml
    exit
fi

# Stop all Docker containers
if [[ "$1" = "--stop" || "$1" = "-stop" ]]; then
    docker stop $(docker ps -q)
    exit
fi

# Upgrade ANE files
if [[ "$1" = "--upgrade" || "$1" = "-upgrade" || "$1" = "--pull" || "$1" = "-pull" ]]; then
    upgrade
    exit
fi

# Show help for all bad arguments
echo "  ** Ansible-NAS-Enhanced (ANE) unrecognized switch."
echo "  ** Run \"./ane.sh --help\" for help :-)"
exit 1
