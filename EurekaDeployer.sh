#!/usr/bin/env bash

SCRIPT=`realpath -s $0`
SCRIPTPATH=`dirname $SCRIPT`

TMP_FILE="$SCRIPTPATH/.deploy_tmp"
source "$SCRIPTPATH/"delivery_default.conf
source "$SCRIPTPATH/".common.sh
source "$TMP_FILE"
DEPLOY_COMMAND=''

echo -e "--------------------------------------------------"
echo -e "This script helps you to deliver a tar package or sources,"
echo -e "previously processed with EurekaPackager.sh"
echo -e "It will guide you through steps needed for deploy (ssh info)"
echo -e "--------------------------------------------------"


#
# $1 : variable name
# $2 : same var's value
#
save_or_update_tmp() {
    if grep -q $1 "$TMP_FILE";then
        tmp=$(echo $2 | sed 's./.\\/.g')
        sed_param=s/${1}=.*/${1}=$tmp/
        sed -i "$sed_param" "$TMP_FILE"
    else
        echo "$1=$2" >> "$TMP_FILE"
    fi
}

#
# asks question if field not filled
#
blank_field() {
   if [[ $1 = "" ]];then
        question="No response... Continue ? (y/n)"
        ask_continue "$question"
    fi
}


#
# $1 : Question with default value
# $2 : Default value
#
insist_dialog() {
while [ -z $REPLY ] ;do
    read -p "$1" RESP
    REPLY=${RESP:-$2}
    blank_field $REPLY
done
echo -ne $REPLY
}

for i in "$@";do
    case $i in
        -dr|--dry--run)
        DEPLOY_COMMAND="--dry-run"
        echo -e "\nRunning in dry-run mode. \n"
        shift
        ;;
        -h|--help)
        echo
        echo -e "options : "
        echo -e "   -dr|--dry-run : run a simulation deploy"
        echo -e "   -h|--help :     show this dialog"
        echo -e "(Developed by Marek Necesany (manec) for SMILE company)"
        exit
        ;;
    esac
done


avail_envs="integ,recette,preprod,prod"
while [[ ! $avail_envs =~ (^|,)$DEPLOY_ENV($|,) ]] ;do
    read -p "Deploy environement ( i|integ / r|recette / pp|preprod / p|prod ) [$DEPLOY_ENV_DEFAULT] : " DEPLOY_ENV
    DEPLOY_ENV=${DEPLOY_ENV:-$DEPLOY_ENV_DEFAULT}

    case "$DEPLOY_ENV" in
    "i" | "integ")
        DEPLOY_ENV="integ"
        DEPLOY_PACKAGE="$DELIVER_TOP_FOLDER/${DELIVER_ARCHIVES[0]}.tar.gz"
        DEPLOY_SOURCES="${DELIVER_FOLDERS[0]}/"
        shift
        ;;
    "r" | "recette")
        DEPLOY_ENV="recette"
        DEPLOY_PACKAGE="$DELIVER_TOP_FOLDER/${DELIVER_ARCHIVES[1]}.tar.gz"
        DEPLOY_SOURCES="${DELIVER_FOLDERS[1]}/"
        shift
        ;;
    "pp" | "preprod")
        DEPLOY_ENV="preprod"
        DEPLOY_PACKAGE="$DELIVER_TOP_FOLDER/${DELIVER_ARCHIVES[2]}.tar.gz"
        DEPLOY_SOURCES="${DELIVER_FOLDERS[2]}/"
        shift
        ;;
    "p" | "prod")
        DEPLOY_ENV="prod"
        DEPLOY_PACKAGE="$DELIVER_TOP_FOLDER/${DELIVER_ARCHIVES[3]}.tar.gz"
        DEPLOY_SOURCES="${DELIVER_FOLDERS[3]}/"
        shift
        ;;
    *)
        printf "${Yellow}Invalid option. Please, choose between i|integ , r|recette , pp|preprod or p|prod${Color_Off}\n"
        ;;
    esac
done

if [ ! -d $DEPLOY_SOURCES ];then
    printf "${Red}$DEPLOY_SOURCES doesn't exist. Please, run EurekaPackager.sh before ${Color_Off}\n"
    exit 1
fi

if [ ! -f $DEPLOY_PACKAGE ]; then
    printf "${Red}$DEPLOY_PACKAGE doesn't exist. Please, run EurekaPackager.sh before ${Color_Off}\n"
    exit 1
fi

save_or_update_tmp DEPLOY_ENV_DEFAULT $DEPLOY_ENV

question="Deploy as user [$DEPLOY_USER_DEFAULT] : "
DEPLOY_USER=$(insist_dialog "$question" ${DEPLOY_USER_DEFAULT})
save_or_update_tmp DEPLOY_USER_DEFAULT ${DEPLOY_USER}

question="Deploy at host (server name or ip) [$DEPLOY_HOST_DEFAULT] : "
DEPLOY_HOST=$(insist_dialog "$question" ${DEPLOY_HOST_DEFAULT})
save_or_update_tmp DEPLOY_HOST_DEFAULT ${DEPLOY_HOST}

question="Deploy to path (ssh path:/path/where/put/package/) [$DEPLOY_PATH_DEFAULT] : "
DEPLOY_PATH=$(insist_dialog "$question" ${DEPLOY_PATH_DEFAULT})
save_or_update_tmp DEPLOY_PATH_DEFAULT ${DEPLOY_PATH}


avail_types="s,src,sources,p,pkg,package"
while [[ ! $avail_types =~ (^|,)$DEPLOY_TYPE($|,)  ]]  ;do
    read -p "Do you wish send directly the modified sources or the tar package only ? (s|src|sources / p|pkg|package) [$DEPLOY_TYPE_DEFAULT] : " DEPLOY_TYPE
    DEPLOY_TYPE=${DEPLOY_TYPE:-$DEPLOY_TYPE_DEFAULT}

    case "$DEPLOY_TYPE" in
    "s" | "src" | "sources" )
        DEPLOY_TYPE="sources"
        DEPLOY_COMMAND="rsync -avz --human-readable ${DEPLOY_COMMAND} ${DEPLOY_SOURCES} ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}"
        shift
        ;;
    "p" | "pkg" | "package" )
        DEPLOY_TYPE="package"
        DEPLOY_COMMAND="rsync -avz --human-readable ${DEPLOY_COMMAND} ${DEPLOY_PACKAGE} ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}"
        shift
        ;;
    *)
        printf "${Yellow}Invalid option. Please, choose between s|src|sources or p|pkg|package${Color_Off}\n"
        ;;
    esac
done
save_or_update_tmp DEPLOY_TYPE_DEFAULT ${DEPLOY_TYPE}

echo
echo -e "deploying at ${DEPLOY_HOST}:${DEPLOY_PATH}...\n"
eval ${DEPLOY_COMMAND}
