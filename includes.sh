#!/bin/bash
# Vaultwarden Sqlite Backup Includes
# includes.sh
# Author: Jr0w3
# Release: 23/10/2023
########################################

#### Vars ##############################
########################################

DAY=$(date '+%Y%m%d')
TIME=$(date '+%H.%M')
CMDS_VAR=("sqlite3" "logger" "tar" "gzip")

#### Function ##########################
########################################
# Print colorful message.
# Arguments:
#     color
#     message
# Outputs:
#     colorful message
########################################
function color() {
    local log_message="$2"
    case $1 in
        red)     echo -e "\033[31m$2\033[0m" ;;
        green)   echo -e "\033[32m$2\033[0m" ;;
        yellow)  echo -e "\033[33m$2\033[0m" ;;
        blue)    echo -e "\033[34m$2\033[0m" ;;
        none)    echo -e "$2" ;;
    esac

    if [ "$ENABLELOG" = "true" ]; then
        logger -t vw-backup "$2"
    fi

}

########################################
# Check cmds.
# Arguments:
#     one or more cmds
########################################
function check_commands() {
    local missing=()
    
    for cmd in "$@"; do
        if ! which "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        color blue "Info: All necessary cmds are installed : $@"
    else
        color red "Error: One or more commands are missing : ${missing[*]}"
        exit 1
    fi
}

########################################
# Check package.
# Arguments:
#     one or more packages
########################################
function check_package() {
    local missing=()

    for pkg in "$@"; do
        if ! dpkg-query -l "$pkg" &> /dev/null; then
             missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        color blue "Info: All necessary packages are installed : $@"
    else
        color red "Error: One or more packages are missing : ${missing[*]}"
        exit 1
    fi

}

########################################
# Check vars and stuff.
# Arguments:
#     no arguments
########################################
function check_vars_and_stuff() {
    check_if_required_vars_set LOCALBACKUPDIR DATADIR RETENTION

    if [ "$ENABLERSYNC" = "true" ]; then
        check_if_required_vars_set REMOTEHOST REMOTEUSER REMOTEPATH
        check_commands rsync
    fi
    if [ "$ENABLESMB" = "true" ]; then
        check_if_required_vars_set SMB_USERNAME SMB_PASSWORD REMOTEHOST REMOTESHARE
        check_package cifs-utils
    fi
}


########################################
# Check file is exist.
# Arguments:
#     file
########################################
function check_file_exist() {
    if [[ ! -f "$1" ]]; then
        color red "Error: Cannot access $1: No such file"
        exit 1
    fi

    if [[ ! -r "$1" ]]; then
        color red "Error: Cannot read $1: Permission denied"
        exit 1
    fi
}

########################################
# Check directory and write permission an create them if needed
# Arguments:
#     directory
########################################
function check_and_prepare_dirs() {
    if [ -d "$1" ]; then
        if [ ! -w "$1" ]; then
            color red "Error: Cannot write to $1"
            exit 1
        fi
    else
        create_dir "$1"
    fi
}

########################################
# Check if directory exist
# Arguments:
#     directory
########################################
function check_dir() {
    if [ ! -d "$1" ]; then
        color blue "Info: Cannot access $1: No such directory."
    fi
}

########################################
# Create directory.
# Arguments:
#     directory name
########################################
function create_dir() {
    mkdir -p "$1"

    if [[ $? -ne 0 ]]; then
        color red "Error: Cannot create $1 directory"
        exit 1
    fi
}

########################################
# Check if required variable set.
# Arguments:
#     one or more variable
########################################
function check_if_required_vars_set() {
    local missing_vars=()

    for var in "$@"; do
        if [ -z "${!var}" ]; then
            color red "Error: Variable '$var' is not set."
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        color red "Error: Exiting the script due to missing variables."
        exit 1
    fi
}

########################################
# Check if optional variable set.
# Arguments:
#     one variable
########################################
function is_optionnal_variable_set() {
    if [ -n "$1" ]; then
        return 0 
    else
        return 1
    fi
}

########################################
# Create backup structure
# Arguments:
#     no arguments 
########################################
function check_backupdir_structure()
{
	check_and_prepare_dirs "$LOCALBACKUPDIR"
    WORKINGDIR="vw-backup-$DAY-$TIME"
    check_and_prepare_dirs "$LOCALBACKUPDIR/$WORKINGDIR"
}

########################################
# Clean old backups
# Arguments:
#     no arguments 
########################################
function clean_old_backups()
{
    $FIND $LOCALBACKUPDIR/* -type f -ctime +$RETENTION
    $FIND $LOCALBACKUPDIR/* -type f -ctime +$RETENTION -exec rm -rf {} \;

    if [ $? -eq 0 ]; then
        color blue "Info: Old backup directories removed."
    else
        color red "Error: Failed to remove old backup directories."
        exit 1
    fi
}

########################################
# Checking true vars
# Arguments:
#     variable
########################################
function is_true(){
    if [ "$1" = "true" ]; then
        return 0
    else
        return 1
    fi
}

########################################
# Remove backups files older than retention
# Arguments:
#     no arguments 
########################################
function remove_old_backups(){
    find $LOCALBACKUPDIR -type f -mtime +$RETENTION -exec rm {} \;
    if [[ $? -ne 0 ]]; then
        color red "Error: An error occurred while removing old backups."
        exit 1
    fi    
}

########################################
# Perform necessary backup tasks
# Arguments:
#     no arguments 
########################################
function backup(){
    sqlite_backup
    is_true $BACKUP_ATTACHMENTS && backup_alts_data "$DATADIR/attachments"
    is_true $BACKUP_ICON_CACHE && backup_alts_data "$DATADIR/icon_cache"
    is_true $BACKUP_SENDS && backup_alts_data "$DATADIR/sends"
    is_true $BACKUP_RSA_KEY && backup_alts_data "$DATADIR/rsa_key.pem" && backup_alts_data "$DATADIR/rsa_key.pub.pem"
    is_true $BACKUP_CONFIG_JSON && backup_alts_data "$DATADIR/config.json"
    make_archive
}

########################################
# Run Sqlite backup
# Arguments:
#     no arguments 
########################################
function sqlite_backup(){
    DBFILE="$DATADIR/db.sqlite3"
    check_file_exist $DBFILE
	color blue "Info: Backing up sqlite db"
    sqlite3 "$DBFILE" ".backup '"$LOCALBACKUPDIR/$WORKINGDIR/db.sqlite3"'"

    if [[ $? -ne 0 ]]; then
        color red "Error: An error occurred while exporting the database."
        exit 1
    fi
}

########################################
# Copy backup_alts_data to backupdir
# Arguments:
#     source
########################################
function backup_alts_data(){
    cp -r "$1" "$LOCALBACKUPDIR/$WORKINGDIR/"
    if [[ $? -ne 0 ]]; then
        color yellow "An error occurred while saving $1. The source may not exist."
    fi
}

########################################
# Make backup copressed archive (.tar.gz)
# Arguments:
#     
########################################
function make_archive(){
    tar -czvf "$LOCALBACKUPDIR/$WORKINGDIR.tar.gz" -C "$LOCALBACKUPDIR" "$WORKINGDIR"
    if [[ $? -ne 0 ]]; then
        color red "Error: An error occurred while maling backup archive."
    fi
    rm -rf $LOCALBACKUPDIR/$WORKINGDIR
}



########################################
# Remote Copy
# Arguments:
#     no arguments 
########################################
function remote_copy(){
    if [ "$ENABLERSYNC" = "true" ]; then
        rsync_copy
    fi 

    if [ "$ENABLESMB" = "true" ]; then
        smb_copy
    fi
    
}

########################################
# Run RSYNC backup
# Arguments:
#     no arguments 
########################################
function rsync_copy(){
    color blue "Info: Copying via Rsync..."
    rsync -a --no-o --delete --safe-links --timeout=10 "$LOCALBACKUPDIR" "$REMOTEUSER@$REMOTEHOST:$REMOTEPATH"
    ERRORLVL=$?

    if [[ $ERRORLVL -ne 0 ]]; then
        color red "Error: Rsync returned $ERRORLVL error code."
        exit 1
    fi
}

########################################
# Run SMB/CIFS backup
# Arguments:
#     no arguments 
########################################
function smb_copy(){
    color blue "Info: Copying via SMB/CIFS..."

    MOUNTPOINT='/tmp/vw-backup'

    if [ ! -d "$MOUNTPOINT" ]; then
        mkdir -p $MOUNTPOINT
    fi

    mount -t cifs -o username=$SMB_USERNAME,password=$SMB_PASSWORD //$REMOTEHOST/$REMOTESHARE $MOUNTPOINT

    if [ $? -ne 0 ]; then
        color red "Error: Failed to mount SMB/CIFS share."
        exit 1
    fi
    
    cp -r "$LOCALBACKUPDIR"/* "$MOUNTPOINT"
    
    if [ $? -ne 0 ]; then
        color red "Error: Failed to copy data to SMB/CIFS share."
        umount $MOUNTPOINT
        exit 1
    fi
    
    color green "Success: Data copied via SMB/CIFS."
    
    umount $MOUNTPOINT
}