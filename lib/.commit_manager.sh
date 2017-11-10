#!/bin/bash

printf "${Blue}Processing provided git information ...${Color_Off}\n"

declare -A COMMITS
NAME="${parameters_project_name}${parameters_delivery_suffix_format}"

DELIVER_TOP_FOLDER="$parameters_delivery_folder_parent/$NAME"
FOLDER_SRC="$DELIVER_TOP_FOLDER/$parameters_delivery_folder_sources"
TMP_DIR="$DELIVER_TOP_FOLDER/tmp"
TMP_TAR="$TMP_DIR/tmp.tar.gz"

#######################################
############ SCRIPT LOGIC #############
#######################################

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
# print all commits sorted by date to deliver
# and get only SHA1 of these commits
printf "${Blue}Final commit list to deliver :${Color_Off}\n"
echo "-----------------------------------------------------------------"
for COMMIT_LINE in "${SORTED_COMMITS[@]}"; do
    echo "${COMMITS[${COMMIT_LINE}]}"
    commit=`echo "${COMMIT_LINE}" | awk '{print $NF}'`
    COMMIT_LIST+=$(echo -e "\n${commit}")
done
echo "-----------------------------------------------------------------"

#rm -rf $DELIVER_TOP_FOLDER
mkdir -p $TMP_DIR

#temp tar archives for each commit
tar_files=''
for commit in $COMMIT_LIST; do
    git archive  --format=tar.gz -o "${TMP_DIR}/${commit}.tar.gz" ${commit} $(git diff --name-only --diff-filter=AMC ${commit}^..${commit})
    tar_files+="${TMP_DIR}/${commit}.tar.gz "
done
#concat tar archives in the final tar
cat $tar_files >> $TMP_TAR

# extract tmp archive in source dir
mkdir ${FOLDER_SRC}
 if [ ! "$parameters_project_target_root" == "." ]; then
    tar ixf $TMP_TAR -C ${FOLDER_SRC} --strip-components=1 "${parameters_project_target_root}"
else
    tar ixf $TMP_TAR -C ${FOLDER_SRC}
fi


printf "${Blue}Files list :${Color_Off}\n"
echo "-----------------------------------------------------------------"
tar itzf $TMP_TAR | grep -v '\/$'
echo "-----------------------------------------------------------------"
printf "${Green}Files are ready for the packages in $FOLDER_SRC${Color_Off}\n"

rm -rf $TMP_DIR
