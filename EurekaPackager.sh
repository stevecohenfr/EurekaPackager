#!/bin/bash

#
# Delivery system with GIT
#

SCRIPT=`realpath -s $0`
SCRIPTPATH=`dirname $SCRIPT`
TMP_FILE="$SCRIPTPATH/.deploy_tmp"
source "$SCRIPTPATH/lib/.common.sh"
#source "$TMP_FILE" # later usage : load saved tmp vars ( see lib/.common.sh#save_or_update_tmp() )

echo
printf "${Cyan}This script helps you to deliver a tar package or sources of changes in a project ${Color_Off}\n"
printf "${Cyan}It will ask you information to confirm what you provided in arguments and in the config file${Color_Off}\n"
echo

#############
### USAGE ###
#############

function show_usage {
    echo -e "--------------------------------------------------"
    echo -e "You can ONLY use this script with GIT and at Project root directory"
    echo -e "Developed by Steve Cohen (stcoh) and Marek Necesany (manec) for SMILE company"
    echo -e "--------------------------------------------------"
    echo
    echo -e "Usage: $0 [OPTION]"
    echo
    echo -e "Options:"
    echo -e "  -c, --commit=<commit SHA1>\t\t use the commit sha1 to get files"
    echo -e "  -m, --message=<commit message>\t\t search a commit using a part of the commit message"
    echo -e "  -e,  --env=<environment>\t\t\t Create package for specific environement"
    echo -e "  -u,  --upgrade\t\t\t self-upgrade the script"
    echo -e "  -h,  --help\t\t\t\t show this help"
    echo -e "  -v,  --version\t\t\t show the script version"
}



####################
###  CHECK ARGS  ###
####################
if [ "$#" -eq 0 ]; then
    show_usage
    exit
fi

###################
###  LOAD ARGS  ###
###################
for i in "$@";do
    case $i in
        -c=*|--commit=*)
        COMMIT=$(echo -e "${COMMIT}\n${i#*=}")
        shift
        ;;
        -m=*|--message=*)
        MESSAGE=$(echo -e "${MESSAGE}\n${i#*=}")
        shift
        ;;
        -e=*|--env=*)
        ENV="${i#*=}"
        shift
        ;;
        -u|--upgrade)
        self_upgrade
        ;;
        -h|--help)
        show_usage
        exit
        ;;
        -v|--version)
        echo "Script version: ${SCRIPT_VERSION}"
        exit
        ;;
        *)
        show_usage
        exit
        ;;
    esac
done

# generate vars from yaml file
create_variables config.yml

# Scripts self-update functions
source "$SCRIPTPATH/lib/.updater.sh"

# Checking provided configuration
source "$SCRIPTPATH/lib/.config_checker.sh"

# Checking for committed files
source "$SCRIPTPATH/lib/.commit_manager.sh"
question="Continue ? (Y/n) "
ask_continue "$question"

# Processing committed files
source "$SCRIPTPATH/lib/.packager.sh"
question="Proceed to deploy ? (Y/n) "
ask_continue "$question" "no"

source "$SCRIPTPATH/lib/.deployer.sh"
