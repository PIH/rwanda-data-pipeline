#!/bin/bash
#
# Backup MySQL via MySQL Dump and/or Percona XtraBackup
# Requires:  7zip, Docker
#
echoWithDate() {
  echo "$(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

MYSQL_USER=root
MYSQL_PASSWORD=root
MYSQL_DATABASE=openmrs
MYSQL_CONTAINER_NAME=srcdb
MYSQL_DATA_DIR=/home/mseaton/environments/mysql/srcdb/data
MYSQL_RUN_DIR=/home/mseaton/environments/mysql/srcdb/run
BACKUP_FILE_PASSWORD=Test123
BACKUP_DIR=/tmp/rwanda-data-pipeline/backups
BACKUP_FILE_PREFIX=${MYSQL_DATABASE}
MYSQLDUMP_ENABLED=true
PERCONA_XTRABACKUP_ENABLED=true

CURRENT_DATE=$(date '+%Y-%m-%d-%H-%M-%S')

# create the needed directories
mkdir -p ${BACKUP_DIR}

# mysql dump

if [ "$MYSQLDUMP_ENABLED" == "true" ]; then

  BACKUP_FILE=${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_${CURRENT_DATE}.sql.7z
  LATEST_BACKUP_FILE=${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_latest.sql.7z

  if [ -z "${MYSQL_CONTAINER_NAME}" ];
  then
    echoWithDate "Executing mysqldump against database ${MYSQL_DATABASE} and compressing with 7zip to ${BACKUP_FILE}"
    mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} --opt --flush-logs --single-transaction ${MYSQL_DATABASE} 2>/dev/null | 7za a -p${BACKUP_FILE_PASSWORD} -siy -t7z ${BACKUP_FILE} -mx9 2>&1 >/dev/null
  else
    echoWithDate "Executing mysqldump against database ${MYSQL_DATABASE} in container ${MYSQL_CONTAINER_NAME} and compressing with 7zip to ${BACKUP_FILE}"
    docker exec ${MYSQL_CONTAINER_NAME} mysqldump -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} --opt --flush-logs --single-transaction ${MYSQL_DATABASE} 2>/dev/null | 7za a -p${BACKUP_FILE_PASSWORD} -siy -t7z ${BACKUP_FILE} -mx9 2>&1 >/dev/null
  fi

  if [ $? -ne 0 ]; then
    echoWithDate "error: an error occurred during mysqldump and 7zip backup"
    exit 1
  fi

  echoWithDate "Storing MD5 sum in ${BACKUP_FILE}.md5"
  BACKUP_MD5=($(md5sum ${BACKUP_FILE}))
  echo $BACKUP_MD5 > ${BACKUP_FILE}.md5

  echoWithDate "mysqldump and 7zip completed successfully, linking as latest"
  rm -f ${LATEST_BACKUP_FILE} && ln -s ${BACKUP_FILE} ${LATEST_BACKUP_FILE}
  rm -f ${LATEST_BACKUP_FILE}.md5 && ln -s ${BACKUP_FILE}.md5 ${LATEST_BACKUP_FILE}.md5
fi

# percona xtrabackup

if [ "$PERCONA_XTRABACKUP_ENABLED" == "true" ]; then

  XTRABACKUP_DATA_DIR=${BACKUP_DIR}/xtrabackup_data_dir
  BACKUP_FILE=${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_${CURRENT_DATE}.xtrabackup.7z
  LATEST_BACKUP_FILE=${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_latest.xtrabackup.7z

  echoWithDate "Executing percona xtrabackup against database ${MYSQL_DATABASE}"
  rm -fR ${XTRABACKUP_DATA_DIR}

  docker run --rm \
    -v ${MYSQL_DATA_DIR}:/var/lib/mysql \
    -v ${MYSQL_RUN_DIR}:/run/mysqld \
    -v ${XTRABACKUP_DATA_DIR}:/xtrabackup_data \
    --user root \
    percona/percona-xtrabackup:8.0 \
    /bin/bash -c "xtrabackup --backup --datadir=/var/lib/mysql/ --socket=/run/mysqld/mysqld.sock --target-dir=/xtrabackup_data --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} ; xtrabackup --prepare --target-dir=/xtrabackup_data"

  if [ $? -ne 0 ]; then
    echoWithDate "error: an error occurred during percona xtrabackup"
    exit 1
  fi

  echoWithDate "Creating 7z archive of Percona backup"
  7za a ${BACKUP_FILE} -p${BACKUP_FILE_PASSWORD} -y -w${XTRABACKUP_DATA_DIR} ${XTRABACKUP_DATA_DIR}/*

  echoWithDate "Storing MD5 sum in ${BACKUP_FILE}.md5"
  BACKUP_MD5=($(md5sum ${BACKUP_FILE}))
  echo $BACKUP_MD5 > ${BACKUP_FILE}.md5

  echoWithDate "mysqldump and 7zip completed successfully, linking as latest"
  rm -f ${LATEST_BACKUP_FILE} && ln -s ${BACKUP_FILE} ${LATEST_BACKUP_FILE}
  rm -f ${LATEST_BACKUP_FILE}.md5 && ln -s ${BACKUP_FILE}.md5 ${LATEST_BACKUP_FILE}.md5
fi
