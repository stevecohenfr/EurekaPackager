#!/bin/bash


SCRIPT=`realpath -s $0`
SCRIPTPATH=`dirname $SCRIPT`
source "$SCRIPTPATH/".common.sh

# generate vars from yaml file
create_variables config.yml



# access yaml content
integ=${environnements_list[3]}
echo ${integ}
test=environnements_${integ}_short
echo ${!test}
