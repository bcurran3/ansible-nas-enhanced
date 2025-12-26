#!/bin/bash
# Ansible-NAS-Enhanced helper script

: "${ANE_EDITOR:="nano"}"
: "${ANE_ALWAYS_CHECK_BEHIND:=false}"
: "${ANE_ALWAYS_PRUNE:=false}"
: "${ANE_ALWAYS_UPGRADE:=false}"
: "${ANE_DISABLE_ALSO_STOPS:=false}"
: "${ANE_DISABLE_ALSO_REMOVES:=false}"
: "${ANE_ENABLE_ALSO_STARTS:=false}"

: "${ANE_ENABLE_ALSO_STARTS:=false}"

# Global exclusion list for app displays
# Filter out non-containers
ANE_EXCLUDES="#|_share_|_root_share|archive_app_data|nvidia_runtime|intel_igpu|amd_gpu|docker_compose|^ansible_nas|webmin|usermin"

########## begin functions ##########

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
    echo "  --available"
    echo "      List ANE available apps."
    echo "  --behind, --outdated"
    echo "      Check if your ANE files are up-to-date."
    echo "  --disable <app_name> <app_name> <app_name>"
    echo "      Disable app(s)."
    echo "  --down, --stop <app_name> <app_name> <app_name>"
    echo "      Disable and stop app(s)."
    echo "  --enable <app_name> <app_name> <app_name>"
    echo "      Enable app(s)."
    echo "  --enabled, --installed"
    echo "      List ANE enabled apps."
    echo "  --help <app_name>"
    echo "      Display <app_name> configuration info."
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
    echo "  --run, --update"
    echo "      Run ANE full playbook."
    echo "  --settings, -s, --overrides"
    echo "      Edit ANE settings/overrides."
    echo "  --stopall"
    echo "      Stop all running containers."
    echo "  --up, --start  <app_name> <app_name> <app_name>; aliases: --app, --apps, --tag, --tags, -t,"
    echo "      Install or update apps by tag."
    echo "  --upgrade, --pull"
    echo "      Upgrade ANE files from repo"
    echo ""
    exit
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

# ANE Pro Tips menu
function display_protips {
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

function display_devstuff {
    echo "Ansible-NAS-Enhanced (ANE) Developer Stuff:"
    echo "  --newapp"
    echo "      Copies app template and autofills some variables."
}

function disable_app {
    [[ "$1" == -* ]] && shift
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg_clean="${arg//-/_}"
        ENABLED_LINE="${arg_clean}_enabled: true"
        DISABLED_LINE="${arg_clean}_enabled: false"
        if [ -f "$FILE" ] && grep -xq "$ENABLED_LINE" "$FILE"; then
            sed -i "s/^$ENABLED_LINE/$DISABLED_LINE/" "$FILE"
            if [[ "$ANE_DISABLE_ALSO_STOPS" == "true" ]]; then
                stop_app "$arg"
            fi
            if [[ "$ANE_DISABLE_ALSO_REMOVES" == "true" ]]; then
                echo "  ** ${arg} disabled. Uninstalling..."
                ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t ${arg}
            else
                echo "  ** ${arg} disabled."
            fi
        elif [ -f "$FILE" ] && grep -xq "$DISABLED_LINE" "$FILE"; then
            echo "  ** ${arg} is already disabled."
        else
            echo "  ** ${arg} does not exist in $FILE."
        fi
    done
}

function display_available_apps {
    echo "  ** ANE available apps:"
    echo "--------------------------------------------------------"
    APP_LIST=$(grep 'role:' nas.yml | \
        grep -v -E '#|ansible-nas-|WIP' | \
        awk -F': ' '{print $2}' | \
        sed 's/[#"].*//;s/ //g' | \
        sort)
    echo "$APP_LIST" | xargs printf "%-20s %-20s %-20s\n"
    TOTAL=$(echo "$APP_LIST" | grep -c -v '^$')
    echo "--------------------------------------------------------"
    echo "  ** Total Apps Available: $TOTAL"
}

function display_disabled_apps {
     echo "  ** ANE disabled apps:"
     echo "--------------------------------------------------------"
     
     DISABLED_LIST=$(grep 'enabled: false' inventories/ANE/group_vars/nas.yml | \
        grep -v -E "$ANE_EXCLUDES" | \
        sed 's/_enabled: false//;s/ //g' | \
        sort)
     
     if [[ -n "$DISABLED_LIST" ]]; then
        echo "$DISABLED_LIST" | xargs printf "%-20s %-20s %-20s\n"
        TOTAL=$(echo "$DISABLED_LIST" | grep -c -v '^$')
     else
        TOTAL=0
     fi
     echo "--------------------------------------------------------"
     echo "  ** Total Apps Disabled: $TOTAL"
}

function display_enabled_apps {
     echo "  ** ANE enabled apps:"
     echo "--------------------------------------------------------"
     EXCLUSIONS="#|_share_|_root_share|archive_app_data|nvidia_runtime|intel_igpu|amd_gpu|docker_compose"
     ENABLED_LIST=$(grep 'enabled: true' inventories/ANE/group_vars/nas.yml | grep -v -E "$EXCLUSIONS" | sed 's/_enabled: true//;s/ //g' | sort)
     if [[ -n "$ENABLED_LIST" ]]; then
        echo "$ENABLED_LIST" | xargs printf "%-20s %-20s %-20s\n"
        TOTAL=$(echo "$ENABLED_LIST" | grep -c -v '^$')
     else
        TOTAL=0
     fi
     echo "--------------------------------------------------------"
     echo "  ** Total Apps Enabled: $TOTAL"
}

function display_status {
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'

    echo "  ** ANE Application Status:"
    echo "--------------------------------------------------------"
    printf "%-20s %-15s %-15s\n" "APP NAME" "CONFIGURED" "STATUS"
    echo "--------------------------------------------------------"
    
    # Use the global ANE_EXCLUDES
    ENABLED_APPS=$(grep 'enabled: true' inventories/ANE/group_vars/nas.yml | \
        grep -v -E "$ANE_EXCLUDES" | \
        sed 's/_enabled: true//;s/ //g')

    for app in $ENABLED_APPS; do
        if docker ps --filter "name=^/${app}" --filter "status=running" --format '{{.Names}}' | grep -q . ; then
            STATE="${GREEN}RUNNING${NC}"
        else
            STATE="${RED}STOPPED${NC}"
        fi
        printf "%-20s %-15s %-25b\n" "$app" "ENABLED" "$STATE"
    done
    echo "--------------------------------------------------------"
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

function stop_app {
    [[ "$1" == -* ]] && shift
    for arg in "$@"; do
        TARGETS=$(docker ps --filter "name=^/${arg}" --filter "status=running" --format "{{.Names}}" | paste -sd ", " -)
        if [[ -n "$TARGETS" ]]; then
            echo "  ** Stopping: $TARGETS"
            docker stop $(docker ps -q --filter "name=^/${arg}" --filter "status=running") > /dev/null
        else
            echo "  ** ${arg} is not currently running."
        fi
    done
}

########## end functions ##########

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

# ANE help
if [[ "$1" = "--help" || "$1" = "-help" || "$1" = "--?" || "$1" = "-?" ]]; then
    app_readme="./docs/applications/$2.md"
    if [[ -n "$2" ]] && [[ -f "$app_readme" ]]; then
        cat "$app_readme"
        exit
    fi
    if [[ -n "$2" ]]; then
        echo "  ** ERROR: $2.md not found."
        echo "  ** "./ane.sh --available" to view available apps."
        exit 1
    fi

    help
fi

# ANE Pro Tips menu
if [[ "$1" = "--protips" || "$1" = "-protips" ]]; then
    display_protips
    exit
fi

# ANE Pro Tips menu
if [[ "$1" = "--devstuff" || "$1" = "-devstuff" ]]; then
    display_devstuff
    exit
fi

if $ANE_ALWAYS_CHECK_BEHIND; then check_behind; fi

# Install/update only specified ANE apps
if [[ "$1" = "--up" || "$1" = "-up" || "$1" = "--start" || "$1" = "-start" || "$1" = "--app" || "$1" = "--apps" || "$1" = "-a" || "$1" = "--tag" || "$1" = "--tags" || "$1" = "-t" ]]; then
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
   display_available_apps
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
    disable_app "$@"
    exit
fi

# Down (stop) ANE app
if [[ "$1" = "--down" || "$1" = "-down" || "$1" = "-stop"|| "$1" = "-stop" ]]; then
    stop_app "$@"
    exit
fi

# List ANE disabled apps
if [[ "$1" = "--disabled" || "$1" = "-disabled" ]]; then
     display_disabled_apps
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
    display_enabled_apps
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

# Copy template for new app role development
if [[ "$1" = "--newapp" || "$1" = "-newapp" ]]; then
    if [[ -z "$2" ]]; then echo "  ** ERROR: Specify app name."; exit 1; fi
    if [[ ! -d "roles/template" ]]; then
        echo "  ** ERROR: 'roles/template' directory not found. Cannot create new app."
        exit 1
    fi
    NEW_APP_CLEAN="${2//-/_}"
    TARGET="roles/$2"
    if [[ -d "$TARGET" ]]; then echo "  ** ERROR: Role '$2' already exists."; exit 1; fi
    cp -r roles/template "$TARGET"
    find "$TARGET" -type f -exec sed -i "s/appname_/${NEW_APP_CLEAN}_/g" {} +
    find "$TARGET" -name "appname_*" | while read file; do 
        mv "$file" "${file//appname_/${NEW_APP_CLEAN}_}"
    done
    echo "  ** Role '$2' created successfully."
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
    ansible-playbook -i inventories/ANE/inventory nas.yml -b -K "${@:2}"
    if ($ANE_ALWAYS_PRUNE); then prune; fi
    exit
fi

# Edit ANE settings/variables
if [[ "$1" = "--settings" || "$1" = "-settings" || "$1" = "-s" || "$1" = "--overrides" || "$1" = "-overrides" || "$1" = "--vars" || "$1" = "-vars" || "$1" = "-v" ]]; then
    $ANE_EDITOR inventories/ANE/group_vars/nas.yml
    exit
fi

# Edit ANE settings/variables
if [[ "$1" = "--status" || "$1" = "-status" ]]; then
    display_status
    exit
fi

# Stop all Docker containers
if [[ "$1" = "--stopall" || "$1" = "-stopall" ]]; then
    RUNNING=$(docker ps -q)
    if [[ -n "$RUNNING" ]]; then
        docker stop $RUNNING
    else
        echo "  ** No containers are currently running."
    fi
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
