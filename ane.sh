#!/bin/bash
# Ansible-NAS-Enhanced helper script

: "${ANE_EDITOR:="nano"}"
: "${ANE_ALWAYS_CHECK_BEHIND:=false}"
: "${ANE_ALWAYS_PRUNE:=false}"
: "${ANE_ALWAYS_UPGRADE:=false}"
: "${ANE_DISABLE_ALSO_STOPS:=false}"
: "${ANE_DISABLE_ALSO_REMOVES:=false}"
: "${ANE_ENABLE_ALSO_STARTS:=false}"

# Filter out non-containers
ANE_EXCLUDES="#|WIP|_share_|_root_share|archive_app_data|nvidia_runtime|intel_igpu|amd_gpu|docker_compose|^ansible_nas|webmin|usermin|_(autoheal|dockflare|tinyauth|traefik|watchtower|repliqate)"

#####################################
########## begin functions ##########
#####################################

# display ANE logo
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
    echo "      Stop app(s)."
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
    echo "  --remove <app_name> <app_name> <app_name>"
    echo "      Stop, disable, and remove ANE apps."
    echo "  --requirements"
    echo "      Install or re-install ANE requirements."
    echo "  --run, --update"
    echo "      Run ANE full playbook."
    echo "  --settings, --overrides"
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

# Check # git commits ANE is behind
function check_behind {
    git fetch --quiet
    if [ $? -ne 0 ]; then echo "  ** ERROR fetching repo delta!"; exit 1; fi
    BEHIND=$(git rev-list --count HEAD..@{u})
    echo "  ** Your ANE installation is $BEHIND git commits behind."
    if [ $BEHIND -gt 0 ]; then
       echo "  ** \"./ane.sh --upgrade\" to update"
    fi
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

# ANE Developer Stuff menu
function display_devstuff {
    echo "Ansible-NAS-Enhanced (ANE) Developer Stuff:"
    echo "  --enableallapps"
    echo "      Enable all apps."
    echo "  --disableallapps"
    echo "      Disable all apps."
    echo "  --newapp appname"
    echo "      Copies app template and autofills some variables."
}

function disable_all_apps {
    FILE="inventories/ANE/group_vars/nas.yml"
    echo -e "${RED}  ** WARNING: This will disable every application in your configuration.${NC}"
    read -p "  ** Are you sure you want to proceed? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "  ** Aborted."
        return 1
    fi
    ENABLED_APPS=$(grep 'enabled: true' "$FILE" | \
        grep -v -E "$ANE_EXCLUDES" | \
        sed 's/_enabled: true//;s/ //g')
    if [[ -z "$ENABLED_APPS" ]]; then
        echo "  ** No apps are currently enabled."
        return 0
    fi
    TAGS_TO_STOP=""
    for app in $ENABLED_APPS; do
        arg_clean="${app//-/_}"
        ENABLED_LINE="${arg_clean}_enabled: true"
        DISABLED_LINE="${arg_clean}_enabled: false"
        sed -i "s/^[[:space:]]*$ENABLED_LINE$/$DISABLED_LINE/" "$FILE"
        TAGS_TO_STOP+="${app},"
    done
    CLEAN_TAGS=${TAGS_TO_STOP%,}
    if [[ "$ANE_DISABLE_ALSO_STOPS" == "true" ]]; then
        echo "  ** Stopping containers for disabled apps..."
        IFS=',' read -r -a STOP_ARRAY <<< "$CLEAN_TAGS"
        stop_app "${STOP_ARRAY[@]}"
    fi
    if [[ "$ANE_DISABLE_ALSO_REMOVES" == "true" ]]; then
        echo "  ** Running playbook to uninstall apps..."
        ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t "$CLEAN_TAGS"
    else
        echo "  ** All apps disabled in config. Containers may still be running unless ANE_DISABLE_ALSO_STOPS is true."
    fi
}

function disable_app {
    [[ "$1" == -* ]] && shift
    FILE="inventories/ANE/group_vars/nas.yml"
    TAGS_TO_REMOVE=""
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_LINE="${arg_clean}_enabled: true"
        DISABLED_LINE="${arg_clean}_enabled: false"
        if [ -f "$FILE" ] && grep -q "^$ENABLED_LINE" "$FILE"; then
            sed -i "s/^$ENABLED_LINE$/$DISABLED_LINE/" "$FILE"
            if [[ "$ANE_DISABLE_ALSO_STOPS" == "true" ]]; then
                stop_app "$arg"
            fi
            echo "  ** ${arg} disabled."
            TAGS_TO_REMOVE+="${arg},"
        elif [ -f "$FILE" ] && grep -q "^$DISABLED_LINE" "$FILE"; then
            echo "  ** ${arg} is already disabled."
        else
            echo "  ** ${arg} does not exist in your settings/overrides file."
        fi
    done
    if [[ "$ANE_DISABLE_ALSO_REMOVES" == "true" && -n "$TAGS_TO_REMOVE" ]]; then
        echo "  ** Uninstalling disabled apps: ${TAGS_TO_REMOVE%,}..."
        ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t "${TAGS_TO_REMOVE%,}"
    fi
}

function display_available_apps {
    echo "  ** ANE available apps:"
    echo "--------------------------------------------------------"
    APP_LIST=$(grep 'role:' nas.yml | \
        grep -v -E "$ANE_EXCLUDES" | \
        awk -F': ' '{print $2}' | \
        sed 's/[#"].*//;s/ //g' | \
        sort)
    echo "$APP_LIST" | xargs -r printf "%-20s %-20s %-20s\n"
    TOTAL=$(echo "$APP_LIST" | grep -c -v '^$')
    echo "--------------------------------------------------------"
    echo "  ** Total Apps Available: $TOTAL"
}

function display_disabled_apps {
     echo "   ** ANE disabled apps:"
     echo "--------------------------------------------------------"
     DISABLED_LIST=$(grep 'enabled: false' inventories/ANE/group_vars/nas.yml | \
        grep -v -E "$ANE_EXCLUDES" | \
        sed 's/_enabled: false//;s/ //g;s/_/-/g' | \
        sort)
     
     if [[ -n "$DISABLED_LIST" ]]; then
        echo "$DISABLED_LIST" | xargs printf "%-20s %-20s %-20s\n"
        TOTAL=$(echo "$DISABLED_LIST" | grep -c -v '^$')
     else
        TOTAL=0
     fi
     echo "--------------------------------------------------------"
     echo "   ** Total Apps Disabled: $TOTAL"
}

function display_enabled_apps {
     echo "   ** ANE enabled apps:"
     echo "--------------------------------------------------------"
     ENABLED_LIST=$(grep 'enabled: true' inventories/ANE/group_vars/nas.yml | \
        grep -v -E "$ANE_EXCLUDES" | \
        sed 's/_enabled: true//;s/ //g;s/_/-/g' | \
        sort)
        
     if [[ -n "$ENABLED_LIST" ]]; then
        echo "$ENABLED_LIST" | xargs -r printf "%-20s %-20s %-20s\n"
        TOTAL=$(echo "$ENABLED_LIST" | wc -l)
     else
        TOTAL=0
     fi
     echo "--------------------------------------------------------"
     echo "   ** Total Apps Enabled: $TOTAL"
}

function display_status {
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    WHITE='\033[1;37m'
    GRAY='\033[0;90m'
    NC='\033[0m'

    echo "  ** ANE Applications Status:"
    echo "--------------------------------------------------------"
    printf "%-20s %-15s %-15s\n" "APP NAME" "CONFIGURED" "STATUS"
    echo "--------------------------------------------------------"
    RUNNING_INFO=$(docker ps --format '{{.Names}} {{.Image}}')
    ENABLED_APPS=$(grep 'enabled: true' inventories/ANE/group_vars/nas.yml | \
        grep -v -E "$ANE_EXCLUDES" | \
        sed 's/_enabled: true//;s/ //g' | \
        sort)
    for app in $ENABLED_APPS; do
        app_hyphen="${app//_/-}"
        if echo "$RUNNING_INFO" | grep -qiE "${app}|${app_hyphen}"; then
            STATE="${GREEN}RUNNING${NC}"
            CONF_COLOR="${WHITE}"
        else
            STATE="${RED}STOPPED${NC}"
            CONF_COLOR="${GRAY}"
        fi
        printf "${BLUE}%-20s${NC} ${CONF_COLOR}%-15s${NC} %-25b\n" "$app_hyphen" "ENABLED" "$STATE"
    done
    echo "--------------------------------------------------------"
}

function enable_all_apps {
    FILE="inventories/ANE/group_vars/nas.yml"
    APPSLIST="./nas.yml"
    TAGS_TO_RUN=""
    echo "  ** Preparing to enable all available ANE apps..."
    ALL_APPS=$(grep 'role:' "$APPSLIST" | \
        grep -v -E "$ANE_EXCLUDES" | \
        awk -F': ' '{print $2}' | \
        sed 's/[#"].*//;s/ //g')
    for arg in $ALL_APPS; do
        arg_clean="${arg//-/_}"
        ENABLED_LINE="${arg_clean}_enabled: true"
        DISABLED_LINE="${arg_clean}_enabled: false"
        if grep -q "^[[:space:]]*$DISABLED_LINE" "$FILE"; then
            sed -i "s/^[[:space:]]*$DISABLED_LINE$/$ENABLED_LINE/" "$FILE"
            TAGS_TO_RUN+="${arg},"
        elif ! grep -q "${arg_clean}_enabled" "$FILE"; then
            echo -e "\n### ${arg}\n$ENABLED_LINE" >> "$FILE"
            TAGS_TO_RUN+="${arg},"
        fi
    done
    if [[ "$ANE_ENABLE_ALSO_STARTS" == "true" && -n "$TAGS_TO_RUN" ]]; then
        echo "  ** Starting mass installation..."
        ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t "${TAGS_TO_RUN%,}"
    else
        echo "  ** All apps enabled in $FILE. Run ANE full playbook to deploy."
    fi
}

function enable_app {
    [[ "$1" == -* ]] && shift
    APPSLIST="./nas.yml"
    FILE="inventories/ANE/group_vars/nas.yml"
    TAGS_TO_RUN=""
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_LINE="${arg_clean}_enabled: true"
        DISABLED_LINE="${arg_clean}_enabled: false"
        if [ -f "$FILE" ] && grep -q "^$ENABLED_LINE" "$FILE"; then
            echo "  ** ${arg} is already enabled."
        elif [ -f "$FILE" ] && grep -q "^$DISABLED_LINE" "$FILE"; then
            sed -i "s/^$DISABLED_LINE$/$ENABLED_LINE/" "$FILE"
            echo "  ** ${arg} re-enabled."
            TAGS_TO_RUN+="${arg},"
        else
            if [ -f "$APPSLIST" ] && grep -qE "role: +${arg}$" "$APPSLIST"; then
                if ! grep -q "${arg_clean}_enabled" "$FILE"; then
                    echo -e "\n### ${arg}\n$ENABLED_LINE" >> "$FILE"
                    if grep -xq "traefik_enabled: true" "$FILE"; then
                        echo "${arg_clean}_traefik_enabled: true" >> "$FILE"
                        echo "${arg_clean}_homepage_href: \"https://{{ ${arg_clean}_hostname }}.{{ ansible_nas_domain }}\"" >> "$FILE"
                    fi
                    echo "  ** ${arg} enabled (new entry)."
                fi
                TAGS_TO_RUN+="${arg},"
            else
                echo "  ** ${arg} role not found in nas.yml."
                echo "  ** ./ane.sh --available to list available apps."
            fi
        fi
    done
    if [[ "$ANE_ENABLE_ALSO_STARTS" == "true" ]] && [[ -n "${TAGS_TO_RUN%,}" ]]; then
        echo "  ** Installing enabled apps: ${TAGS_TO_RUN%,}..."
        ansible-playbook -i inventories/ANE/inventory nas.yml -b -K -t "${TAGS_TO_RUN%,}"
    fi
}

function create_new_app_placeholder {
    if [[ -z "$1" ]]; then 
        echo "  ** ERROR: Specify app name(s)."
        return 1 
    fi
    if [[ ! -d "roles/template" ]]; then
        echo "  ** ERROR: roles/template directory not found."
        return 1
    fi
    DOC_SOURCE="docs/applications/template.md"
    for app in "$@"; do
        if [[ "$app" == -* ]]; then continue; fi
        NEW_APP_CLEAN="${app//-/_}"
        WIP_ROLE_NAME="WIP_${app}"
        WIP_ROLE_PATH="roles/${WIP_ROLE_NAME}"
        DOC_WIP_PATH="docs/applications/WIP_${app}.md"
        if [[ -d "roles/${app}" ]] || [[ -d "$WIP_ROLE_PATH" ]]; then
            echo "  == ROLE: ${app} already exists."
        else
            cp -r roles/template "$WIP_ROLE_PATH"
            find "$WIP_ROLE_PATH" -type f -exec sed -i "s@appname_@${NEW_APP_CLEAN}_@g" {} +
            find "$WIP_ROLE_PATH" -type f -exec sed -i "s@appname@${app}@g" {} +
            find "$WIP_ROLE_PATH" -name "*appname_*" | while read -r file; do 
                mv "$file" "${file//appname_/${NEW_APP_CLEAN}_}"
            done
            echo "  ++ ROLE: ${WIP_ROLE_NAME} successfully created."
        fi
        if [[ -f "$DOC_SOURCE" ]] && [[ ! -f "docs/applications/${app}.md" ]]; then
            cp "$DOC_SOURCE" "$DOC_WIP_PATH"
            sed -i "s@appname@${app}@g" "$DOC_WIP_PATH"
            echo "  ++ DOC : WIP_${app}.md successfully created."
        fi
    done
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

function run_playbook {
#    validate_app
    appslist=""
    shift
    for arg in "$@"; do
        appslist+=" -t $arg"
    done
    ansible-playbook -i inventories/ANE/inventory nas.yml -b -K $appslist
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

###################################
########## end functions ##########
###################################

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
    if [[ -n "./docs/applications/$2.md" ]] && [[ -f "./docs/applications/$2.md" ]]; then
        cat "./docs/applications/$2.md"
        exit
    fi
    if [[ -n "$2" ]]; then
        echo "  ** $2.md not found."
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

# ANE Dev Stuff menu
if [[ "$1" = "--devstuff" || "$1" = "-devstuff" || "$1" = "--devops" || "$1" = "-devops" ]]; then
    display_devstuff
    exit
fi

if [[ "$ANE_ALWAYS_CHECK_BEHIND" == "true" ]]; then check_behind; fi

# Install/update only specified ANE apps
if [[ "$1" = "--up" || "$1" = "-up" || "$1" = "--start" || "$1" = "-start" || "$1" = "--app" || "$1" = "--apps" || "$1" = "-a" || "$1" = "--tag" || "$1" = "--tags" || "$1" = "-t" ]]; then
     if [ "$2" = '' ]; then
        echo "  ** You need to specify at least one app name/tag."
        exit 1
     fi
    [[ "$ANE_ALWAYS_UPGRADE" == "true" ]] && upgrade
    enable_app "$@"
    run_playbook "$@"
    exit
fi

# List ANE available apps (roles)
if [[ "$1" = "--available" || "$1" = "-available" || "$1" = "--roles" || "$1" = "-roles" ]]; then
   display_available_apps
   exit
fi

# Check git commits ANE is behind
if [[ "$1" = "--behind" || "$1" = "-behind" || "$1" = "--outdated" || "$1" = "-outdated" ]]; then
    if [[ "$ANE_ALWAYS_CHECK_BEHIND" == "true" ]]; then exit; fi
    check_behind
    exit
fi

# Disable ANE app(s)
if [[ "$1" = "--disable" || "$1" = "-disable" ]]; then
    disable_app "$@"
    exit
fi

# Down (stop) ANE app(s)
if [[ "$1" = "--down" || "$1" = "-down" || "$1" = "--stop"|| "$1" = "-stop" ]]; then
    stop_app "$@"
    disable_app "$@"
    exit
fi

# List ANE disabled apps
if [[ "$1" = "--disabled" || "$1" = "-disabled" ]]; then
     display_disabled_apps
     exit
fi

# Enable ANE app(s)
if [[ "$1" = "--enable" || "$1" = "-enable" ]]; then
    enable_app "$@"
    exit
fi

# Enable all ANE apps
if [[ "$1" = "--enableallapps" || "$1" = "-enableallapps" ]]; then
    enable_all_apps
    exit
fi

# List ANE enabled apps
if [[ "$1" = "--enabled" || "$1" = "-enabled" || "$1" = "--installed" || "$1" = "-installed" ]]; then
    display_enabled_apps
    exit
fi

# Disable all ANE apps
if [[ "$1" = "--disableallapps" || "$1" = "-disableallapps" ]]; then
    disable_all_apps
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
if [[ "$1" = "--newapp" || "$1" = "-newapp" || "$1" = "--newapps" || "$1" = "-newapps" || "$1" = "--createapp" || "$1" = "-createapp" ]]; then
    create_new_app_placeholder "$@"
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

# Remove ANE app
if [[ "$1" = "--remove" || "$1" = "-remove" ]]; then
    stop_app "$@"
    disable_app "$@"
    run_playbook "$@"
    exit
fi

# Install ANE requirements
if [[ "$1" = "--requirements" || "$1" = "-requirements" ]]; then
    ansible-galaxy install -r requirements.yml --force
    exit
fi

# Run ANE full playbook
if [[ "$1" = "--run" || "$1" = "-r" || "$1" = "--update" || "$1" = "-update" || "$1" = "-u" ]]; then
    [[ "$ANE_ALWAYS_UPGRADE" == "true" ]] && upgrade
    ansible-playbook -i inventories/ANE/inventory nas.yml -b -K "${@:2}" && { [[ "$ANE_ALWAYS_PRUNE" == "true" ]] && prune; }
    exit
fi

# Edit ANE settings/overrides/variables
if [[ "$1" = "--settings" || "$1" = "-settings" || "$1" = "-s" || "$1" = "--overrides" || "$1" = "-overrides" || "$1" = "--vars" || "$1" = "-vars" || "$1" = "-v" ]]; then
    $ANE_EDITOR inventories/ANE/group_vars/nas.yml
    exit
fi

# Display ANE Applications Status
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
