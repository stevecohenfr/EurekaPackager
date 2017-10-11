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
# Script Infos
SCRIPT_VERSION='0.6.1'
SCRIPT_NAME='EurekaPackager'

# CONFIG
source delivery_default.conf

NAME="${PROJECT_NAME}${PACKAGES_SUFFIX}"

DELIVER_TOP_FOLDER=$ALL_DELIVER_FOLDER/$NAME
FOLDER_SRC=$DELIVER_TOP_FOLDER"/src"
TMP_DIR=$DELIVER_TOP_FOLDER"/tmp"
TMP_TAR=$TMP_DIR"/tmp.tar.gz"

declare -a DELIVER_FOLDERS=($FOLDER_SRC"_integ" $FOLDER_SRC"_recette" $FOLDER_SRC"_preprod" $FOLDER_SRC"_prod")
declare -a ENVS_AFFIXES=("__INTEG__" "__RECETTE__" "__PREPROD__" "__PROD__")
declare -a ENVS=("INTEGRATION" "RECETTE" "PREPRODUCTION" "PRODUCTION")
declare -a DELIVER_ARCHIVES=("INTEG_$NAME" "RECETTE_$NAME" "PREPROD_$NAME" "PROD_$NAME")

#
# Asks if user wants to remove the local delivery prepared folder
#
remove_packages() {
    echo
    read -p "Remove package folder ?(Y/n) " -r
    if [[ $REPLY =~ ^[Yy]$ ]] && [ ! $REPLY = "" ];then
        rm -rf $DELIVER_TOP_FOLDER
    fi
}


#
# $1 : "Continue" Question string
# -> exits script if user doesn't want to continue
# -> returns "true" if user wants
#
ask_continue() {
    read -p "$1" -r
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [ ! $REPLY = "" ];then
        printf "${Red}Aborting.${Color_Off}\n"
        remove_packages
        exit 1
    else
        return 0
    fi
}