#!/bin/bash
#
# Backup Postgres via pg_dump to a password-protected 7zip file
#
echoWithDate() {
  echo "backup-pgdump $(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

# SET AND CHECK EXPECTED ENVIRONMENT VARIABLES

for i in "$@"
do
case $i in
    --postgresUser=*)
      RDP_PGDUMP_USER="${i#*=}"
      shift # past argument=value
    ;;
    --postgresDatabase=*)
      RDP_PGDUMP_DATABASE="${i#*=}"
      shift # past argument=value
    ;;
    --postgresContainerName=*)
      RDP_PGDUMP_CONTAINER_NAME="${i#*=}"
      shift # past argument=value
    ;;
    --backupFilePassword=*)
      RDP_PGDUMP_FILE_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --backupFilePath=*)
      RDP_PGDUMP_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    *)
      echoWithDate "Unknown input argument specified: $i"
      exit 1
    ;;
esac
done

if [ -z "${RDP_PGDUMP_USER}" ]; then
  echoWithDate "You must have RDP_PGDUMP_USER defined to execute this script"; exit 1
fi
if [ -z "${RDP_PGDUMP_DATABASE}" ]; then
  echoWithDate "You must have RDP_PGDUMP_DATABASE defined to execute this script"; exit 1
fi
if [ -z "${RDP_PGDUMP_CONTAINER_NAME}" ]; then
  echoWithDate "No container name specified, executing against native Postgres installation"
fi
if [ -z "${RDP_PGDUMP_FILE_PASSWORD}" ]; then
  echoWithDate "You must have RDP_PGDUMP_FILE_PASSWORD defined to execute this script"; exit 1
fi
if [ -z "${RDP_PGDUMP_FILE_PATH}" ]; then
  echoWithDate "You must have RDP_PGDUMP_FILE_PATH defined to execute this script"; exit 1
fi

if [ -z "${RDP_PGDUMP_CONTAINER_NAME}" ];
then
  echoWithDate "Executing pg_dump against database ${RDP_PGDUMP_DATABASE} and compressing with 7zip to ${RDP_PGDUMP_FILE_PATH}"
  sudo su - ${RDP_PGDUMP_USER} -c "pg_dump -U ${RDP_PGDUMP_USER} -O -x ${RDP_PGDUMP_DATABASE} 2>/dev/null" | 7za a -p${RDP_PGDUMP_FILE_PASSWORD} -siy -t7z ${RDP_PGDUMP_FILE_PATH} -mx5 2>&1 >/dev/null
else
  echoWithDate "Executing pg_dump against database ${RDP_PGDUMP_DATABASE} in container ${RDP_PGDUMP_CONTAINER_NAME} and compressing with 7zip to ${RDP_PGDUMP_FILE_PATH}"
  docker exec ${RDP_PGDUMP_CONTAINER_NAME} pg_dump -U ${RDP_PGDUMP_USER} -O -x ${RDP_PGDUMP_DATABASE} 2>/dev/null | 7za a -p${RDP_PGDUMP_FILE_PASSWORD} -siy -t7z ${RDP_PGDUMP_FILE_PATH} -mx5 2>&1 >/dev/null
fi

if [ $? -ne 0 ]; then
  echoWithDate "error: an error occurred during pg_dump and 7zip backup"
  exit 1
fi

echoWithDate "pg_dump and 7zip completed successfully"

echoWithDate "Storing md5 sum in ${RDP_PGDUMP_FILE_PATH}.md5"
BACKUP_MD5=($(md5sum ${RDP_PGDUMP_FILE_PATH}))
echo $BACKUP_MD5 > ${RDP_PGDUMP_FILE_PATH}.md5
