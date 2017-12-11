#!/bin/bash

printf "${Blue}Deploying...${Color_Off}\n"

case "${!type}" in
    "pkg"|"package" )
        delivery="$DELIVER_TOP_FOLDER/$DELIVER_ARCHIVE"
        ;;
    "src"|"sources" )
        delivery="$DELIVER_FOLDER/"
        ;;
esac

user=environments_${ENV}_deploy_user
host=environments_${ENV}_deploy_host
pass=environments_${ENV}_deploy_pass
target=environments_${ENV}_deploy_target

ssh_host="${!user}@${!host}"

proxy_user=environments_${ENV}_deploy_proxy_user
proxy_host=environments_${ENV}_deploy_proxy_host
proxy_pass=environments_${ENV}_deploy_proxy_pass

[ -n "${!proxy_user}" ] && [ -n "${!proxy_host}" ] && proxy_hop=0

if [ $proxy_hop ]; then
    ssh_proxy="${!proxy_user}@${!proxy_host}"
    destination=":${!target}"
    ssh_hop="-A $ssh_proxy ssh $ssh_host"
    DEPLOY_COMMAND="rsync -avzhe \"ssh $ssh_hop\" $delivery $destination"
else
    destination="${ssh_host}:${!target}"
    DEPLOY_COMMAND="rsync -avzh $delivery $destination"
fi

#before scripts prepare
before_scripts=environments_${ENV}_deploy_commands_before_scripts

if [[ -n "${!before_scripts}" ]]; then
    bf_script="cd ${!target};"
    before_scripts=${before_scripts}[@]

    for i in "${!before_scripts}";do
        bf_script+="$i;"
    done

    [ $proxy_hop ] \
        && ssh_bs_command="-A $ssh_proxy ssh $ssh_host \"$bf_script\"" \
        || ssh_bs_command="$ssh_host $bf_script"
fi

#after scripts prepare
after_scripts=environments_${ENV}_deploy_commands_after_scripts
if [[ -n "${!after_scripts}" ]]; then
    af_script="cd ${!target};"
    after_scripts=${after_scripts}[@]

    for i in "${!after_scripts}";do
        af_script+="$i;"
    done

    [ $proxy_hop ] \
        && ssh_as_command="-A $ssh_proxy ssh $ssh_host \"$af_script\"" \
        || ssh_as_command="$ssh_host $af_script"
fi

printf "${Blue}The following commands will be executed : ${Color_Off}\n"

[[ -n "${!before_scripts}" ]] && printf "\t${Green}[before-script (server side)]${Color_Off}\t${bf_script} \n"
printf "\t${Green}[sync-script]${Color_Off}\t${DEPLOY_COMMAND} \n"
[[ -n "${!after_scripts}" ]] && printf "\t${Green}[after-script (server side)]${Color_Off}\t${af_script} \n"

[[ ${interact} ]] && ask_continue "Proceed ? (Y/n) "

# deployment
[[ -n "${!proxy_pass}" ]] && echo "ssh proxy password: ${!proxy_pass}"
[[ -n "${!pass}" ]] && echo "ssh password: ${!pass}"

[[ -n "${!before_scripts}" ]] && ssh ${ssh_bs_command}
eval ${DEPLOY_COMMAND}
[[ -n "${!after_scripts}" ]] && ssh ${ssh_as_command}