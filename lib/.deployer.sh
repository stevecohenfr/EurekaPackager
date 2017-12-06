#!/bin/bash

printf "${Blue}Deploying...${Color_Off}\n"

user=environments_${ENV}_deploy_user
host=environments_${ENV}_deploy_host
pass=environments_${ENV}_deploy_pass
target=environments_${ENV}_deploy_target

# TODO : proxy support

proxy_user=environments_${ENV}_deploy_proxy_user
proxy_host=environments_${ENV}_deploy_proxy_host
proxy_pass=environments_${ENV}_deploy_proxy_pass

ssh_proxy="${!proxy_user}@${!proxy_host}"
ssh_host="${!user}@${!host}"
destination="${ssh_host}:${!target}"

case "${!type}" in
    "pkg"|"package" )
        DEPLOY_COMMAND="rsync -avz --human-readable $DELIVER_TOP_FOLDER/$DELIVER_ARCHIVE $destination"
        shift
        ;;
    "src"|"sources" )
        DEPLOY_COMMAND="rsync -avz --human-readable $DELIVER_FOLDER/ $destination"
        shift
        ;;
esac

question="Execution of "

#before scripts prepare
before_scripts=environments_${ENV}_deploy_commands_before_scripts

if [[ -n "${!before_scripts}" ]]; then
    bf_script="cd ${!target};"
    before_scripts=${before_scripts}[@]

    for i in "${!before_scripts}";do
        bf_script+="$i;"
    done

    printf "\t${Green}[before-script]${Color_Off}\t${bf_script} \n"
fi

printf "\t${Green}[sync-script]${Color_Off}\t${DEPLOY_COMMAND} \n"

#after scripts prepare
after_scripts=environments_${ENV}_deploy_commands_after_scripts
if [[ -n "${!after_scripts}" ]]; then
    af_script="cd ${!target};"
    after_scripts=${after_scripts}[@]

    for i in "${!after_scripts}";do
        af_script+="$i;"
    done
    printf "\t${Green}[after-script]${Color_Off}\t${af_script} \n"
fi

if [[ -n "$interactive" ]];then
    question+="Proceed ? (Y/n)"
    ask_continue "$question"
fi


# deployment
if [[ -n "${!pass}" ]]; then
    echo "ssh password: ${!pass}"
fi

if [[ -n "${!before_scripts}" ]]; then
    ssh $ssh_host $bf_script
fi

eval ${DEPLOY_COMMAND}

if [[ -n "${!after_scripts}" ]]; then
    ssh $ssh_host $af_script
fi