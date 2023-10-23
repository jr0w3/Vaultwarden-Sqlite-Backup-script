#!/bin/bash
# Vaultwarden Sqlite Backup script
# backup.sh
# Author: Jr0w3
# Release: 23/10/2023
########################################

# Load stuff
. includes.sh

source backup.conf

check_commands "${CMDS_VAR[@]}"
check_vars
check_dir $DATADIR
check_backupdir_structure
remove_old_backups
backup
remote_copy
color green "Backup completed !"
