#!/bin/bash
# Vaultwarden Sqlite Backup script
# backup.sh
# Author: Jr0w3
# Release: 23/10/2023
########################################

# Load stuff
source "$(dirname "${BASH_SOURCE[0]}")/includes.sh"
source "$(dirname "${BASH_SOURCE[0]}")/backup.conf"

check_commands "${CMDS_VAR[@]}"
check_vars_and_stuff
check_dir $DATADIR
check_backupdir_structure
remove_old_backups
backup
remote_copy
color green "Backup completed !"
