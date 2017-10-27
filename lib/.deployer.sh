#!/bin/bash


user=environnements_${ENV}_deploy_user
host=environnements_${ENV}_deploy_host
type=environnements_${ENV}_deploy_type
target=environnements_${ENV}_deploy_target

destination="${!user}@${!host}:${!target}"

case "${!type}" in
    "pkg"|"package" )
        printf "send $DELIVER_ARCHIVE to $destination \n"
        DEPLOY_COMMAND="rsync -avz --human-readable $DELIVER_ARCHIVE $destination"
        shift
        ;;
    "src"|"sources" )
        printf "send $DELIVER_FOLDER  contents to $destination \n"
        DEPLOY_COMMAND="rsync -avz --human-readable $DELIVER_FOLDER $destination"

        shift
        ;;
    *)
        printf "${Yellow}Invalid  deploy type option at '${type}' in config file.
        Please, provide 'package' or 'sources' ${Color_Off}\n"
        ;;
esac


#eval ${DEPLOY_COMMAND}
#TODO : post and pre deploy commands to exec on server