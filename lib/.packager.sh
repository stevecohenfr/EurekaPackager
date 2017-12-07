#!/bin/bash

printf "${Blue}Copying files in delivery directory for ${!ENV_NAME^^} environment...${Color_Off}\n"

DELIVER_FOLDER=${FOLDER_SRC}_${ENV}
DELIVER_ARCHIVE="${ENV^^}_${NAME}.tar.gz"
ENV_SUFFIX=environments_${ENV}_suffix
ENV_NAME=environments_${ENV}_name

# Parse files, replace and remove __<ENV>__ lines
#
# $1 : __ENV__ pattern
# $2 : file to modify
#
function update_env {
    if [[ -z verbose ]]; then
        echo "*** Updating $2 ***"
    fi

    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ $line == *"$1"* ]]; then
            #Get normal key without __ENV__
            normal_key=`echo "${line/$1/}" | awk -F"=" '{print $1}'`
            l=0
            while IFS='' read -r line2 || [[ -n "$line2" ]]; do
                ((l++))
                if [[ $line2 == "${normal_key}="* ]]; then
                    [[ $verbose ]] && echo "Removing LXC variable at line $l : ${line2}"
                    #Remove current line
                    sed "${l}d" -i "$2"
                    break;
                fi
            done < "$2"
        fi
    done < $2
    #Remove all __ENV__ from current file
    sed -e "s/$1//g" -i "$2"
    for i in ${environments_list[*]}; do
        env_suffix=environments_${i}_suffix
        sed -e "/${!env_suffix}/ d" -i "$2"
    done;
}

mkdir $DELIVER_FOLDER
cp -r "${FOLDER_SRC}/." $DELIVER_FOLDER

for file in `find $DELIVER_FOLDER -type f`; do
    update_env ${!ENV_SUFFIX} $file
done

for file in `find $DELIVER_FOLDER -name *${!ENV_SUFFIX}*`; do
    rm `echo $file | sed s/$${!ENV_SUFFIX}//g`;
    mv $file `echo $file | sed s/$${!ENV_SUFFIX}//g`;
done

type=environments_${ENV}_deploy_type
case "${!type}" in
    "pkg"|"package" )
        cd $DELIVER_FOLDER
        tar zcf "../${DELIVER_ARCHIVE}" *
        cd - > /dev/null
        printf "${Green}Your packages are ready in $DELIVER_TOP_FOLDER${Color_Off}\n"
        shift
    ;;
    "src"|"sources" )
        printf "${Green}Your sources are ready in $DELIVER_TOP_FOLDER${Color_Off}\n"
        shift
    ;;
esac


