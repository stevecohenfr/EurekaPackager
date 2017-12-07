#!/bin/bash

BRANCH=$(git branch -a | grep -v remotes | grep ${BRANCH} | cut -d '*' -f2)

B_COUNT=$(echo -n "$BRANCH" | grep -c '^')
if [[ $B_COUNT -eq 0 ]];then
    printf "${Red}No Branch found !\nQuiting... ${Color_Off}\n"
    exit 1
elif [[ $B_COUNT -gt 1 ]];then
    printf "${Red}Several Branches found :${Color_Off}\n"
    echo "-----------------------------------------------------------------"
    echo "${BRANCH}"
    echo "-----------------------------------------------------------------"
    printf "${Red}Please, be more specific in the '-b' option \nQuiting...${Color_Off}\n"
    exit 1
fi

printf "${Green}Branch found !${Color_Off}\n"
echo "-----------------------------------------------------------------"
echo "${BRANCH}"
echo "-----------------------------------------------------------------"

mkdir -p ${TMP_DIR} 2> /dev/null
original_branch=environments_${ENV}_origin_branch
[[ -n ${!original_branch} ]] && original_branch="${!original_branch}" || original_branch="master"
printf "${Blue}Getting differences between branches ${Bold} '${original_branch}' and '${BRANCH}' ...${Color_Off}\n"

git archive  --format=tar.gz -o ${TMP_TAR} ${BRANCH} $(git diff --name-only --diff-filter=AMC ${original_branch}..${BRANCH})

