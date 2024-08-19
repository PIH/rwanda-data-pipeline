#!/bin/bash

exec > {{ rdp_log_file }} 2>&1

sudo {{ rdp_scripts_dir }}/restore-xtrabackup.sh \
  --mysqlRootPassword={{ item.mysqlRootUser }} \
  --mysqlContainerName={{ item.mysqlContainerName }} \
  --mysqlContainerPort={{ item.mysqlContainerPort }} \
  --mysqlContainerTimezone={{ item.mysqlContainerTimezone }} \
  --mysqlDataDir={{ item.mysqlDataDir }} \
  --mysqlRunDir={{ item.mysqlRunDir }} \
  --restoreFilePassword={{ item.restoreFilePassword }} \
  --restoreFilePath={{ item.restoreFilePath }} \
  --restoreMd5FilePath={{ item.restoreMd5FilePath }} \
  --latestMd5FilePath={{ item.latestMd5FilePath }}
