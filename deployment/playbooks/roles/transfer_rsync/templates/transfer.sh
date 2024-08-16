#!/bin/bash

exec > {{ rdp_backup_log_file }} 2>&1

/usr/bin/flock -n {{ rdp_transfer_lock_file }} {{ rdp_backup_scripts_dir }}/transfer-rsync.sh \
  --sourceFile={{ rdp_transfer_source }} \
  --targetFile={{ rdp_transfer_target }}