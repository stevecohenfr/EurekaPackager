#!/bin/bash
#
# Delivery system with GIT
#
# Created by Steve Cohen (stcoh)
# 12/04/2017
#

#######################################
################ VARS #################
#######################################
# Regular Colors
Color_Off='\033[0m'       # Text Reset
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
# Script Infos
SCRIPT_VERSION='0.6.1'
SCRIPT_NAME='EurekaPackager'


#######################################
############### UPDATER ###############
#######################################

function check_update {
    REMOTE_VERSION=`curl -sL https://rawgit.com/ReaperSoon/EurekaPackager/master/VERSION`

    if [[ "$SCRIPT_VERSION" < "$REMOTE_VERSION" ]]; then
	printf "${Yellow}Your script is deprecated (${SCRIPT_VERSION} < ${REMOTE_VERSION}). Please use -u or --upgrade${Color_Off}\n"
    fi
}

function self_upgrade {
    DIST_SCRIPT="https://rawgit.com/ReaperSoon/EurekaPackager/master/EurekaPackager.sh"

    # Download new version
    printf "${Green}Downloading latest version...${Color_Off}\n"
    if ! wget --quiet --output-document="$0.tmp" $DIST_SCRIPT ; then
	printf "${Red}Failed: Error while trying to wget new version!${Color_Off}\n"
	printf "${Red}File requested: ${DIST_SCRIPT}${Color_Off}\n"
	exit 1
    fi
    printf "${Green}Done.${Color_Off}\n"

    # Copy over modes from old version
    OCTAL_MODE=$(stat -c '%a' $0)
    if ! chmod $OCTAL_MODE "$0.tmp" ; then
	printf "${Red}Failed: Error while trying to set mode on $0.tmp.${Color_Off}\n"
	exit 1
    fi

    # Spawn update script
    cat > .updatescript.sh << EOF
#!/bin/bash
# Overwrite old file with new
if mv "$0.tmp" "$0"; then
  printf "${Green}Done. Upgrade complete.${Color_Off}\n"
  rm \$0
else
  printf "${Red}Failed!${Color_Off}\n"
fi
EOF

    printf "${Green}Upgrading script...${Color_Off}\n"
    exec /bin/bash .updatescript.sh  
}

check_update

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

COMMIT=''
TICKET=''
HELP=''
VERSION=''

for i in "$@"
do
case $i in
    --commit=*)
	COMMIT=${COMMIT}"\n"${i#*=}
	shift
    ;;
    --message=*)
	MESSAGE="${MESSAGE}\n${i#*=}"
	shift
    ;;
    -u|--upgrade)
	self_upgrade
    ;;
    -h|--help)
	HELP="help"
    ;;
    -v|--version)
	VERSION="version"
    ;;
    *)
    show_usage
    exit
    ;;
esac
done

if [[ ! ${HELP} == '' ]]; then
    show_usage
    exit
fi

if [[ ! ${VERSION} == '' ]]; then
    echo "Script version: ${SCRIPT_VERSION}"
    exit
fi

#######################################
############ SCRIPT LOGIC #############
#######################################

# CONFIG
ALL_DELIVER_FOLDER="/lxc/croix-rouge/var/www/livraisons"
EZ_ROOT="/lxc/croix-rouge/var/www/irfss/www"
TODAY=`date +"%Y%m%d"`
NAME="CRF_IRFSS_"$TODAY 

DELIVER_FOLDER=$ALL_DELIVER_FOLDER/$NAME
FOLDER_SRC=$DELIVER_FOLDER"/src"
FOLDER_SRC_INTEG=$FOLDER_SRC"_integ"
FOLDER_SRC_RECETTE=$FOLDER_SRC"_recette"
FOLDER_SRC_PREPROD=$FOLDER_SRC"_preprod"
FOLDER_SRC_PROD=$FOLDER_SRC"_prod"

echo "Starting archive script..."

mkdir -p $FOLDER_SRC

cd $EZ_ROOT

#If GIT message is provided, search git commit SHA1
if [[ ! ${MESSAGE} == '' ]] && [[ ${COMMIT} == '' ]]; then
    messages=$(echo -e ${MESSAGE}|sort|uniq)
    for mess in $messages; do
        printf "Searching commit SH1 using commit containing message ${Blue}${mess}${Color_Off}...\n"
        COMMIT_LINES=`git log --all --pretty=oneline --grep="${mess}"`

        # Commit found
        if [ ! "${COMMIT_LINES}" == '' ]; then
            printf "${Green}Commit(s) found !${Color_Off}\n"
            echo "-----------------------------------------------------------------"
            echo "${COMMIT_LINES}"
            echo "-----------------------------------------------------------------"
            read -p "Is it the commit(s) you want to deliver ?(Y/n) " -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]] && [ ! $REPLY = "" ] 
            then
                printf "${Red}Aborting.${Color_Off}\n"
                exit 1
            fi

            for COMMIT_LINE in "$COMMIT_LINES"; do
                commit=`echo "${COMMIT_LINE}" | awk '{print $1}'`
                COMMIT=${COMMIT}"\n"$commit
            done
        # Commit NOT found
        else
            printf "${Red}Sorry, commit not found.${Color_Off}\n"
            exit 1
        fi
    done
fi

COMMIT=$(echo -e $COMMIT|sort|uniq)

# Liste fichier modifié
for commit in $COMMIT
do
    filecommit=$(git show --oneline --name-only $commit | tail -n+2 | sed -e "s/www\///g")"\n"$filecommit
done

filecommit=$(echo -e $filecommit|sort|uniq)

printf "${Blue}Files list :${Color_Off}\n"
echo "-----------------------------------------------------------------"
for file in $filecommit; do
   echo $file
   cp --parents $file $FOLDER_SRC
done
echo "-----------------------------------------------------------------"

printf "${Green}Files are ready for the packages in $FOLDER_SRC${Color_Off}\n"
read -p "Continue ?(Y/n) " -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [ ! $REPLY = "" ] 
then
    printf "${Red}Aborting.${Color_Off}\n"
    exit 1
fi

printf "${Blue}Copying files in delivery directories${Color_Off}\n"

cp -R $FOLDER_SRC $FOLDER_SRC_INTEG
cp -R $FOLDER_SRC $FOLDER_SRC_RECETTE
cp -R $FOLDER_SRC $FOLDER_SRC_PREPROD
cp -R $FOLDER_SRC $FOLDER_SRC_PROD


printf "${Blue}Updating files depending on environments${Color_Off}\n"

#
# $1 : __ENV__ pattern
# $2 : file to modify
#
function update_env {
    echo "*** Updating $2 ***"
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ $line == *"$1"* ]]; then
            #Get normal key without __ENV__
            normal_key=`echo "${line/$1/}" | awk -F"=" '{print $1}'`
            l=0
            while IFS='' read -r line2 || [[ -n "$line2" ]]; do
                ((l++))
                if [[ $line2 == "${normal_key}="* ]]; then
                    #Remove curent line
                    echo "Removing LXC variable at line $l : ${line2}"
                    sed "${l}d" -i "$2"
                    break;
                fi
            done < "$2"
        fi
    done < $2
    #Remove all __ENV__ from lines
    sed -e "s/$1//g" -i "$2"
}  

#INTEGRATION
for file in `find $FOLDER_SRC_INTEG -type f`; do
        update_env "__INTEG__" $file
done

for file in `find $FOLDER_SRC_INTEG -name *__INTEG__*`; do
        rm `echo $file | sed s/__INTEG__//g`;
        mv $file `echo $file | sed s/__INTEG__//g`;
done

# RECETTE
for file in `find $FOLDER_SRC_RECETTE -type f`; do
        update_env "__RECETTE__" $file
done

for file in `find $FOLDER_SRC_RECETTE -name *__RECETTE__*`; do
        rm `echo $file | sed s/__RECETTE__//g`;
        mv $file `echo $file | sed s/__RECETTE__//g`;
done

# PREPROD
for file in `find $FOLDER_SRC_PREPROD -type f`; do
        update_env "__PREPROD__" $file
done

for file in `find $FOLDER_SRC_PREPROD -name *__PREPROD__*`; do
        rm `echo $file | sed s/__PREPROD__//g`;
        mv $file `echo $file | sed s/__PREPROD__//g`;
done

#PROD
for file in `find $FOLDER_SRC_PROD -type f`; do
        update_env "__PROD__" $file
done

for file in `find $FOLDER_SRC_PROD -name *__PROD__*`; do
        rm `echo $file | sed s/__PROD__//g`;
        mv $file `echo $file | sed s/__PROD__//g`;
done

printf "${Blue}Creating packages${Color_Off}\n"

printf "${Blue}INTEGRATION${Color_Off}\n"
cd $FOLDER_SRC_INTEG
tar -zcvf ../"INTEG_"$NAME.tar.gz *
cd -

printf "${Blue}RECETTE${Color_Off}\n"
cd $FOLDER_SRC_RECETTE
tar -zcvf ../"RECETTE_"$NAME.tar.gz *
cd -

printf "${Blue}PREPRODUCTION${Color_Off}\n"
cd $FOLDER_SRC_PREPROD
tar -zcvf ../"PREPROD_"$NAME.tar.gz *
cd -

printf "${Blue}PRODUCTION${Color_Off}\n"
cd $FOLDER_SRC_PROD
tar -zcvf ../"PROD_"$NAME.tar.gz *
cd -

printf "${Green}Your packages are ready in $DELIVER_FOLDER${Color_Off}\n"
