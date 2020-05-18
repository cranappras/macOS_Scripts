#!/bin/bash

# A bash script for Jamf to run to install nvm in local user space
# 

export localUser=$3


#################################################
# TS
#  timestamp function returns e.g. 20180406-15:11:01
function ts {
    date "+%Y%m%d-%H:%M:%S"
}


#################################################
# USER_RUN command
#  run the command as the $localuser
function user_run {
    sudo -u $localUser -i bash -c "$1"
}


# safety check when testing script
if [ -z $3 ]; then
    printf "$(ts): localUser not specified in \$3, exiting\n"
    exit 1
fi


summary=""      # the dialog result shown at the end
summary_file=`user_run mktemp`
printf "display dialog \"" >> $summary_file
#printf "display alert \"" >> $summary_file
warn_level=0    # the note(0)|caution(1)|stop(2) level to show at the end


#################################################
# SET_WARN_LEVEL level[0,1,2]
#  check the warn level against the provided one and set
function set_warn_level {
    level=${1:-0}
    if [ $level -gt $warn_level ]; then
        warn_level=$level
    fi
}


#################################################
# APPEND_SUMMARY message
#  append the provided message to the summary
function append_summary {
    _msg="$1"
    if [ -z "$summary" ]; then
        summary="$_msg"
        printf "$_msg" >> $summary_file
    else
        summary="$summary\n\n$_msg"
        printf "\n\n$_msg" >> $summary_file
    fi
}


#################################################
# RUN_APPLESCRIPT command_file
#  displays popup window with message
function run_applescript {
    msg_file="$1"
    user_run "osascript $msg_file"
}
#################################################
# reference: https://developer.apple.com/library/content/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_cmds.html#//apple_ref/doc/uid/TP40000983-CH216-SW12
#################################################


#################################################
# INSTALL_NVM
#  installs nvm, no parameters
function install_nvm {
    script='nvm-installer.sh'
    tmp_dir=`user_run "mktemp -d"`
    script_path="$tmp_dir/$script"
    curl -f "https://packages.qintel.com/files/$script" > $script_path
    chmod +x "$script_path"
    user_run "$script_path"
    rm -rf "$tmp_dir"
}


##########
# SCRIPT #
##########


# NVM
# Only install nvm if ~/.nvm does not exist
cd /Users/$localUser
if [ -e .nvm ]; then
    msg="nvm : ALREADY INSTALLED (~/.nvm already exists)"
    append_summary "$msg"
    printf "$(ts): $msg\n"
else
    install_nvm
    msg="nvm : INSTALLED"
    echo $msg
    append_summary "$msg"
    printf "$(ts): $msg\n"
fi


# NPMRC
# Add ~/.npmrc if it is not there already
cd /Users/$localUser
if [ -e .npmrc ]; then
    msg="npm config : ALREADY INSTALLED (~/.npmrc already exists)"
    append_summary "$msg"
    echo "$(ts): $msg"
else
    echo "registry=https://packages.qintel.com/npm/" > .npmrc
    chown -R "$localUser:QINTEL\\Domain Users" .npmrc
    msg="npm config : INSTALLED (~/.npmrc created)"
    append_summary "$msg"
    echo "$(ts): $msg"
fi


# Determine warn level icon and display dialog
icon_string="with icon stop"
if [ $warn_level -eq 1 ]; then
    icon_string="with icon caution"
elif [ $warn_level -eq 0 ]; then
    icon_string=""
fi
printf "\" buttons (\"OK\") default button 1 $icon_string with title \"Node Environment Installer Summary\"\n" >> $summary_file

run_applescript "$summary_file" "$icon_string"
rm -f $summary_file