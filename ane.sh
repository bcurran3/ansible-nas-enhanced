#!/bin/bash
# Ansible-NAS-Enhanced helper script

: "${ANE_EDITOR:="nano"}"
: "${ANE_ALWAYS_CHECK_BEHIND:=false}"
: "${ANE_ALWAYS_ENABLE_DOCKFLARE:=false}"
: "${ANE_ALWAYS_ENABLE_TRAEFIK:=false}"
: "${ANE_ALWAYS_PRUNE:=false}"
: "${ANE_ALWAYS_UPGRADE:=false}"
: "${ANE_DISABLE_ALSO_REMOVES:=false}"
: "${ANE_DISABLE_ALSO_STOPS:=false}"
: "${ANE_ENABLE_ALSO_STARTS:=false}"
: "${ANE_BECOME_PASSWORD:=""}"

# Configure Ansible Become Flags (Sudo)
if [[ -n "$ANE_BECOME_PASSWORD" ]]; then
    BECOME_FLAGS=(-b --extra-vars "ansible_become_pass=$ANE_BECOME_PASSWORD")
else
    BECOME_FLAGS=(-b -K)
fi
if [[ -n "$ANE_BECOME_PASSWORD" ]]; then
    MASKED_PASS="********"
else
    MASKED_PASS="NOT SET"
fi

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
    echo "  --copytoplugins <app_name> <app_name> <app_name>"
    echo "      Copy app(s) to plugins directory"
    echo "  --disable <app_name> <app_name> <app_name>"
    echo "      Disable app(s)."
    echo "  --down, --stop <app_name> <app_name> <app_name>"
    echo "      Stop app(s)."
    echo "  --enable <app_name> <app_name> <app_name>"
    echo "      Enable app(s)."
    echo "  --enabled, --installed"
    echo "      List ANE enabled apps."
    echo "  --autoheal <app_name> <app_name> <app_name>"
    echo "      Enable autoheal for specific app(s)."
    echo "  --dockflare <app_name> <app_name> <app_name>"
    echo "      Enable Dockflare integration for specific app(s)."
    echo "  --repliqate <app_name> <app_name> <app_name>"
    echo "      Enable Repliqate backups for specific app(s)."
    echo "  --tinyauth <app_name> <app_name> <app_name>"
    echo "      Enable TinyAuth protection for specific app(s)."
    echo "  --traefik <app_name> <app_name> <app_name>"
    echo "      Enable traefik for specific app(s)."
    echo "  --watchtower <app_name> <app_name> <app_name>"
    echo "      Enable Watchtower updates for specific app(s)."
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
    echo "  --fastrun"
    echo "      Update enabled apps"
    echo ""
    exit
}

# ANE Pro Tips menu
function display_protips {
    echo "Ansible-NAS-Enhanced (ANE) Pro Tips:"
    echo "  export ANE_EDITOR=\"editorname\""
    echo "    -- set a different default text editor for ane.sh; i.e. vi, vim, msedit"
    echo "  export ANE_ALWAYS_CHECK_BEHIND=\"true\""
    echo "    -- always check if ANE is up-to-date"
    echo "  export ANE_ALWAYS_ENABLE_DOCKFLARE=\"true\""
    echo "    -- always enable Dockflare with app"
    echo "  export ANE_ALWAYS_ENABLE_TRAEFIK=\"true\""
    echo "    -- always enable Traefik with app"
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
    echo "  export ANE_BECOME_PASSWORD=\"yoursudopassword\""
    echo "    -- automate sudo prompts (use with caution!)"
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

function copy_to_plugins {
    if [[ -z "$2" ]]; then echo "  ** ERROR: Specify role name(s) to copy."; exit 1; fi
    if [[ ! -d "plugins" ]]; then
        mkdir "plugins"
        echo "  ++ DIR : plugins directory created."
    fi
    shift 
    for app in "$@"; do
        if [[ -d "roles/$app" ]]; then
            SRC="roles/$app"
        elif [[ -d "roles/WIP_$app" ]]; then
            SRC="roles/WIP_$app"
        else
            echo "  == ROLE: $app not found in roles/ directory."
            continue
        fi
        TARGET_DIR="plugins/$(basename "$SRC")"
        if [[ -d "$TARGET_DIR" ]]; then
            echo "  == ROLE: $(basename "$SRC") already exists in plugins/."
        else
            cp -r "$SRC" "plugins/"
            echo "  ++ ROLE: $(basename "$SRC") copied to plugins/ successfully."
        fi
    done
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
        ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}" -t "$CLEAN_TAGS"
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
        ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}" -t "${TAGS_TO_REMOVE%,}"
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
        ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}" -t "${TAGS_TO_RUN%,}"
    else
        echo "  ** All apps enabled in $FILE. Run ANE full playbook to deploy."
    fi
}

function enable_app {
    [[ "$1" == -* ]] && shift
    APPSLIST="./nas.yml"
    FILE="inventories/ANE/group_vars/nas.yml"
    TAGS_TO_RUN=""
    RESOLVED_APPS=""

    # 1. Wildcard Resolution
    for arg in "$@"; do
        if [[ "$arg" == *"*"* ]]; then
            MATCHES=$(find roles/ -maxdepth 1 -type d -name "$arg" ! -name "template" ! -name "WIP_*" ! -name ".*" | sed 's|roles/||' | sort)
            [[ -n "$MATCHES" ]] && RESOLVED_APPS+="$MATCHES "
        else
            RESOLVED_APPS+="$arg "
        fi
    done

    for app in $RESOLVED_APPS; do
        app_clean="${app//-/_}"
        
        # We use flexible regex patterns to find the lines regardless of spaces
        ENABLED_PAT="^[[:space:]]*${app_clean}_enabled:[[:space:]]*true"
        DISABLED_PAT="^[[:space:]]*${app_clean}_enabled:[[:space:]]*false"
        
        # Check if already enabled
        if grep -qE "$ENABLED_PAT" "$FILE"; then
            echo "  ** ${app} is already enabled."
        
        # Check if disabled and swap it
        elif grep -qE "$DISABLED_PAT" "$FILE"; then
            # The 's' command now looks for the pattern anywhere on the line
            sed -i -E "s/(${app_clean}_enabled:)[[:space:]]*false/\1 true/" "$FILE"
            echo "  ** ${app} re-enabled."
            
            # Add Autoheal/Dockflare/Traefik if global flags are set
            if [[ "$ANE_ALWAYS_ENABLE_AUTOHEAL" == "true" ]] && ! grep -q "${app_clean}_autoheal_enabled" "$FILE"; then
                sed -i "/${app_clean}_enabled: true/a ${app_clean}_autoheal_enabled: true" "$FILE"
                echo "  ** Autoheal enabled for ${app}."
            fi
            if [[ "$ANE_ALWAYS_ENABLE_DOCKFLARE" == "true" ]] && ! grep -q "${app_clean}_dockflare_enabled" "$FILE"; then
                sed -i "/${app_clean}_enabled: true/a ${app_clean}_dockflare_enabled: true" "$FILE"
                echo "  ** Dockflare enabled for ${app}."
            fi
            if [[ "$ANE_ALWAYS_ENABLE_TRAEFIK" == "true" ]] && ! grep -q "${app_clean}_traefik_enabled" "$FILE"; then
                sed -i "/${app_clean}_enabled: true/a ${app_clean}_traefik_enabled: true" "$FILE"
                echo "  ** Traefik enabled for ${app}."
            fi
            TAGS_TO_RUN+="${app},"
        
        # If not found at all, append to end of file
        else
            if grep -qE "role:[[:space:]]*${app}$" "$APPSLIST"; then
                # Ensure a newline before adding
                echo "" >> "$FILE"
                echo "### ${app}" >> "$FILE"
                echo "${app_clean}_enabled: true" >> "$FILE"
                
                [[ "$ANE_ALWAYS_ENABLE_DOCKFLARE" == "true" ]] && echo "${app_clean}_dockflare_enabled: true" >> "$FILE"
                [[ "$ANE_ALWAYS_ENABLE_TRAEFIK" == "true" ]] && echo "${app_clean}_traefik_enabled: true" >> "$FILE"
                
                echo "  ++ ${app} enabled (new entry)."
                TAGS_TO_RUN+="${app},"
            else
                echo "  ** ${app} not found in roles/ or nas.yml."
            fi
        fi
    done

    # Final Execution
    if [[ "$ANE_ENABLE_ALSO_STARTS" == "true" ]] && [[ -n "${TAGS_TO_RUN%,}" ]]; then
        echo "  ** Running playbook for: ${TAGS_TO_RUN%,}..."
        ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}" -t "${TAGS_TO_RUN%,}"
    fi
}

function enable_autoheal {
    [[ "$1" == -* ]] && shift
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_MARKER="${arg_clean}_enabled: true"
        AUTOHEAL_LINE="${arg_clean}_autoheal_enabled: true"
        if [ -f "$FILE" ] && grep -q "^$ENABLED_MARKER" "$FILE"; then
            if grep -q "^$AUTOHEAL_LINE" "$FILE"; then
                echo "  ** Autoheal is already enabled for ${arg}."
            else
                sed -i "/^$ENABLED_MARKER$/a $AUTOHEAL_LINE" "$FILE"
                echo "  ** Autoheal enabled for ${arg}."
            fi
        else
            echo "  ** Error: ${arg} must be enabled before adding autoheal, or app not found."
        fi
    done
}

function enable_dockflare {
    [[ "$1" == -* ]] && shift
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_MARKER="${arg_clean}_enabled: true"
        DOCKFLARE_LINE="${arg_clean}_dockflare_enabled: true"
        if [ -f "$FILE" ] && grep -q "^$ENABLED_MARKER" "$FILE"; then
            if grep -q "^$DOCKFLARE_LINE" "$FILE"; then
                echo "  ** Dockflare is already enabled for ${arg}."
            else
                sed -i "/^$ENABLED_MARKER$/a $DOCKFLARE_LINE" "$FILE"
                echo "  ** Dockflare enabled for ${arg}."
            fi
        else
            echo "  ** Error: ${arg} must be enabled before adding dockflare, or app not found."
        fi
    done
}

function enable_tinyauth {
    [[ "$1" == -* ]] && shift
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_MARKER="${arg_clean}_enabled: true"
        TINYAUTH_LINE="${arg_clean}_tinyauth_enabled: true"
        if [ -f "$FILE" ] && grep -q "^$ENABLED_MARKER" "$FILE"; then
            if grep -q "^$TINYAUTH_LINE" "$FILE"; then
                echo "  ** TinyAuth is already enabled for ${arg}."
            else
                sed -i "/^$ENABLED_MARKER$/a $TINYAUTH_LINE" "$FILE"
                echo "  ** TinyAuth enabled for ${arg}."
            fi
        else
            echo "  ** Error: ${arg} must be enabled before adding tinyauth, or app not found."
        fi
    done
}

function enable_traefik {
    [[ "$1" == -* ]] && shift
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_MARKER="${arg_clean}_enabled: true"
        TRAEFIK_LINE="${arg_clean}_traefik_enabled: true"
        HREF_LINE="${arg_clean}_homepage_href: \"https://{{ ${arg_clean}_hostname }}.{{ ansible_nas_domain }}\""
        
        if [ -f "$FILE" ] && grep -q "^$ENABLED_MARKER" "$FILE"; then
            if grep -q "^$TRAEFIK_LINE" "$FILE"; then
                echo "  ** Traefik is already enabled for ${arg}."
            else
                sed -i "/^$ENABLED_MARKER$/a $HREF_LINE" "$FILE"
                sed -i "/^$ENABLED_MARKER$/a $TRAEFIK_LINE" "$FILE"
                echo "  ** Traefik enabled for ${arg}."
            fi
        else
            echo "  ** Error: ${arg} must be enabled before adding traefik, or app not found."
        fi
    done
}

function enable_repliqate {
    [[ "$1" == -* ]] && shift
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_MARKER="${arg_clean}_enabled: true"
        REPLIQATE_LINE="${arg_clean}_repliqate_enabled: true"
        if [ -f "$FILE" ] && grep -q "^$ENABLED_MARKER" "$FILE"; then
            if grep -q "^$REPLIQATE_LINE" "$FILE"; then
                echo "  ** Repliqate is already enabled for ${arg}."
            else
                sed -i "/^$ENABLED_MARKER$/a $REPLIQATE_LINE" "$FILE"
                echo "  ** Repliqate enabled for ${arg}."
            fi
        else
            echo "  ** Error: ${arg} must be enabled before adding repliqate, or app not found."
        fi
    done
}

function enable_watchtower {
    [[ "$1" == -* ]] && shift
    FILE="inventories/ANE/group_vars/nas.yml"
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_MARKER="${arg_clean}_enabled: true"
        WATCHTOWER_LINE="${arg_clean}_watchtower_enabled: true"
        if [ -f "$FILE" ] && grep -q "^$ENABLED_MARKER" "$FILE"; then
            if grep -q "^$WATCHTOWER_LINE" "$FILE"; then
                echo "  ** Watchtower is already enabled for ${arg}."
            else
                sed -i "/^$ENABLED_MARKER$/a $WATCHTOWER_LINE" "$FILE"
                echo "  ** Watchtower enabled for ${arg}."
            fi
        else
            echo "  ** Error: ${arg} must be enabled before adding watchtower, or app not found."
        fi
    done
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

# update enabled apps
function fast_run {
    echo "  ** Fetching list of enabled apps for fast run..."
    ENABLED_LIST=$(grep 'enabled: true' inventories/ANE/group_vars/nas.yml | \
        grep -v -E "$ANE_EXCLUDES" | \
        sed 's/_enabled: true//;s/ //g;s/_/-/g' | \
        sort)
    if [[ -z "$ENABLED_LIST" ]]; then
        echo "  ** ERROR: No enabled apps found in settings."
        return 1
    fi
    echo "  ** Preparing to update the following apps (sorted):"
    echo "     $ENABLED_LIST" | xargs -r printf "    - %s\n"
    echo ""
    [[ "$ANE_ALWAYS_UPGRADE" == "true" ]] && upgrade
    run_playbook --up $(echo $ENABLED_LIST | xargs)
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

# run the full ANE playbook
function run_playbook {
    appslist=""
    shift
    for arg in "$@"; do
        appslist+=" -t $arg"
    done
    ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}" $appslist
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

function shell_help {
    echo "ANE Shell Commands:"
    echo "----------------------------------------------------------------"
    echo "  [ App Management ]"
    echo "  available             : List all available apps"
    echo "  up <app>              : Install/Update specific app(s)"
    echo "  down <app>            : Stop and Disable app(s)"
    echo "  enable <app>          : Enable app(s)"
    echo "  disable <app>         : Disable app(s)"
    echo "  fastrun               : Update enabled apps"
    echo "  remove <app>          : Stop, Disable, and Uninstall app(s)"
    echo "  run                   : Run full ANE playbook (all enabled apps)"
    echo "  stopall               : Stop ALL running containers"
    echo "  settings              : Edit group_vars/nas.yml"
    echo ""
    echo "  [ App Feature Toggles ]"
    echo "  autoheal <app>        : Enable Autoheal for app(s)"
    echo "  dockflare <app>       : Enable Dockflare for app(s)"
    echo "  repliqate <app>       : Enable Repliqate for app(s)"
    echo "  tinyauth <app>        : Enable TinyAuth for app(s)"
    echo "  traefik <app>         : Enable Traefik for app(s)"
    echo "  watchtower <app>      : Enable Watchtower for app(s)"
    echo ""
    echo "  [ System & Config ]"
    echo "  status                : Show running/enabled status"
    echo "  running               : Show raw docker running list (alpha sorted)"
    echo "  enabled               : List currently enabled apps"
    echo "  disabled              : List currently disabled apps"
    echo "  install               : Initialize/Reset configuration files"
    echo "  inventory             : Edit inventory file"
    echo "  permissions           : Reset shared file permissions"
    echo "  requirements          : Re-install ANE Ansible requirements"
    echo "  prune                 : Clean up docker images/volumes"
    echo "  behind                : Check if ANE is outdated"
    echo "  upgrade               : Pull latest ANE repo changes"
    echo ""
    echo "  [ Development ]"
    echo "  newapp <app>          : Create a new app role from template"
    echo "  copytoplugins <app>   : Copy role to plugins folder"
    echo "  enableall             : Enable ALL apps"
    echo "  disableall            : Disable ALL apps"
    echo ""
    echo "  [ General ]"
    echo "  help <app>            : Show documentation for specific app"
    echo "  protips               : Show environment variable options"
    echo "  exit                  : Exit ANE shell"
    echo "----------------------------------------------------------------"
}

function shell {
    clear
    echo -e "\033[34m"
    print_logo
    echo -e "\033[0m"

    while true; do 
        # using -n so the cursor stays on the same line as the prompt
        echo -ne "\033[34mANE SHELL> \033[0m" 
        read -r input
        
        # Extract command and arguments
        cmd="${input%% *}"
        args="${input#* }"
        
        # If input matches command exactly (no args), clear args
        if [[ "$cmd" == "$args" ]]; then args=""; fi

        case "$cmd" in 
            enable) 
                if [[ -z "$args" ]]; then enable_all_apps; else enable_app $args; fi
                ;;
            enableall|enableallapps)
                enable_all_apps
                ;;
            disable)
                if [[ -z "$args" ]]; then disable_all_apps; else disable_app $args; fi
                ;;
            disableall|disableallapps)
                disable_all_apps
                ;;
            up)
                [[ "$ANE_ALWAYS_UPGRADE" == "true" ]] && upgrade
                enable_app $args
                run_playbook --up $args
                ;;
            down|stop)
                stop_app $args
                disable_app $args
                ;;
            fastrun)
                fast_run
                ;;
            remove)
                stop_app $args
                disable_app $args
                run_playbook --remove $args
                ;;
            
            # --- Feature Toggles ---
            autoheal)
                enable_autoheal $args
                ;;
            dockflare)
                enable_dockflare $args
                ;;
            repliqate)
                enable_repliqate $args
                ;;
            tinyauth)
                enable_tinyauth $args
                ;;
            traefik)
                enable_traefik $args
                ;;
            watchtower)
                enable_watchtower $args
                ;;
            
            # --- Development ---
            newapp)
                create_new_app_placeholder $args
                ;;
            copytoplugins)
                copy_to_plugins $args
                ;;
            
            # --- System & Config ---
            install)
                if [ -d "inventories/ANE" ]; then
                    echo "  ** WARNING: inventories/ANE exists!"
                    echo "  ** Remove it first if you wish to reset."
                else
                    cp -rfp inventories/sample inventories/ANE
                    echo "  ** Configuration initialized."
                    echo "  ** Use 'inventory' or 'settings' to configure."
                fi
                ;;
            requirements)
                 ansible-galaxy install -r requirements.yml --force
                ;;
            run|update)
                 [[ "$ANE_ALWAYS_UPGRADE" == "true" ]] && upgrade
                 if [[ -z "$args" ]]; then
                    ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}"
                 else
                    run_playbook --run $args
                 fi
                 [[ "$ANE_ALWAYS_PRUNE" == "true" ]] && prune
                ;;
            upgrade|pull)
                upgrade
                ;;
            prune)
                prune
                ;;
            permissions)
                 ansible-playbook -i inventories/ANE/inventory permission_data.yml "${BECOME_FLAGS[@]}"
                ;;
            stopall)
                RUNNING=$(docker ps -q)
                if [[ -n "$RUNNING" ]]; then docker stop $RUNNING; else echo " ** No containers running."; fi
                ;;
            behind|outdated)
                check_behind
                ;;
            status)
                display_status
                ;;
            running)
                docker ps --format "table {{.Names}}\t{{.Status}}" | (sed -u 1q; sort)
                ;;
            protips)
                display_protips
                ;;
            available|roles)
                display_available_apps
                ;;
            enabled|installed)
                display_enabled_apps
                ;;
            disabled)
                display_disabled_apps
                ;;
            settings|vars)
                $ANE_EDITOR inventories/ANE/group_vars/nas.yml
                ;;
            inventory)
                $ANE_EDITOR inventories/ANE/inventory
                ;;
            
            # --- Help/Exit ---
            help|?)
                if [[ -n "$args" ]]; then
                     if [[ -f "./docs/applications/$args.md" ]]; then
                        cat "./docs/applications/$args.md"
                     else
                        echo " ** Docs for $args not found."
                     fi
                else
                    shell_help
                fi
                ;;
            exit|quit)
                echo "Exiting ANE-SHELL..."
                exit 0 
                ;;
            *)
                if [[ -n "$input" ]]; then 
                    echo -e "\033[0;31m  ** Unknown command: $cmd\033[0m"
                fi
                ;;
        esac 
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

# Copy role(s) to plugins directory
if [[ "$1" = "--copytoplugins" || "$1" = "-copytoplugins" ]]; then
    copy_to_plugins "$@"
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

# Enable Autoheal for ANE app(s)
if [[ "$1" == "--autoheal" || "$1" == "-autoheal" || "$1" == "--enableautoheal" || "$1" == "-enableautoheal" ]]; then
    if [ "$2" == "" ]; then
        echo "  ** You need to specify at least one app name."
        exit 1
    fi
    enable_autoheal "$@"
    exit
fi

# Enable Dockflare for ANE app(s)
if [[ "$1" == "--dockflare" || "$1" == "-dockflare" || "$1" == "--enabledockflare" || "$1" == "-enabledockflare" ]]; then
    if [ "$2" == "" ]; then
        echo "  ** You need to specify at least one app name."
        exit 1
    fi
    enable_dockflare "$@"
    exit
fi

# upate enabled apps
if [[ "$1" = "--fastrun" || "$1" = "-fastrun" ]]; then
    fast_run
    exit
fi

# Enable Repliqate for ANE app(s)
if [[ "$1" == "--repliqate" || "$1" == "-repliqate" || "$1" == "--enablerepliqate" || "$1" == "-enablerepliqate" ]]; then
    if [ "$2" == "" ]; then
        echo "  ** You need to specify at least one app name."
        exit 1
    fi
    enable_repliqate "$@"
    exit
fi

# Enable TinyAuth for ANE app(s)
if [[ "$1" == "--tinyauth" || "$1" == "-tinyauth" || "$1" == "--enabletinyauth" || "$1" == "-enabletinyauth" ]]; then
    if [ "$2" == "" ]; then
        echo "  ** You need to specify at least one app name."
        exit 1
    fi
    enable_tinyauth "$@"
    exit
fi

# Enable Traefik for ANE app(s)
if [[ "$1" == "--traefik" || "$1" == "-traefik" || "$1" == "--enabletraefik" || "$1" == "-enabletraefik" ]]; then
    if [ "$2" == "" ]; then
        echo "  ** You need to specify at least one app name."
        exit 1
    fi
    enable_traefik "$@"
    exit
fi

# Enable Watchtower for ANE app(s)
if [[ "$1" == "--watchtower" || "$1" == "-watchtower" || "$1" == "--enablewatchtower" || "$1" == "-enablewatchtower" ]]; then
    if [ "$2" == "" ]; then
        echo "  ** You need to specify at least one app name."
        exit 1
    fi
    enable_watchtower "$@"
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
    ansible-playbook -i inventories/ANE/inventory permission_data.yml "${BECOME_FLAGS[@]}"
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
    ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}" "${@:2}" && { [[ "$ANE_ALWAYS_PRUNE" == "true" ]] && prune; }
    exit
fi

# Edit ANE settings/overrides/variables
if [[ "$1" = "--settings" || "$1" = "-settings" || "$1" = "-s" || "$1" = "--overrides" || "$1" = "-overrides" || "$1" = "--vars" || "$1" = "-vars" || "$1" = "-v" ]]; then
    $ANE_EDITOR inventories/ANE/group_vars/nas.yml
    exit
fi

# ANE Shell
if [[ "$1" = "--shell" || "$1" = "-shell" ]]; then
    shell
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
