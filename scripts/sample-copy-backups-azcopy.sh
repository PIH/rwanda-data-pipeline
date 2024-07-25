#!/bin/bash

# This uses azcopy to transfer backup files from a server into Azure
# We will want to change / adapt this to support different backup mechanisms (eg. Azcopy, Rsync, Scp, etc)

export PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
export AZCOPY_CONCURRENCY_VALUE=<%= @azcopy_concurrency_value %>
export AZCOPY_CONCURRENT_FILES=<%= @azcopy_concurrent_files %>

BASE_DIR=<%= @tomcat_home_dir %>/backups
AZSECRET='<%= @az_secret %>'
AZURL='<%= @az_url %>'
AZBACKUPFOLDERPATH='<%= @az_backup_folder_path %>'
DATE=$(date +"%Y%m%d")

if [ ! -z "$AZBACKUPFOLDERPATH" ]; then

  mkdir -p ${BASE_DIR}/logs
  log_file=${BASE_DIR}/logs/azcopy-${DATE}.log

  echo $(date +%F-time-%T) >> $log_file

  if [ -d "${BASE_DIR}/percona" ]; then
    azcopy sync "${BASE_DIR}/percona/"  "${AZURL}/${AZBACKUPFOLDERPATH}/percona/?${AZSECRET}" --recursive=true --delete-destination=false >> $log_file
  fi

  if [ -d "${BASE_DIR}/sequences" ]; then
    azcopy sync "${BASE_DIR}/sequences/"  "${AZURL}/${AZBACKUPFOLDERPATH}/sequences/?${AZSECRET}" --recursive=true --delete-destination=false >> $log_file
  fi

  if [ -d "${BASE_DIR}/archive" ]; then
    azcopy sync "${BASE_DIR}/archive/"  "${AZURL}/${AZBACKUPFOLDERPATH}/archive/?${AZSECRET}" --recursive=true --delete-destination=false >> $log_file
  fi

fi
