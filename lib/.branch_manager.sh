#!/bin/bash

for branch in $BRANCH; do
    BRANCHES+=$(git branch -a | grep -v remotes | grep ${branch} | cut -d '*' -f2)
done

BRANCHES=$(echo ${BRANCHES} | tr ' ' '\n' | sort -u)

B_COUNT=$(echo -n "${BRANCHES}" | grep -c '^')
if [[ $B_COUNT -eq 0 ]];then
    printf "${Red}No Branch found !\nQuiting... ${Color_Off}\n"
    exit 1
elif [[ $B_COUNT -eq 1 ]];then
    printf "${Green}Branch found !${Color_Off}\n"
else
    printf "${Green}Several Branches found :${Color_Off}\n"
fi

echo "-----------------------------------------------------------------"
echo "${BRANCHES}"
echo "-----------------------------------------------------------------"

mkdir -p ${TMP_DIR} 2> /dev/null

original_branch=environments_${ENV}_origin_branch
[[ -n ${!original_branch} ]] && original_branch="${!original_branch}" || original_branch="master"
printf "${Blue}Getting differences between found branches and ${Bold} '${original_branch}'${Color_Off}${Blue} branch... ${Color_Off}\n"

tar_files=''
for branch in $BRANCHES; do
    tmp_tar=$(echo -n ${branch} | md5sum | cut -d ' ' -f 1)
    git archive  --format=tar.gz -o "${TMP_DIR}/${tmp_tar}.tar.gz" ${branch} $(git diff --name-only --diff-filter=AMC ${original_branch}..${branch})
    tar_files+="${TMP_DIR}/${tmp_tar}.tar.gz "
done

#concat tar archives in the final tar
cat $tar_files >> $TMP_TAR