#!/bin/bash

ENV_FILE=
while getopts e: flag
do
  case "${flag}" in
    e) ENV_FILE=${OPTARG};;
  esac
done

if [ -z ${ENV_FILE} ]; then
  echo "You must pass the location of an environment variable file with the -e flag"
  echo "Usage:  ./backup.sh -e /path/to/env/file"
  exit 1
fi

if [ -a ${ENV_FILE} ]; then
  source ${ENV_FILE}
else
  echo "The specified environment variable file does not exist at ${ENV_FILE}"
  exit 1
fi

if [ "$RDP_MYSQLDUMP_ENABLED" == "true" ]; then
  bash ./backup-mysqldump.sh
fi

if [ "$RDP_PERCONA_BACKUP_ENABLED" == "true" ]; then
  bash ./backup-xtrabackup.sh
fi
