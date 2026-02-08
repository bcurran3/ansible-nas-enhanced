#!/bin/bash
# shell.sh Ansible-NAS-Enhanced helper script

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

# Filter out non-containers
ANE_EXCLUDES="#|WIP|_share_|_root_share|archive_app_data|nvidia_runtime|intel_igpu|amd_gpu|docker_compose|^ansible_nas|webmin|usermin|_(autoheal|dockflare|tinyauth|traefik|watchtower|repliqate)"

#####################################
########## begin functions ##########
#####################################

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
                    help_menu
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

function print_logo {
echo "      _    _   _ _____"
echo "     / \  | \ | | ____|"
echo "    / _ \ |  \| |  _|"
echo "   / ___ \| |\  | |___"
echo "  /_/   \_\_| \_|_____|"
echo ""
echo " Ansible-NAS-Enhanced Shell"
echo
}

function help_menu {
    echo "ANE Shell Commands:"
    echo "----------------------------------------------------------------"
    echo "  [ App Management ]"
    echo "  available             : List all available apps"
    echo "  up <app>              : Install/Update specific app(s)"
    echo "  down <app>            : Stop and Disable app(s)"
    echo "  enable <app>          : Enable app(s)"
    echo "  disable <app>         : Disable app(s)"
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

# Check # git commits ANE is behind
function check_behind {
    git fetch --quiet
    if [ $? -ne 0 ]; then echo "  ** ERROR fetching repo delta!"; return 1; fi
    BEHIND=$(git rev-list --count HEAD..@{u})
    echo "  ** Your ANE installation is $BEHIND git commits behind."
    if [ $BEHIND -gt 0 ]; then
       echo "  ** Type 'upgrade' to update."
    fi
}

function display_protips {
    echo "Ansible-NAS-Enhanced (ANE) Pro Tips:"
    echo "  export ANE_EDITOR=\"editorname\"            -- set default text editor"
    echo "  export ANE_BECOME_PASSWORD=\"password\"     -- set sudo password (skips prompt)"
    echo "  export ANE_ALWAYS_CHECK_BEHIND=\"true\"     -- always check updates"
    echo "  export ANE_ALWAYS_ENABLE_DOCKFLARE=\"true\" -- auto-enable Dockflare"
    echo "  export ANE_ALWAYS_ENABLE_TRAEFIK=\"true\"   -- auto-enable Traefik"
    echo "  export ANE_ALWAYS_PRUNE=\"true\"            -- always prune"
    echo "  export ANE_ALWAYS_UPGRADE=\"true\"          -- always upgrade ANE"
    echo "  export ANE_DISABLE_ALSO_REMOVES=\"true\"    -- disable app also removes it"
    echo "  export ANE_DISABLE_ALSO_STOPS=\"true\"      -- disable app also stops it"
    echo "  export ANE_ENABLE_ALSO_STARTS=\"true\"      -- enable app also starts it"
}

function copy_to_plugins {
    if [[ -z "$1" ]]; then echo "  ** ERROR: Specify role name(s) to copy."; return 1; fi
    if [[ ! -d "plugins" ]]; then
        mkdir "plugins"
        echo "  ++ DIR : plugins directory created."
    fi
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
        echo "  ** All apps disabled in config."
    fi
}

function disable_app {
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
        echo "  ** All apps enabled in $FILE. Run 'run' to deploy."
    fi
}

function enable_app {
    APPSLIST="./nas.yml"
    FILE="inventories/ANE/group_vars/nas.yml"
    TAGS_TO_RUN=""
    for arg in "$@"; do
        arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        arg_clean="${arg//-/_}"
        ENABLED_LINE="${arg_clean}_enabled: true"
        DISABLED_LINE="${arg_clean}_enabled: false"
        TRAEFIK_LINE="${arg_clean}_traefik_enabled: true"
        DOCKFLARE_LINE="${arg_clean}_dockflare_enabled: true"
        if [ -f "$FILE" ] && grep -q "^$ENABLED_LINE" "$FILE"; then
            echo "  ** ${arg} is already enabled."
        elif [ -f "$FILE" ] && grep -q "^$DISABLED_LINE" "$FILE"; then
            sed -i "s/^$DISABLED_LINE/$ENABLED_LINE/" "$FILE"
            echo "  ** ${arg} re-enabled."
            TAGS_TO_RUN+="${arg},"
        else
            if [ -f "$APPSLIST" ] && grep -qE "role: +${arg}$" "$APPSLIST"; then
                if ! grep -q "${arg_clean}_enabled" "$FILE"; then
                    echo -e "\n### ${arg}\n$ENABLED_LINE" >> "$FILE"
                    echo "  ** ${arg} enabled (new entry)."
                fi
                TAGS_TO_RUN+="${arg},"
            else
                echo "  ** ${arg} role not found in nas.yml."
            fi
        fi
    done
    if [[ "$ANE_ENABLE_ALSO_STARTS" == "true" ]] && [[ -n "${TAGS_TO_RUN%,}" ]]; then
        echo "  ** Installing enabled apps: ${TAGS_TO_RUN%,}..."
        ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}" -t "${TAGS_TO_RUN%,}"
    fi
}

function enable_autoheal {
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
            echo "  ** Error: ${arg} must be enabled before adding autoheal."
        fi
    done
}

function enable_dockflare {
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
            echo "  ** Error: ${arg} must be enabled before adding dockflare."
        fi
    done
}

function enable_tinyauth {
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
            echo "  ** Error: ${arg} must be enabled before adding tinyauth."
        fi
    done
}

function enable_traefik {
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
            echo "  ** Error: ${arg} must be enabled before adding traefik."
        fi
    done
}

function enable_repliqate {
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
            echo "  ** Error: ${arg} must be enabled before adding repliqate."
        fi
    done
}

function enable_watchtower {
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
            echo "  ** Error: ${arg} must be enabled before adding watchtower."
        fi
    done
}

function create_new_app_placeholder {
    if [[ -z "$1" ]]; then echo "  ** ERROR: Specify app name(s)."; return 1; fi
    if [[ ! -d "roles/template" ]]; then echo "  ** ERROR: roles/template directory not found."; return 1; fi
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

function prune {
    echo "  ** Pruning images..."
    docker image prune -f
    echo "  ** Pruning volumes..."
    docker volume prune -f
}

function upgrade {
    git pull
}

function run_playbook {
    appslist=""
    shift
    for arg in "$@"; do
        appslist+=" -t $arg"
    done
    ansible-playbook -i inventories/ANE/inventory nas.yml "${BECOME_FLAGS[@]}" $appslist
}

function stop_app {
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

# check for nano or other editor
$ANE_EDITOR --version > /dev/null
if [ $? -ne 0 ]; then
   echo "  ** ERROR:"
   echo "  ** $ANE_EDITOR not installed."
   exit 1
fi

if [[ "$ANE_ALWAYS_CHECK_BEHIND" == "true" ]]; then check_behind; fi

# Launch strictly into Shell Mode
shell