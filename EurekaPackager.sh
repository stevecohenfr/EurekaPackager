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
printf "${Cyan}If interactive mode set, it will ask you to confirm information you provided in arguments and in the config file${Color_Off}\n"
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
    echo -e "  -b,  --branch\t\t\t create package/delivery files from a branch. Current if none specified as follows '-b=word in branch name'"
    echo -e "  -u,  --upgrade\t\t\t self-upgrade the script"
    echo -e "  -i, --interact\t\t\t interaction mode : questions asked"
    echo -e "  -h,  --help\t\t\t\t show this help"
    echo -e "  -v,  --version\t\t\t show the script version"
    echo -e "  -vv,  --verbose\t\t\t show the script version"
    echo -e "  -p, --pack-only\t\t\t no deploy, package only"
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
        -b|--branch)
        BRANCH='\*'
        ;;
        -b=*|--branch=*)
        BRANCH=$(echo -e "${i#*=}")
        ;;
        -i|--interact)
        interact=0
        shift
        ;;
        -vv|--verbose)
        verbose=0
        shift
        ;;
        -p|--pack-only)
        pack_only=0
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

if [ ! -f "config.yml" ]; then
    printf "\t${Red}The configuration file 'config.yml' doesn't exist.
    Please, create and fulfill it.
    Quitting...${Color_Off}\n"
    exit 1
fi

# generate vars from yaml file
create_variables config.yml

# Scripts self-update functions
source "$SCRIPTPATH/lib/.updater.sh"

# Checking provided configuration
source "$SCRIPTPATH/lib/.config_checker.sh"

################################
# Processing provided git info #
################################
printf "${Blue}Processing provided git information ...${Color_Off}\n"

NAME="${parameters_project_name}${parameters_delivery_suffix_format}"

DELIVER_TOP_FOLDER="$parameters_delivery_folder_parent/$NAME"
FOLDER_SRC="$DELIVER_TOP_FOLDER/$parameters_delivery_folder_sources"
TMP_DIR="$DELIVER_TOP_FOLDER/tmp"
TMP_TAR="$TMP_DIR/tmp.tar.gz"

rm -rf $DELIVER_TOP_FOLDER 2> /dev/null

if [[ -z "$BRANCH" ]]; then
    source "$SCRIPTPATH/lib/.commit_manager.sh"
else
    source "$SCRIPTPATH/lib/.branch_manager.sh"
fi

# extract tmp archive in source dir
mkdir ${FOLDER_SRC} 2> /dev/null
 if [ ! "$parameters_project_target_root" == "." ]; then
    tar ixf $TMP_TAR -C ${FOLDER_SRC} --strip-components=1 "${parameters_project_target_root}"
else
    tar ixf $TMP_TAR -C ${FOLDER_SRC}
fi

printf "${Blue}File list :${Color_Off}\n"
echo "-----------------------------------------------------------------"
tar itzf $TMP_TAR | grep -v '\/$' | sort -u
echo "-----------------------------------------------------------------"
printf "${Green}Files are ready for the packages in $FOLDER_SRC${Color_Off}\n"

rm -rf $TMP_DIR 2> /dev/null

########################################
# Packing/processing checked git files #
########################################
[[ $interact ]] && ask_continue "Continue ? (Y/n) "
source "$SCRIPTPATH/lib/.packager.sh"

#######################
# deploying git files #
#######################
if [ ! $pack_only ];then
    [[ $interact ]] && ask_continue "Proceed to deploy ? (Y/n) " "no"
    source "$SCRIPTPATH/lib/.deployer.sh"
fi