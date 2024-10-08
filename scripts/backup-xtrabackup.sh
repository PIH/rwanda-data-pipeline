#!/bin/bash
#
# Backup MySQL via Percona Xtrabackup to a password-protected 7zip file
#
echoWithDate() {
  echo "backup-xtrabackup $(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

# SET AND CHECK EXPECTED VARIABLES

for i in "$@"
do
case $i in
    --mysqlUser=*)
      RDP_PERCONA_BACKUP_MYSQL_USER="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlPassword=*)
      RDP_PERCONA_BACKUP_MYSQL_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlDataDir=*)
      RDP_PERCONA_BACKUP_MYSQL_DATA_DIR="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlRunDir=*)
      RDP_PERCONA_BACKUP_MYSQL_RUN_DIR="${i#*=}"
      shift # past argument=value
    ;;
    --targetDataDir=*)
      RDP_PERCONA_BACKUP_TARGET_DATA_DIR="${i#*=}"
      shift # past argument=value
    ;;
    --backupFilePassword=*)
      RDP_PERCONA_BACKUP_FILE_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --backupFilePath=*)
      RDP_PERCONA_BACKUP_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    --xtrabackupInstall=*)
      RDP_PERCONA_BACKUP_INSTALL_MODE="${i#*=}"
      shift # past argument=value
    ;;
    *)
      echoWithDate "Unknown input argument specified: $i"
      exit 1
    ;;
esac
done

if [ -z "${RDP_PERCONA_BACKUP_MYSQL_USER}" ]; then
  RDP_PERCONA_BACKUP_MYSQL_USER="root"
  echoWithDate "No RDP_PERCONA_BACKUP_MYSQL_USER specified, defaulting to ${RDP_PERCONA_BACKUP_MYSQL_USER}"
fi
if [ -z "${RDP_PERCONA_BACKUP_MYSQL_PASSWORD}" ]; then
  echoWithDate "You must have RDP_PERCONA_BACKUP_MYSQL_PASSWORD defined to execute this script"; exit 1
fi
if [ -z "${RDP_PERCONA_BACKUP_MYSQL_DATA_DIR}" ]; then
  RDP_PERCONA_BACKUP_MYSQL_DATA_DIR="/var/lib/mysql"
  echoWithDate "No RDP_PERCONA_BACKUP_MYSQL_DATA_DIR specified, defaulting to ${RDP_PERCONA_BACKUP_MYSQL_DATA_DIR}"
fi
if [ -z "${RDP_PERCONA_BACKUP_MYSQL_RUN_DIR}" ]; then
  RDP_PERCONA_BACKUP_MYSQL_RUN_DIR="/var/run/mysqld"
  echoWithDate "No RDP_PERCONA_BACKUP_MYSQL_RUN_DIR specified, defaulting to ${RDP_PERCONA_BACKUP_MYSQL_RUN_DIR}"
fi
if [ -z "${RDP_PERCONA_BACKUP_TARGET_DATA_DIR}" ]; then
  RDP_PERCONA_BACKUP_TARGET_DATA_DIR="/tmp/xtrabackup_data_dir/$(date '+%Y-%m-%d-%H-%M-%S')"
  echoWithDate "No RDP_PERCONA_BACKUP_TARGET_DATA_DIR specified, defaulting to ${RDP_PERCONA_BACKUP_TARGET_DATA_DIR}"
fi
if [ -z "${RDP_PERCONA_BACKUP_FILE_PASSWORD}" ]; then
  echoWithDate "You must have RDP_PERCONA_BACKUP_FILE_PASSWORD defined to execute this script"; exit 1
fi
if [ -z "${RDP_PERCONA_BACKUP_FILE_PATH}" ]; then
  echoWithDate "You must have RDP_PERCONA_BACKUP_FILE_PATH defined to execute this script"; exit 1
fi
if [ -z "${RDP_PERCONA_BACKUP_INSTALL_MODE}" ]; then
  RDP_PERCONA_BACKUP_INSTALL_MODE="docker"
  echoWithDate "No RDP_PERCONA_BACKUP_INSTALL_MODE specified, defaulting to ${RDP_PERCONA_BACKUP_INSTALL_MODE}"
fi

if [ "${RDP_PERCONA_BACKUP_INSTALL_MODE}" = "native" ]; then
  echoWithDate "Executing percona xtrabackup against ${RDP_PERCONA_BACKUP_MYSQL_DATA_DIR} using percona running natively"
  mkdir -p ${RDP_PERCONA_BACKUP_TARGET_DATA_DIR}
  /bin/bash -c "xtrabackup --backup --datadir=${RDP_PERCONA_BACKUP_MYSQL_DATA_DIR} --socket=${RDP_PERCONA_BACKUP_MYSQL_RUN_DIR}/mysqld.sock --target-dir=${RDP_PERCONA_BACKUP_TARGET_DATA_DIR} --user=${RDP_PERCONA_BACKUP_MYSQL_USER} --password=${RDP_PERCONA_BACKUP_MYSQL_PASSWORD} ; xtrabackup --prepare --target-dir=${RDP_PERCONA_BACKUP_TARGET_DATA_DIR}"
else
  if [ -d ${RDP_PERCONA_BACKUP_TARGET_DATA_DIR} ]; then
    echoWithDate "Target directory ${RDP_PERCONA_BACKUP_TARGET_DATA_DIR} must not already exist, exiting"
    exit 1
  fi
  echoWithDate "Executing percona xtrabackup against ${RDP_PERCONA_BACKUP_MYSQL_DATA_DIR} using percona running in docker"
  docker run --rm \
    -v ${RDP_PERCONA_BACKUP_MYSQL_DATA_DIR}:/var/lib/mysql \
    -v ${RDP_PERCONA_BACKUP_MYSQL_RUN_DIR}:/run/mysqld \
    -v ${RDP_PERCONA_BACKUP_TARGET_DATA_DIR}:/xtrabackup_data \
    --user root \
    percona/percona-xtrabackup:8.0 \
    /bin/bash -c "xtrabackup --backup --datadir=/var/lib/mysql/ --socket=/run/mysqld/mysqld.sock --target-dir=/xtrabackup_data --user=${RDP_PERCONA_BACKUP_MYSQL_USER} --password=${RDP_PERCONA_BACKUP_MYSQL_PASSWORD} ; xtrabackup --prepare --target-dir=/xtrabackup_data"
fi

if [ $? -ne 0 ]; then
  echoWithDate "error: an error occurred during percona xtrabackup"
  exit 1
fi

echoWithDate "Percona backup completed successfully"

echoWithDate "Creating 7z archive of Percona backup at ${RDP_PERCONA_BACKUP_FILE_PATH}"
7za a ${RDP_PERCONA_BACKUP_FILE_PATH} -p${RDP_PERCONA_BACKUP_FILE_PASSWORD} -y -w${RDP_PERCONA_BACKUP_TARGET_DATA_DIR} ${RDP_PERCONA_BACKUP_TARGET_DATA_DIR}/*
if [ $? -ne 0 ]; then
  echoWithDate "7z archive failed, exiting"
  exit 1
else
  echoWithDate "7z archive succeeded, removing data directory at ${RDP_PERCONA_BACKUP_TARGET_DATA_DIR}"
  rm -fR ${RDP_PERCONA_BACKUP_TARGET_DATA_DIR}
fi

echoWithDate "Storing MD5 sum in ${RDP_PERCONA_BACKUP_FILE_PATH}.md5"
BACKUP_MD5=($(md5sum ${RDP_PERCONA_BACKUP_FILE_PATH}))
echo $BACKUP_MD5 > ${RDP_PERCONA_BACKUP_FILE_PATH}.md5
