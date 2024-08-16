#!/bin/bash

exec > {{ rdp_backup_log_file }} 2>&1

 sudo {{ rdp_backup_scripts_dir }}/backup-xtrabackup.sh \
  --mysqlUser={{ rdp_backup_mysql_user }} \
  --mysqlPassword={{ rdp_backup_mysql_password }} \
  --mysqlDataDir={{ rdp_backup_mysql_data_dir }} \
  --mysqlRunDir={{ rdp_backup_mysql_run_dir }} \
  --backupFilePassword={{ rdp_backup_mysql_backup_file_password }} \
  --backupFilePath={{ rdp_backup_mysql_backup_file_path }}
