#!/bin/bash

exec > {{ rdp_backup_log_file }} 2>&1

 sudo {{ rdp_backup_scripts_dir }}/backup-pgdump.sh \
  --postgresUser={{ rdp_backup_postgres_user }} \
  --postgresDatabase={{ rdp_backup_postgres_database }} \
  --backupFilePassword={{ rdp_backup_file_password }} \
  --backupFilePath={{ rdp_backup_file_path }}