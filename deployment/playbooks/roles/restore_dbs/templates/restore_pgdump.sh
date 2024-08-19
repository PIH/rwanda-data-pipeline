#!/bin/bash

exec > {{ rdp_log_file }} 2>&1

sudo {{ rdp_scripts_dir }}/backup-xtrabackup.sh \
  --postgresUser={{ item.postgresUser }} \
  --postgresPassword={{ item.postgresPassword }} \
  --postgresDatabase={{ item.postgresDatabase }} \
  --postgresContainerName={{ item.postgresContainerName }} \
  --postgresContainerPort={{ item.postgresContainerPort }} \
  --postgresContainerImage={{ item.postgresContainerImage }} \
  --restoreFilePassword={{ item.restoreFilePassword }} \
  --restoreFilePath={{ item.restoreFilePath }} \
  --restoreMd5FilePath={{ item.restoreMd5FilePath }} \
  --latestMd5FilePath={{ item.latestMd5FilePath }}
