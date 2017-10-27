#!/bin/bash


DELIVER_FOLDER=${FOLDER_SRC}_${ENV}
DELIVER_ARCHIVE="${ENV^^}_${NAME}.tar.gz"
ENV_SUFFIX=environnements_${ENV}_suffix
ENV_NAME=environnements_${ENV}_name

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
    #Remove all __ENV__ from current file
    sed -e "s/$1//g" -i "$2"
     for i in ${environnements_list[*]}; do
        env_suffix=environnements_${i}_suffix
        sed -e "/${!env_suffix}/ d" -i "$2"
    done;
}


# Processing committed files
printf "${Blue}Copying files in delivery directory and packing${Color_Off}\n"

printf "${Blue}${!ENV_NAME}${Color_Off}\n"
mkdir $DELIVER_FOLDER
cp -r "${FOLDER_SRC}/." $DELIVER_FOLDER

for file in `find $DELIVER_FOLDER -type f`; do
    update_env ${!ENV_SUFFIX} $file
done

for file in `find $DELIVER_FOLDER -name *${!ENV_SUFFIX}*`; do
        rm `echo $file | sed s/$${!ENV_SUFFIX}//g`;
        mv $file `echo $file | sed s/$${!ENV_SUFFIX}//g`;
done

cd $DELIVER_FOLDER
tar cf "../${DELIVER_ARCHIVE}" *
cd - > /dev/null

printf "${Green}Your packages are ready in $DELIVER_TOP_FOLDER${Color_Off}\n"

