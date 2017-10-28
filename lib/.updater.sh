#!/bin/bash

# TODO: self-upgrade of lib/*
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
    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/master/EurekaPackager.sh")
    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/master/lib/*")

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