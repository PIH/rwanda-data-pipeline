#!/bin/bash

/usr/bin/flock -n {{ rdp_transfer_lock_file }} {{ rdp_scripts_dir }}/transfer-rsync.sh \
  --sourceFile={{ rdp_transfer_source }} \
  --targetFile={{ rdp_transfer_target }}