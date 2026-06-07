#!/bin/bash

# Define where you want backups saved (change this if you have a specific backup drive)
BACKUP_DIR="/home/dev/stacks/vikunja/backups"
STACK_DIR="/home/dev/stacks/vikunja"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# 1. Backup the Postgres Database
# We use -T to disable TTY allocation since this will run in the background
docker compose -f "$STACK_DIR/compose.yml" exec -T db pg_dumpall -U vikunja > "$BACKUP_DIR/db_backup_$DATE.sql"

# 2. Backup the Vikunja attachments (files directory)
tar -czf "$BACKUP_DIR/files_backup_$DATE.tar.gz" -C "$STACK_DIR" files

# 3. (Optional) Delete backups older than 14 days to save space
find "$BACKUP_DIR" -type f -mtime +14 -name "*.sql" -exec rm {} \;
find "$BACKUP_DIR" -type f -mtime +14 -name "*.tar.gz" -exec rm {} \;
