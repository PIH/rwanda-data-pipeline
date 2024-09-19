#!/bin/bash
#
# Restore a Percona xtrabackup to a data directory
#
echoWithDate() {
  echo "restore-xtrabackup $(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

# SET AND CHECK EXPECTED VARIABLES

for i in "$@"
do
case $i in
    --mysqlRootPassword=*)
      RDP_PERCONA_RESTORE_MYSQL_ROOT_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlContainerName=*)
      RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlContainerImage=*)
      RDP_PERCONA_RESTORE_MYSQL_IMAGE="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlContainerPort=*)
      RDP_PERCONA_RESTORE_MYSQL_CONTAINER_PORT="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlContainerTimezone=*)
      RDP_PERCONA_RESTORE_MYSQL_CONTAINER_TIMEZONE="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlDataDir=*)
      RDP_PERCONA_RESTORE_MYSQL_DATA_DIR="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlRunDir=*)
      RDP_PERCONA_RESTORE_MYSQL_RUN_DIR="${i#*=}"
      shift # past argument=value
    ;;
    --restoreFilePassword=*)
      RDP_PERCONA_RESTORE_FILE_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --restoreFilePath=*)
      RDP_PERCONA_RESTORE_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    --restoreMd5FilePath=*)
      RDP_PERCONA_RESTORE_MD5_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    --latestMd5FilePath=*)
      RDP_PERCONA_RESTORE_LATEST_MD5_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    --xtrabackupInstall=*)
      RDP_PERCONA_RESTORE_INSTALL_MODE="${i#*=}"
      shift # past argument=value
    ;;
    *)
      echoWithDate "Unknown input argument specified: $i"
      exit 1
    ;;
esac
done

if [ -z "${RDP_PERCONA_RESTORE_MYSQL_IMAGE}" ]; then
  RDP_PERCONA_RESTORE_MYSQL_IMAGE="library/mysql:8.0"
  echoWithDate "No RDP_PERCONA_RESTORE_MYSQL_IMAGE specified, defaulting to ${RDP_PERCONA_RESTORE_MYSQL_IMAGE}"
fi

if [ -z "${RDP_PERCONA_RESTORE_INSTALL_MODE}" ]; then
  RDP_PERCONA_RESTORE_INSTALL_MODE="docker"
  echoWithDate "No RDP_PERCONA_RESTORE_INSTALL_MODE specified, defaulting to ${RDP_PERCONA_RESTORE_INSTALL_MODE}"
fi

echoWithDate "Executing restore-xtrabackup"

##### Validate backup file prior to loading it in

# Validate and compute MD5 of the backup to restore
if [ ! -z "${RDP_PERCONA_RESTORE_FILE_PATH}" ]; then
  if [ -f ${RDP_PERCONA_RESTORE_FILE_PATH} ]; then
      ACTUAL_RESTORE_MD5=($(md5sum ${RDP_PERCONA_RESTORE_FILE_PATH}))
      echoWithDate "Actual restore MD5: ${ACTUAL_RESTORE_MD5}"
  else
    echoWithDate "Specified restoreFilePath of ${RDP_PERCONA_RESTORE_FILE_PATH} not found"; exit 1
  fi
else
  echoWithDate "No restoreFilePath specified"; exit 1
fi

# Validate and read in the expected MD5 of the new backup to restore and ensure it matches the actual md5
if [ ! -z "${RDP_PERCONA_RESTORE_MD5_FILE_PATH}" ]; then
  if [ -f ${RDP_PERCONA_RESTORE_MD5_FILE_PATH} ]; then
      EXPECTED_RESTORE_MD5=$(cat ${RDP_PERCONA_RESTORE_MD5_FILE_PATH})
      echoWithDate "Restore backup MD5: ${RESTORE_MD5}"
      if [[ "$ACTUAL_RESTORE_MD5" != *"$EXPECTED_RESTORE_MD5"* ]]; then
          echoWithDate "The expected md5 does not match the actual md5"; exit 1
      fi
  else
    echoWithDate "Specified restoreMd5FilePath of ${RDP_PERCONA_RESTORE_FILE_PATH} not found"; exit 1
  fi
fi

# Validate and retrieve the most recently restored MD5, if available, and check if it matches the new md5
if [ ! -z "${RDP_PERCONA_RESTORE_LATEST_MD5_FILE_PATH}" ]; then
  if [ -f ${RDP_PERCONA_RESTORE_LATEST_MD5_FILE_PATH} ]; then
    LAST_BACKUP_MD5=$(cat ${RDP_PERCONA_RESTORE_LATEST_MD5_FILE_PATH})
    echo "Found last backup MD5: ${LAST_BACKUP_MD5}"
    if [ "$EXPECTED_RESTORE_MD5" = "$LAST_BACKUP_MD5" ]; then
        echoWithDate "The last backup MD5 matches the new backup MD5, skipping restoration"
        exit 0
    fi
  fi
fi

# If we make it here, then we have a new, valid backup file to restore

# Validate additional input arguments
if [ -z "${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}" ]; then
  echo "No mysql data directory specified, exiting"; exit 1
else
  if [ ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR} == '/' ]; then
    echo "Invalid mysql data directory specified, exiting"; exit 1
  fi
  echo "MySQL data directory specified at ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}.  This will be recreated."
fi

if [ -z "${RDP_PERCONA_RESTORE_MYSQL_RUN_DIR}" ]; then
  echo "No mysql run directory specified, exiting"; exit 1
fi

# Extract the percona backup
RDP_PERCONA_EXTRACT_DATA_DIR="/tmp/xtrabackup_restore_data_dir/$(date '+%Y-%m-%d-%H-%M-%S')"
echoWithDate "Extracting the percona backup to ${RDP_PERCONA_EXTRACT_DATA_DIR}"
7za x ${RDP_PERCONA_RESTORE_FILE_PATH} -p${RDP_PERCONA_RESTORE_FILE_PASSWORD} -y -o${RDP_PERCONA_EXTRACT_DATA_DIR}
if [ $? -ne 0 ]; then
    echoWithDate "Extraction failed, exiting"
    exit 1
fi

# If there are no errors at this point, recreate the databases

echoWithDate "Stopping the existing MySQL instance"
if [ -z "${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME}" ]; then
  echoWithDate "Stopping native mysql"
  service mysql stop
else
  echoWithDate "Stopping and removing MySQL container: ${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME}"
  docker stop ${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME} || true
  docker rm ${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME} || true
fi

echoWithDate "Re-creating existing data directory: ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}"

mkdir -p ${RDP_PERCONA_RESTORE_MYSQL_RUN_DIR}
mkdir -p ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}
rm -fR ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}

if [ "${RDP_PERCONA_RESTORE_INSTALL_MODE}" = "native" ]; then
  echoWithDate "Restoring Percona Backup to ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR} using percona running natively"
  /bin/bash -c "xtrabackup --move-back --datadir=${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR} --target-dir=${RDP_PERCONA_EXTRACT_DATA_DIR}"
else
  echoWithDate "Restoring Percona Backup to ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR} using percona running in docker"
  docker run --rm \
    -v ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}:/var/lib/mysql \
    -v ${RDP_PERCONA_EXTRACT_DATA_DIR}:/xtrabackup_data \
    --user root \
    percona/percona-xtrabackup:8.0 \
    /bin/bash -c "xtrabackup --move-back --datadir=/var/lib/mysql --target-dir=/xtrabackup_data"
fi

if [ -z "${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME}" ]; then
  echoWithDate "Changing permissions of data directory"
  chown -R mysql:mysql ${RDP_PERCONA_RESTORE_MYSQL_RUN_DIR}
  chown -R mysql:mysql ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}
  echoWithDate "Starting native mysql"
  service mysql start
else
  echoWithDate "Changing permissions of data directory"
  chown -R 999:999 ${RDP_PERCONA_RESTORE_MYSQL_RUN_DIR}
  chown -R 999:999 ${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}

  echoWithDate "Initializing new MySQL container named ${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME}"

  if [ -z "${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_TIMEZONE}" ]; then
    RDP_PERCONA_RESTORE_MYSQL_CONTAINER_TIMEZONE="America/New_York"
  fi

  if [ -z "${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_PORT}" ]; then
    RDP_PERCONA_RESTORE_MYSQL_CONTAINER_PORT="3306"
  fi

  RDP_PERCONA_RESTORE_MYSQL_CONTAINER_BUFFER_POOL_SIZE="128M"

  docker run --name ${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME} \
    --restart always \
    -e MYSQL_ROOT_PASSWORD=${RDP_PERCONA_RESTORE_MYSQL_ROOT_PASSWORD} \
    -e TZ=${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_TIMEZONE} \
    -v "${RDP_PERCONA_RESTORE_MYSQL_DATA_DIR}:/var/lib/mysql" \
    -v "${RDP_PERCONA_RESTORE_MYSQL_RUN_DIR}:/var/run/mysqld" \
    -p "${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_PORT}:3306" \
    -d ${RDP_PERCONA_RESTORE_MYSQL_IMAGE} \
      --character-set-server=utf8 \
      --collation-server=utf8_general_ci \
      --max_allowed_packet=1G \
      --innodb-buffer-pool-size=${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_BUFFER_POOL_SIZE} \
      --user=mysql \
      --server-id=1 \
      --log-bin=mysql-bin \
      --binlog_format=ROW \
      --max_binlog_size=100M \
      --default-authentication-plugin=mysql_native_password \
      --sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION

    echo "Stopping Docker container to preserve memory"
    docker stop ${RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME}
fi

if [ $? -eq 0 ]; then
    echoWithDate "Backup restoration succeeded"
else
    echoWithDate "Backup restoration failed, exiting"
    exit 1
fi

# If the script makes it here, save the new MD5 as the latest MD5
if [ ! -z "${RDP_PERCONA_RESTORE_MD5_FILE_PATH}" ]; then
  if [ ! -z "${RDP_PERCONA_RESTORE_LATEST_MD5_FILE_PATH}" ]; then
    cp ${RDP_PERCONA_RESTORE_MD5_FILE_PATH}  ${RDP_PERCONA_RESTORE_LATEST_MD5_FILE_PATH}
    echoWithDate "Latest backup md5 stored in ${RDP_PERCONA_RESTORE_LATEST_MD5_FILE_PATH}"
  fi
fi
