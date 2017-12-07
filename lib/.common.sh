#!/bin/env

#######################################
################ VARS #################
#######################################
# Regular Colors
Color_Off='\033[0m'       # Text Reset
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
Bold='\033[1m'            # Bold text
Underline='\033[4m'       # Underline text

# Script Infos
SCRIPT_VERSION='0.7'

#
# YML parsing
# $1 : .yml file
# $2 : var name - prefix
#
# credits: https://github.com/jasperes/bash-yaml
#
function parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"

    (
        sed -ne 's/\"/\\\"/g; s/\ #.*//g; s/\s*$//g;' \
            -e  "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |
        awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |
        sed 's/_=/+=/g'
    ) < "$yaml_file"
}

# Create vars from yml file ($1)
function create_variables() {
    local yaml_file="$1"
    eval "$(parse_yaml "$yaml_file")"
}

#
# Asks if user wants to remove the local delivery prepared folder
# - prereq.: global var must be initialized $DELIVER_TOP_FOLDER
#
remove_packages() {
    echo
    read -p "Remove package folder '$DELIVER_TOP_FOLDER' ?(Y/n) " -r
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ $REPLY = "" ]];then
        rm -rf $DELIVER_TOP_FOLDER
    fi
}


#
# $1 : "Continue" Question string
# -> exits script if user doesn't want to continue
# -> returns "true" if user wants
# $2 : avoid asking if want to remove created dir with sources & package
ask_continue() {
    read -p "$1" -r
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [ ! $REPLY = "" ];then
        printf "${Red}Aborting.${Color_Off}\n"
        if [ -z $2 ];then
            remove_packages
        fi
    exit 1
    else
        return 0
    fi
}


# Save var to tmp file (global var $TMP_FILE must be initialized)
# $1 : variable name
# $2 : same var's value
#
save_or_update_tmp() {
    if grep -q $1 "$TMP_FILE";then
        tmp=$(echo $2 | sed 's./.\\/.g')
        sed_param=s/${1}=.*/${1}=$tmp/
        sed -i "$sed_param" "$TMP_FILE"
    else
        echo "$1=$2" >> "$TMP_FILE"
    fi
}