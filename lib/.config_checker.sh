#!/bin/bash

#
# Check if provided required configuration info for deploy
# $1 : environnement
#
check_config () {
    config+=(parameters_project_name)
    config+=(parameters_project_target_root)
    config+=(parameters_delivery_folder_parent)
    config+=(parameters_delivery_folder_sources)
    config+=(parameters_delivery_suffix_format)
    config+=(environments_${1}_name)
    config+=(environments_${1}_short)
    config+=(environments_${1}_suffix)
    config+=(environments_${1}_deploy_user)
    config+=(environments_${1}_deploy_host)
    config+=(environments_${1}_deploy_target)

    deploy_type=environments_${1}_deploy_type
    avail_types="pkg,package,src,sources"
    if  [[ ! $avail_types =~ (^|,)${!deploy_type}($|,) ]] ;then
        printf "\t${Red}Invalid  deploy type '${!deploy_type}' at '${deploy_type}' in config file.
        Please, provide it with 'pkg'/'package' for package sending or 'src'/'sources' for source deploy
        Quitting...${Color_Off}\n"
        exit 1
    fi

    for i in ${config[*]}; do
        if [ -z ${!i} ];then
            printf "\t${Red}'${i}' is unset or doesn't exist.
            Please check its existence and provide it in 'conf.ym'l file.
            Quitting...${Color_Off}\n"
            exit 1
        fi;
    done
}

declare -A avail_shorts

for i in ${environments_list[*]}; do
    env_short=environments_${i}_short
    [[ -z ${!env_short} ]] &&
        printf "\t${Yellow}The '${i}' env is listed but not (or not fully) configured.
        Please check its correct configuration in the 'conf.ym'l file.
        Otherwise, some features may function badly.
        ${Color_Off}" && ask_continue "Continue (y/n) ?" "no"

    avail_options+="${!env_short}|${i} / "
    avail_shorts[$i]=${!env_short}
    [[ -n ${ENV} ]] && [[ " ${avail_shorts[@]} " =~ " ${ENV} " ]] && ENV=${i}
done;

if [[ -n ${ENV} ]] && [[ ! " ${environments_list[@]} " =~ " ${ENV} "  ]] ; then
    printf "\t${Red}Shortcut or environment  '$ENV' not found.
    Please, check if it exists in 'conf.yml' file (in 'environments_list').
    Quitting...${Color_Off}\n"
    exit 1
fi

while [[ ! " ${environments_list[@]} " =~ " ${ENV} "  ]] ;do

    read -p "Deploy environement (  ${avail_options::-2} ) : " ENV
    for i in ${environments_list[*]}; do
        if [[ ${i} == ${ENV} ]] || [[ ${avail_shorts[$i]} == ${ENV} ]]; then
            ENV=${i}
        fi
    done;

    if [[ ! " ${environments_list[@]} " =~ " ${ENV} "  ]] ; then
        printf "${Yellow}Invalid option. Please, choose between ${avail_options::-2}${Color_Off}\n"
    fi
done

ENV_NAME=environments_${ENV}_name
printf "${Blue}Checking global and '${!ENV_NAME}' configuration...${Color_Off}\n"
check_config $ENV