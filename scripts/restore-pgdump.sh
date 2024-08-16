#!/bin/bash
#
# Restore a Percona xtrabackup to a data directory
#
echoWithDate() {
  echo "$(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

# SET AND CHECK EXPECTED VARIABLES

for i in "$@"
do
case $i in
    --postgresUser=*)
      RDP_PGDUMP_RESTORE_USER="${i#*=}"
      shift # past argument=value
    ;;
    --postgresPassword=*)
      RDP_PGDUMP_RESTORE_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --postgresDatabase=*)
      RDP_PGDUMP_RESTORE_DATABASE="${i#*=}"
      shift # past argument=value
    ;;
    --postgresContainerName=*)
      RDP_PGDUMP_RESTORE_CONTAINER_NAME="${i#*=}"
      shift # past argument=value
    ;;
    --postgresContainerPort=*)
      RDP_PGDUMP_RESTORE_CONTAINER_PORT="${i#*=}"
      shift # past argument=value
    ;;
    --postgresContainerImage=*)
      RDP_PGDUMP_RESTORE_CONTAINER_IMAGE="${i#*=}"
      shift # past argument=value
    ;;
    --restoreFilePassword=*)
      RDP_PGDUMP_RESTORE_FILE_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --restoreFilePath=*)
      RDP_PGDUMP_RESTORE_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    --restoreMd5FilePath=*)
      RDP_PGDUMP_RESTORE_MD5_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    --latestMd5FilePath=*)
      RDP_PGDUMP_RESTORE_LATEST_MD5_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    *)
      echoWithDate "Unknown input argument specified"
      exit 1
    ;;
esac
done

##### Validate backup file prior to loading it in

# Validate and compute MD5 of the backup to restore
if [ ! -z "${RDP_PGDUMP_RESTORE_FILE_PATH}" ]; then
  if [ -f ${RDP_PGDUMP_RESTORE_FILE_PATH} ]; then
      ACTUAL_RESTORE_MD5=($(md5sum ${RDP_PGDUMP_RESTORE_FILE_PATH}))
      echoWithDate "Actual restore MD5: ${ACTUAL_RESTORE_MD5}"
  else
    echoWithDate "Specified restoreFilePath of ${RDP_PGDUMP_RESTORE_FILE_PATH} not found"; exit 1
  fi
else
  echoWithDate "No restoreFilePath specified"; exit 1
fi

# Validate and read in the expected MD5 of the new backup to restore and ensure it matches the actual md5
if [ ! -z "${RDP_PGDUMP_RESTORE_MD5_FILE_PATH}" ]; then
  if [ -f ${RDP_PGDUMP_RESTORE_MD5_FILE_PATH} ]; then
      EXPECTED_RESTORE_MD5=$(cat ${RDP_PGDUMP_RESTORE_MD5_FILE_PATH})
      echoWithDate "Restore backup MD5: ${RESTORE_MD5}"
      if [[ "$ACTUAL_RESTORE_MD5" != *"$EXPECTED_RESTORE_MD5"* ]]; then
          echoWithDate "The expected md5 does not match the actual md5"; exit 1
      fi
  else
    echoWithDate "Specified restoreMd5FilePath of ${RDP_PGDUMP_RESTORE_FILE_PATH} not found"; exit 1
  fi
fi

# Validate and retrieve the most recently restored MD5, if available, and check if it matches the new md5
if [ ! -z "${RDP_PGDUMP_RESTORE_LATEST_MD5_FILE_PATH}" ]; then
  if [ -f ${RDP_PGDUMP_RESTORE_LATEST_MD5_FILE_PATH} ]; then
    LAST_BACKUP_MD5=$(cat ${RDP_PGDUMP_RESTORE_LATEST_MD5_FILE_PATH})
    echo "Found last backup MD5: ${LAST_BACKUP_MD5}"
    if [ "$EXPECTED_RESTORE_MD5" = "$LAST_BACKUP_MD5" ]; then
        echoWithDate "The last backup MD5 matches the new backup MD5, skipping restoration"
        exit 0
    fi
  fi
fi

# If we make it here, then we have a new, valid backup file to restore

# Extract the backup
RDP_PGDUMP_RESTORE_UNZIPPED_FILE_PATH="${RDP_PGDUMP_RESTORE_FILE_PATH}.sql"
echoWithDate "Extracting the backup to ${RDP_PGDUMP_RESTORE_UNZIPPED_FILE_PATH}"
7za x ${RDP_PGDUMP_RESTORE_FILE_PATH} -p${RDP_PGDUMP_RESTORE_FILE_PASSWORD} -y -so > ${RDP_PGDUMP_RESTORE_UNZIPPED_FILE_PATH}
if [ $? -ne 0 ]; then
    echoWithDate "Extraction failed, exiting"
    exit 1
fi

# If there are no errors at this point, recreate container if needed and drop existing DB if needed

if [ -z "${RDP_PGDUMP_RESTORE_CONTAINER_NAME}" ]; then
  echoWithDate "Running native postgres. Dropping existing database ${RDP_PGDUMP_RESTORE_DATABASE} if it exists"
  psql -U ${RDP_PGDUMP_RESTORE_USER} -c "drop database if exists ${RDP_PGDUMP_RESTORE_DATABASE}"
  echoWithDate "Creating database ${RDP_PGDUMP_RESTORE_DATABASE}"
  psql -U ${RDP_PGDUMP_RESTORE_USER} -c "create database ${RDP_PGDUMP_RESTORE_DATABASE}"
  echoWithDate "Importing backup into postgres"
  psql -U ${RDP_PGDUMP_RESTORE_USER} ${RDP_PGDUMP_RESTORE_DATABASE} < ${RDP_PGDUMP_RESTORE_UNZIPPED_FILE_PATH}
else
  echoWithDate "Recreating Postgres container: ${RDP_PGDUMP_RESTORE_CONTAINER_NAME}"
  docker stop ${RDP_PGDUMP_RESTORE_CONTAINER_NAME} || true
  docker rm ${RDP_PGDUMP_RESTORE_CONTAINER_NAME} || true
  docker run --name ${RDP_PGDUMP_RESTORE_CONTAINER_NAME} \
    --restart always \
    -e POSTGRES_DB=${RDP_PGDUMP_RESTORE_DATABASE} \
    -e POSTGRES_USER=${RDP_PGDUMP_RESTORE_USER} \
    -e POSTGRES_PASSWORD=${RDP_PGDUMP_RESTORE_PASSWORD} \
    -p "${RDP_PGDUMP_RESTORE_CONTAINER_PORT}:5432" \
    -d ${RDP_PGDUMP_RESTORE_CONTAINER_IMAGE}
  echoWithDate "Importing backup into postgres container"
  sleep 10
  docker exec -i ${RDP_PGDUMP_RESTORE_CONTAINER_NAME} /bin/bash -c "psql -U ${RDP_PGDUMP_RESTORE_USER} ${RDP_PGDUMP_RESTORE_DATABASE}" < ${RDP_PGDUMP_RESTORE_UNZIPPED_FILE_PATH}
fi

if [ $? -eq 0 ]; then
    echoWithDate "Backup imported successfully"
else
    echoWithDate "Backup import failed, exiting"
    exit 1
fi

# If the script makes it here, save the new MD5 as the latest MD5
echoWithDate "Backup restoration successful"
if [ ! -z "${RDP_PGDUMP_RESTORE_MD5_FILE_PATH}" ]; then
  if [ ! -z "${RDP_PGDUMP_RESTORE_LATEST_MD5_FILE_PATH}" ]; then
    cp ${RDP_PGDUMP_RESTORE_MD5_FILE_PATH}  ${RDP_PGDUMP_RESTORE_LATEST_MD5_FILE_PATH}
    echoWithDate "Latest backup md5 stored in ${RDP_PGDUMP_RESTORE_LATEST_MD5_FILE_PATH}"
  fi
fi
