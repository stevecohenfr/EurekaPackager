#!/bin/bash

SCRIPT=`realpath -s $0`
SCRIPTPATH=`dirname $SCRIPT`
source "$SCRIPTPATH/lib/".common.sh

# generate vars from yaml file
create_variables config.yml


check_config () {

    if [[ ! " ${environnements_list[@]} " =~ " ${1} " ]]; then
        echo "'${1}' is not declared in 'environnements_list'."
        echo "Please provide it in 'conf.ym'l file."
        echo "Quitting..."
        exit 1
    fi

    config+=(parameters_project_name)
    config+=(parameters_project_target_root)
    config+=(parameters_delivery_folder_parent)
    config+=(parameters_delivery_folder_sources)
    config+=(parameters_delivery_suffix_format)
    config+=(environnements_${1}_name)
    config+=(environnements_${1}_short)
    config+=(environnements_${1}_suffix)
    config+=(environnements_${1}_deploy_user)
    config+=(environnements_${1}_deploy_host)
    config+=(environnements_${1}_deploy_type)
    config+=(environnements_${1}_deploy_target)

    for i in ${config[*]}; do
        if [ -z ${!i} ];then
            echo "'${i}' is unset or doesn't exist."
            echo "Please check its existence and provide it in 'conf.ym'l file."
            echo "Quitting..."
            exit 1
        fi;
    done
}


#######################################
############### USAGE ################
#######################################

function show_usage {
    echo -e "--------------------------------------------------"
    echo -e "This script help you to create a delivery file"
    echo -e "You can ONLY use this script with GIT"
    echo -e "Developed by Steve Cohen (stcoh) for SMILE company"
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

declare -A COMMITS

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

avail_shorts=''
for i in ${environnements_list[*]}; do
    env_short=environnements_${i}_short
    if [[ -n ${ENV} ]] && [ $ENV == ${!env_short} ]; then
        ENV=${i}
    fi
    avail_shorts+="${!env_short}|${i} / "
done;

while [[ ! " ${environnements_list[@]} " =~ " ${ENV} "  ]]  ;do
    read -p "Deploy environement (  ${avail_shorts::-2} ) : " ENV
    for i in ${environnements_list[*]}; do
        env_short=environnements_${i}_short
        if [[ -n ${ENV} ]] && [ $ENV == ${!env_short} ]; then
            ENV=${i}
        fi
    done;

    if [[ ! " ${environnements_list[@]} " =~ " ${ENV} "  ]] ; then
        printf "${Yellow}Invalid option. Please, choose between ${avail_shorts::-2}${Color_Off}\n"
    fi
done

check_config $ENV

source "$SCRIPTPATH/lib/".commit_manager.sh
source "$SCRIPTPATH/lib/".packager.sh
source "$SCRIPTPATH/lib/".deployer.sh

