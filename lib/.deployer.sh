#!/bin/bash

# TODO : proxy support


user=environments_${ENV}_deploy_user
host=environments_${ENV}_deploy_host
target=environments_${ENV}_deploy_target
proxy_user=environments_${ENV}_deploy_proxy_user
proxy_host=environments_${ENV}_deploy_proxy_host

ssh_proxy="${!proxy_user}@${!proxy_host}"
ssh_host="${!user}@${!host}"
destination="${ssh_host}:${!target}"

case "${!type}" in
    "pkg"|"package" )
        DEPLOY_COMMAND="rsync -avz --human-readable $DELIVER_TOP_FOLDER/$DELIVER_ARCHIVE $destination"
        shift
        ;;
    "src"|"sources" )
        DEPLOY_COMMAND="rsync -avz --human-readable $DELIVER_TOP_FOLDER/$DELIVER_FOLDER/ $destination"
        shift
        ;;
esac

#before scripts prepare
bf_script="cd ${!target};"
before_scripts=environments_${ENV}_deploy_commands_before_scripts
before_scripts=${before_scripts}[@]

for i in "${!before_scripts}";do
    bf_script+="$i;"
done

#after scripts prepare
af_script="cd ${!target};"
after_scripts=environments_${ENV}_deploy_commands_after_scripts
after_scripts=${after_scripts}[@]

for i in "${!after_scripts}";do
    af_script+="$i;"
done

question="
    Execution of '$bf_script' at '$ssh_host'
    then '${DEPLOY_COMMAND}'
    and finaly '$af_script' at '$ssh_host'.
    Proceed ? (Y/n) "
ask_continue "$question"


# deployment
ssh $ssh_host $bf_script
eval ${DEPLOY_COMMAND}
ssh $ssh_host $af_script