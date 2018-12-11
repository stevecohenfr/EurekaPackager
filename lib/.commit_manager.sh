#!/bin/bash


#######################################
############ SCRIPT LOGIC #############
#######################################

#If GIT message is provided, search git commit SHA1
if [[ ! ${MESSAGE} == '' ]]; then
    messages=$(echo -e ${MESSAGE}|uniq)
    for mess in $messages; do
        printf "Searching commit SHA1 using commit containing message ${Blue}${mess}${Color_Off}...\n"
        COMMIT_LINES=`git log --all --pretty=format:"%H %ai %s" --grep="${mess}" --no-merges --first-parent | grep -v "index on" | grep -v "Uncommitted"`

        # Commit found
        if [ ! "${COMMIT_LINES}" == '' ]; then
            printf "${Green}Commit(s) found !${Color_Off}\n"
            echo "-----------------------------------------------------------------"
            echo "${COMMIT_LINES}"
            echo "-----------------------------------------------------------------"
            question="Is this the commit/Are these the commits you want to deliver ?(Y/n) "
            [[ $interact ]] && proceed=$(ask_continue "$question") || proceed=0

            if [[ proceed ]];then
                for COMMIT_LINE in "$COMMIT_LINES"; do
                    commit=`echo "${COMMIT_LINE}" | awk '{print $1}'`
                    COMMIT+=$(echo -e "\n${commit}")
                done
            fi
        fi
    done
fi

declare -A COMMITS

# List commits in map array
for commit in $COMMIT; do
    if git cat-file -e ${commit} 2> /dev/null; then
        commit_key=`git log -1  --pretty=format:"%ai %H" ${commit}`
        COMMITS[$commit_key]=`git log -1  --pretty=format:"%ai %h %s" ${commit}`
    else
       printf "${Red}Commit '${commit}' doesn't exist ...${Color_Off}\n\n"
    fi
done

# No Commit found -> Quit
if [[ ${!COMMITS[*]} == '' ]]; then
    printf "${Red}Sorry, no commit to pack. Quitting...${Color_Off}\n"
    exit 1
fi


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

mkdir -p $TMP_DIR 2> /dev/null

#temp tar archives for each commit
tar_files=''
for commit in $COMMIT_LIST; do
    git archive  --format=tar.gz -o "${TMP_DIR}/${commit}.tar.gz" ${commit} $(git diff --name-only --diff-filter=AMC ${commit}^..${commit})
    tar_files+="${TMP_DIR}/${commit}.tar.gz "
done
#concat tar archives in the final tar
cat $tar_files >> $TMP_TAR
