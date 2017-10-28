#!/bin/bash

SCRIPT=`realpath -s $0`
SCRIPTPATH=`dirname $SCRIPT`
source "$SCRIPTPATH/lib/".common.sh


#######################################
############### USAGE ################
#######################################

function show_usage {
    echo -e "--------------------------------------------------"
    echo -e "This script help you to create a delivery file"
    echo -e "You can ONLY use this script with GIT and at Project root directory"
    echo -e "Developed by Steve Cohen (stcoh) and Marek Necesany (manec) for SMILE company"
    echo -e "--------------------------------------------------"
    echo
    echo -e "Usage: $0 [OPTION]"
    echo
    echo -e "Options:"
    echo -e "  --commit=<commit SHA1>\t\t use the commit sha1 to get files"
    echo -e "  --message=<commit message>\t\t search a commit using a part of the commit message"
    echo -e "  -e,  --env=<environment>\t\t\t Create package for specific environement"
    echo -e "  -u,  --upgrade\t\t\t self-upgrade the script"
    echo -e "  -h,  --help\t\t\t\t show this help"
    echo -e "  -v,  --version\t\t\t show the script version"
}



#######################################
############# CHECK ARGS ##############
#######################################
if [ "$#" -eq 0 ]; then
    show_usage
    exit
fi

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

# Checking provided configuration
source "$SCRIPTPATH/lib/".config_checker.sh

# Checking for committed files
printf "${Blue}Processing provided git information ...${Color_Off}\n"
source "$SCRIPTPATH/lib/.commit_manager.sh"

# Processing committed files
printf "${Blue}Copying files in delivery directory for ${!ENV_NAME^^} environment...${Color_Off}\n"
source "$SCRIPTPATH/lib/.packager.sh"



printf "${Blue}Deploying...${Color_Off}\n"
source "$SCRIPTPATH/lib/.deployer.sh"
