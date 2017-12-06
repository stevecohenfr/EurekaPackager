#!/bin/bash

NAME="${parameters_project_name}${parameters_delivery_suffix_format}"

DELIVER_TOP_FOLDER="$parameters_delivery_folder_parent/$NAME"
FOLDER_SRC="$DELIVER_TOP_FOLDER/$parameters_delivery_folder_sources"
TMP_DIR="$DELIVER_TOP_FOLDER/tmp"
TMP_TAR="$TMP_DIR/tmp.tar.gz"

mkdir -p ${TMP_DIR}
git archive  --format=tar.gz -o ${TMP_TAR} ${BRANCH} $(git diff --name-only --diff-filter=AMC dev..${BRANCH})

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
