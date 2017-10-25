#!/bin/bash
#
# Delivery system with GIT
#
# Created by Steve Cohen (stcoh)
# 12/04/2017
#

SCRIPT=`realpath -s $0`
SCRIPTPATH=`dirname $SCRIPT`
source "$SCRIPTPATH/".common.sh


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

#######################################
############ SCRIPT LOGIC #############
#######################################

echo "Starting archive script..."

#If GIT message is provided, search git commit SHA1
if [[ ! ${MESSAGE} == '' ]]; then
    messages=$(echo -e ${MESSAGE}|uniq)
    for mess in $messages; do
        printf "Searching commit SHA1 using commit containing message ${Blue}${mess}${Color_Off}...\n"
        COMMIT_LINES=`git log --all --pretty=format:"%H %ai %s" --grep="${mess}"`

        # Commit found
        if [ ! "${COMMIT_LINES}" == '' ]; then
            printf "${Green}Commit(s) found !${Color_Off}\n"
            echo "-----------------------------------------------------------------"
            echo "${COMMIT_LINES}"
            echo "-----------------------------------------------------------------"
            question="Is this the commit/Are these the commits you want to deliver ?(Y/n) "
            if ask_continue "$question";then
                for COMMIT_LINE in "$COMMIT_LINES"; do
                    commit=`echo "${COMMIT_LINE}" | awk '{print $1}'`
                    COMMIT+=$(echo -e "\n${commit}")
                done
            fi
        fi
    done
fi

# No Commit found -> Quit
if [[ ${COMMIT} == '' ]]; then
    printf "${Red}Sorry, no commit to pack. Quitting...${Color_Off}\n"
    exit 1
fi

# List commits in map array
for commit in $COMMIT; do
    if git cat-file -e ${commit} 2> /dev/null; then
        commit_key=`git log -1  --pretty=format:"%ai %H" ${commit}`
        COMMITS[$commit_key]=`git log -1  --pretty=format:"%ai %h %s" ${commit}`
    else
       printf "${Red}Commit ${commit} doesn't exist ...${Color_Off}\n\n"
    fi
done

# Sort commits by date
IFS=$'\n' SORTED_COMMITS=($(sort -u <<<"${!COMMITS[*]}"))
unset IFS

COMMIT_LIST=''
# Get SHA1 of commits sorted by date
printf "${Blue}Final commit list to deliver :${Color_Off}\n"
echo "-----------------------------------------------------------------"
for COMMIT_LINE in "${SORTED_COMMITS[@]}"; do
    echo "${COMMITS[${COMMIT_LINE}]}"
    commit=`echo "${COMMIT_LINE}" | awk '{print $NF}'`
    COMMIT_LIST+=$(echo -e "\n${commit}")
done
echo "-----------------------------------------------------------------"

rm -rf $DELIVER_TOP_FOLDER
mkdir -p $TMP_DIR

#temp tar archives for each commit
tar_files=''
for commit in $COMMIT_LIST; do
    git archive  --format=tar.gz -o "${TMP_DIR}/${commit}.tar.gz" ${commit} $(git diff --name-only --diff-filter=AMC ${commit}^..${commit})
    tar_files+="${TMP_DIR}/${commit}.tar.gz "
done
#concat tar archives in the final tar
cat $tar_files >> $TMP_TAR


#
# move source files to deploy in delivery directory : if deploy target's dir different from project's dir
#
move_sources() {
    if [ ! "$DEPLOY_ROOT" == "." ]; then
        ORIGIN_FILES="${FOLDER_SRC}/${DEPLOY_ROOT}/*"
        DEST_FILES="${FOLDER_SRC}/"
        mv $ORIGIN_FILES $DEST_FILES
        rm -rf "${FOLDER_SRC}/${DEPLOY_ROOT}"
    fi
}


mkdir ${FOLDER_SRC}
tar ixf $TMP_TAR -C ${FOLDER_SRC}
move_sources
rm -rf $TMP_DIR


printf "${Blue}Files list :${Color_Off}\n"
echo "-----------------------------------------------------------------"
find "${FOLDER_SRC}/" -type f
echo "-----------------------------------------------------------------"
printf "${Green}Files are ready for the packages in $FOLDER_SRC${Color_Off}\n"
question="Continue ? (Y/n) "
ask_continue "$question"

# Parse files, replace and remove __ENV__ lines
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


# Processing committed files
printf "${Blue}Copying files in delivery directories and packing${Color_Off}\n"

for ((i=0;i<${#ENVS_AFFIXES[@]};++i)); do

    printf "${Blue}${ENVS[i]}${Color_Off}\n"
    mkdir ${DELIVER_FOLDERS[i]}
    cp -r "${FOLDER_SRC}/." ${DELIVER_FOLDERS[i]}

    for file in `find ${DELIVER_FOLDERS[i]} -type f`; do
        update_env ${ENVS_AFFIXES[i]} $file
    done

    for file in `find ${DELIVER_FOLDERS[i]} -name *${ENVS_AFFIXES[i]}*`; do
            rm `echo $file | sed s/${ENVS_AFFIXES[i]}//g`;
            mv $file `echo $file | sed s/${ENVS_AFFIXES[i]}//g`;
    done

    cd ${DELIVER_FOLDERS[i]}
    tar cf "../${DELIVER_ARCHIVES[i]}.tar.gz" *
    cd - > /dev/null
done

printf "${Green}Your packages are ready in $DELIVER_TOP_FOLDER${Color_Off}\n"



####################################
# ######### DEPLOY ############### #
####################################
question="Proceed to deploy ? (Y/n) "
ask_continue "$question"

source "$SCRIPTPATH/"EurekaDeployer.sh