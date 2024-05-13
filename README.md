# Vaultwarden Sqlite Backup Script

![Release Date](https://img.shields.io/badge/Release-23/10/2023-brightgreen)

This script is designed to automate the backup process for Vaultwarden sqlite database.

## Table of Contents

- [Overview](#overview)
- [Configuration](#configuration)
- [Usage](#usage)
- [Creating a Cron Job for Automated Backup](#creating-a-cron-job-for-automated-backup)
- [Using Rsync for Remote Backups](#using-rsync-for-remote-backups)
- [Author](#author)

## Overview

Vaultwarden is a self-hosted password manager. This script helps you create and manage backups of your Vaultwarden data to ensure the safety of your password database.  Currently the script allows you to keep backups locally or synchronize them via rsync.

## Configuration

Before using the script, you need to configure it by editing the `backup.conf` file. Here are the main parameters you should set:

### Required Parameters

- `LOCALBACKUPDIR`: The local directory to store all backups.
- `DATADIR`: The Vaultwarden data directory.
- `RETENTION`: The backup retention time in days.

### Optional Parameters

- `ENABLELOG`: Enable logging to systemd (true or false).
- `BACKUP_ATTACHMENTS`: Set to true to include the attachments folder in the backup.
- `BACKUP_CONFIG_JSON`: Set to true to include the `config.json` file in the backup.
- `BACKUP_ICON_CACHE`: Set to true to include the icon cache folder in the backup.
- `BACKUP_RSA_KEY`: Set to true to include the RSA keys in the backup.
- `BACKUP_SENDS`: Set to true to include the `sends` folder in the backup.
- `ENABLERSYNC`: Enable Rsync (true or false).
- `REMOTEHOST`: The Rsync remote host.
- `REMOTEUSER`: The Rsync remote user.
- `REMOTEPATH`: The Rsync remote path.
- `ENABLESMB` : Enable SMB/CIFS (true or false).
- `REMOTEHOST` : The SMB/CIFS remote host.
- `SMB_USERNAME` : The SMB/CIFS remote user.
- `SMB_PASSWORD` : The SMB/CIFS remote user.
- `REMOTESHARE` : The SMB/CIFS remote path.

## Usage

1. **Clone this repository or download the script files**.

   ```bash
   git clone https://github.com/jr0w3/Vaultwarden-Sqlite-Backup-script.git && cd Vaultwarden-Sqlite-Backup-script/
   ```

2. **Configure the `backup.conf` file with your specific settings**.
   ```bash
   nano backup.conf
   ```

3. **Run the script by executing `./backup.sh` in the terminal**.
   ```bash
   ./backup.conf
   ```

4. **The script will perform the backup and, if configured, sync the backup to a remote location**.

5. **You can schedule this script to run periodically to ensure regular backups of your Vaultwarden data**.

## Creating a Cron Job for Automated Backup

You can automate the Vaultwarden backup process by setting up a cron job. Here's how to do it:

1. **Open a terminal**.

2. **Open your user's crontab by running the following command**:

   ```bash
   crontab -e
   ```
3. **Add the following line to schedule the execution of the backup script every day at midnight (00:00)**:
   ```bash
   0 0 * * * /path/to/your/script/backup.sh
   ```
4. **Save and close the text editor**.

The cron job is now set up to automatically run the Vaultwarden backup script every day at midnight.

Make sure to adjust the time and frequency as needed. You can use the crontab.guru tool to help generate complex cron expressions if necessary.

After setting up the cron job, the script will run automatically at the specified time, ensuring regular backups of your Vaultwarden data.

## Using Rsync for Remote Backups

If you've configured the `ENABLERSYNC` option in your Vaultwarden backup script to use Rsync for remote backups, it's important to ensure that SSH key authentication is set up between your local and remote machines. This will allow the backup process to run without requiring a password input.

Here's how to set up SSH key authentication for Rsync:

1. **Generate SSH Keys**: If you haven't already done so, you'll need to generate an SSH key pair on your local machine. You can do this with the following command:

   ```bash
   ssh-keygen -t rsa
   ```
You can leave the passphrase empty for passwordless authentication.

2. **Copy the Public Key**: After generating your SSH key pair, you need to copy the public key to the remote machine. You can use the **ssh-copy-id** command to do this:
   ```bash
   ssh-copy-id user@remote_host
   ```
Replace `user` with your remote username and `remote_host` with the hostname or IP address of the remote machine.

3. **Test SSH Access**: To ensure that SSH key authentication is working correctly, try connecting to the remote machine without a password prompt:
   ```bash
   ssh user@remote_host
   ```
You should be able to log in without being asked for a password.

4. **Secure the Private Key**: Make sure to keep your private key secure on your local machine, as it provides access to the remote system. Protect it with appropriate file permissions.

Once SSH key authentication is set up, your Rsync command in the backup script will be able to connect to the remote host without requiring a password. This is essential for unattended, automated backups. Make sure to replace `user` and `remote_host` with your actual username and remote host information.

## Using SMB/CIFS for Remote Backups
You need setup `ENABLESMB` to `true` top enable SMB/CIFS backup.

## Author

- Author: Jr0w3
- Release Date: 23/10/2023

If you have any questions or encounter issues with the script, please feel free to [create an issue on GitHub](https://github.com/jr0w3/Vaultwarden-Sqlite-Backup-script/issues) for assistance. The author will be happy to help you with any problems you may encounter.
