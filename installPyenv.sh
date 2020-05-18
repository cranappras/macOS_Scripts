#!/bin/bash

# A bash script for Jamf to run to install pyenv in local user space
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
# APPEND_LOG message
#  append the provided message to the summary
function append_log {
    _msg="$1"
    printf "$(ts): $_msg\n" >> $local_log
    printf "$(ts): $_msg\n"
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
    append_log "$_msg"
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
# INSTALL_PYENV
#  installs pyenv, no parameters
function install_pyenv {
    script='pyenv-installer.sh'
    tmp_dir=`user_run "mktemp -d"`
    script_path="$tmp_dir/$script"
    curl -f "https://packages.qintel.com/files/$script" > $script_path
    chmod +x "$script_path"
    # TESTING ONLY
    #script_path="/Users/$localUser/dev/devops/jamf-pyenv-installer/$script"
    append_log "Running pyenv install script."
    user_run "$script_path" >> $local_log 2>&1
    ret_code=$?
    rm -rf "$tmp_dir"
    return $ret_code
}


#################################################
# CONFIGURE_BASH_PROFILE
function configure_bash_profile {
    config="
###########################################################
# ADDED BY JAMF PYENV INSTALLER
# pyenv path injection and auto activation
export PATH=\"/Users/$localUser/.pyenv/bin:\$PATH\"
eval \"\$(pyenv init -)\"
eval \"\$(pyenv virtualenv-init -)\"
###########################################################
"
    # find configs
    opt_config_files=(.bashrc .bashrc.local .profile .profile.local .bash_profile)
    file_string=""
    for cf in "${opt_config_files[@]}"
    do
        if [ -e "$cf" ]; then
            file_string="$file_string $cf"
        fi
    done

    match_files=""
    if [ -n "$file_string" ]; then
        match_files=`grep -l pyenv $file_string`
        grep_res=$?
    fi

    if [ -z "$match_files" ]; then
        printf "$config" >> .bash_profile
        msg="auto env : INSTALLED (added to ~/.bash_profile)"
        append_summary "$msg"
    else
        msg="auto env : BROKEN (pyenv present in $match_files but pyenv not in path, you can clean and re-run)"
        set_warn_level 1
        append_summary "$msg"
    fi
}


#################################################
# Configure local logging
jamf_log_dir="/Users/$localUser/.jamf_logs"
local_log="$jamf_log_dir/pyenv_install.log"
mkdir -p $jamf_log_dir
printf "\n\n=============================================\n" >> $local_log
printf "$(ts): INSTALL OF PYENV TRIGGERED\n" >> $local_log
chown -R $localUser $jamf_log_dir


##########
# SCRIPT #
##########

# XCODE
# Verify Xcode existence and configure Xcode environment.
if [ -e /Applications/Xcode.app ]; then
	xcodebuild -license accept
    xcodebuild -runFirstLaunch
    installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
    msg="Xcode : CONFIGURED"
    append_summary "$msg"
else
	msg="Xcode : ERROR: Xcode could not be configured, please verify that Xcode is installed"
    append_summary "$msg"
fi

# PYENV
# Only install pyenv if ~/.pyenv does not exist
cd /Users/$localUser
if [ -d .pyenv ]; then
    msg="pyenv : ALREADY INSTALLED (~/.pyenv already exists)"
    append_summary "$msg"
else
    install_pyenv
    if [[ $? -ne 0 || ! -d .pyenv ]]; then
        msg="pyenv : ERROR: pyenv could not be installed, please check $local_log for more details"
    else
        msg="pyenv : INSTALLED"
    fi
    append_summary "$msg"
fi


# .BASH_PROFILE
# Only try to configure .bash_profile if pyenv is not in the path
cd /Users/$localUser
user_run "which pyenv" > /dev/null
if [ $? -eq 0 ]; then
    msg="auto env : ALREADY INSTALLED (pyenv detected in the path)"
    append_summary "$msg"
else
    configure_bash_profile
fi

# PIP
# Add ~/.pip/pip.conf if it is not there already
cd /Users/$localUser
if [ -e .pip/pip.conf ]; then
    msg="pip config : ALREADY INSTALLED (~/.pip/pip.conf already exists)"
    append_summary "$msg"
else
    mkdir -p .pip
    echo "[global]
index_url = https://packages.qintel.com/pypi/qintel/prod/+simple/" > .pip/pip.conf
    chown -R "$localUser:QINTEL\\Domain Users" .pip
    msg="pip config : INSTALLED (~/.pip/pip.conf created)"
    append_summary "$msg"
fi


# Determine warn level icon and display dialog
icon_string="with icon stop"
if [ $warn_level -eq 1 ]; then
    icon_string="with icon caution"
elif [ $warn_level -eq 0 ]; then
    icon_string=""
fi
printf "\" buttons (\"OK\") default button 1 $icon_string with title \"Python Environment Installer Summary\"\n" >> $summary_file

run_applescript "$summary_file" "$icon_string"
rm -f $summary_file
