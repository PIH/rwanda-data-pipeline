#!/bin/bash
#
# Restore a Percona xtrabackup to a data directory
#
echoWithDate() {
  echo "$(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

BACKUP_DIR=/tmp/rwanda-data-pipeline/backups
XTRABACKUP_DATA_DIR=${BACKUP_DIR}/xtrabackup_data_dir
RESTORE_DATA_DIR=/home/mseaton/environments/mysql/targetdb/data

echoWithDate "Restoring Percona Backup to ${RESTORE_DATA_DIR}"

rm -fR ${RESTORE_DATA_DIR}
docker run --rm \
  -v ${RESTORE_DATA_DIR}:/var/lib/mysql \
  -v ${XTRABACKUP_DATA_DIR}:/xtrabackup_data \
  --user root \
  percona/percona-xtrabackup:8.0 \
  /bin/bash -c "xtrabackup --copy-back --datadir=/var/lib/mysql --target-dir=/xtrabackup_data"
