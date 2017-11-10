#!/bin/bash

# TODO: self-upgrade of lib/*
#######################################
############### UPDATER ###############
#######################################

function check_update {
    REMOTE_VERSION=`curl -sL https://rawgit.com/ReaperSoon/EurekaPackager/dev/VERSION`

    if [[ "$SCRIPT_VERSION" < "$REMOTE_VERSION" ]]; then
	printf "${Yellow}Your script is deprecated (${SCRIPT_VERSION} < ${REMOTE_VERSION}). Please use -u or --upgrade${Color_Off}\n"
    fi
}

function self_upgrade {
    # TODO : for each required file - local filename

    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/dev/EurekaPackager.sh")
    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/dev/lib/.commit_manager.sh")
    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/dev/lib/.common.sh")
    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/dev/lib/.config_checker.sh")
    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/dev/lib/.deployer.sh")
    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/dev/lib/.packager.sh")
    DIST_SCRIPTS+=("https://rawgit.com/ReaperSoon/EurekaPackager/dev/lib/.updater.sh")

    # Download new version
    printf "${Green}Downloading latest version...${Color_Off}\n"
    file_counter=0
    for i in ${DIST_SCRIPTS[*]}; do
        if ! wget --quiet --output-document="$file_counter.tmp" ${i} ; then
            printf "${Red}Failed: Error while trying to wget new version!${Color_Off}\n"
            printf "${Red}File requested: ${i}${Color_Off}\n"
            exit 1
        fi

           # Copy over modes from old version
        OCTAL_MODE=$(stat -c '%a' ${file_counter})
        if ! chmod $OCTAL_MODE "$file_counter.tmp" ; then
            printf "${Red}Failed: Error while trying to set mode on $file_counter.tmp.${Color_Off}\n"
            exit 1
        fi
    done;

    printf "${Green}Done.${Color_Off}\n"



    # Spawn update script
    # TODO : for each required file
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