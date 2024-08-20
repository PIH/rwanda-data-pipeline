#!/bin/bash
#
# Backup MySQL via MySQL Dump to a password-protected 7zip file
#
echoWithDate() {
  echo "backup-mysqldump $(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

# SET AND CHECK EXPECTED ENVIRONMENT VARIABLES

for i in "$@"
do
case $i in
    --mysqlUser=*)
      RDP_MYSQLDUMP_USER="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlPassword=*)
      RDP_MYSQLDUMP_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlDatabase=*)
      RDP_MYSQLDUMP_DATABASE="${i#*=}"
      shift # past argument=value
    ;;
    --mysqlContainerName=*)
      RDP_MYSQLDUMP_CONTAINER_NAME="${i#*=}"
      shift # past argument=value
    ;;
    --backupFilePassword=*)
      RDP_MYSQLDUMP_FILE_PASSWORD="${i#*=}"
      shift # past argument=value
    ;;
    --backupFilePath=*)
      RDP_MYSQLDUMP_FILE_PATH="${i#*=}"
      shift # past argument=value
    ;;
    *)
      echoWithDate "Unknown input argument specified: $i"
      exit 1
    ;;
esac
done

if [ -z "${RDP_MYSQLDUMP_USER}" ]; then
  RDP_MYSQLDUMP_USER="root"
  echoWithDate "No RDP_MYSQLDUMP_USER specified, defaulting to ${RDP_MYSQLDUMP_USER}"
fi
if [ -z "${RDP_MYSQLDUMP_PASSWORD}" ]; then
  echoWithDate "You must have RDP_MYSQLDUMP_PASSWORD defined to execute this script"; exit 1
fi
if [ -z "${RDP_MYSQLDUMP_DATABASE}" ]; then
  echoWithDate "You must have RDP_MYSQLDUMP_DATABASE defined to execute this script"; exit 1
fi
if [ -z "${RDP_MYSQLDUMP_CONTAINER_NAME}" ]; then
  echoWithDate "No container name specified, executing against native MySQL installation"
fi
if [ -z "${RDP_MYSQLDUMP_FILE_PASSWORD}" ]; then
  echoWithDate "You must have RDP_MYSQLDUMP_FILE_PASSWORD defined to execute this script"; exit 1
fi
if [ -z "${RDP_MYSQLDUMP_FILE_PATH}" ]; then
  echoWithDate "You must have RDP_MYSQLDUMP_FILE_PATH defined to execute this script"; exit 1
fi

if [ -z "${RDP_MYSQLDUMP_CONTAINER_NAME}" ];
then
  echoWithDate "Executing mysqldump against database ${RDP_MYSQLDUMP_DATABASE} and compressing with 7zip to ${RDP_MYSQLDUMP_FILE_PATH}"
  mysqldump -u${RDP_MYSQLDUMP_USER} -p${RDP_MYSQLDUMP_PASSWORD} --opt --flush-logs --single-transaction ${RDP_MYSQLDUMP_DATABASE} 2>/dev/null | 7za a -p${RDP_MYSQLDUMP_FILE_PASSWORD} -siy -t7z ${RDP_MYSQLDUMP_FILE_PATH} -mx9 2>&1 >/dev/null
else
  echoWithDate "Executing mysqldump against database ${RDP_MYSQLDUMP_DATABASE} in container ${RDP_MYSQLDUMP_CONTAINER_NAME} and compressing with 7zip to ${RDP_MYSQLDUMP_FILE_PATH}"
  docker exec ${RDP_MYSQLDUMP_CONTAINER_NAME} mysqldump -u ${RDP_MYSQLDUMP_USER} --password=${RDP_MYSQLDUMP_PASSWORD} --opt --flush-logs --single-transaction ${RDP_MYSQLDUMP_DATABASE} 2>/dev/null | 7za a -p${RDP_MYSQLDUMP_FILE_PASSWORD} -siy -t7z ${RDP_MYSQLDUMP_FILE_PATH} -mx9 2>&1 >/dev/null
fi

if [ $? -ne 0 ]; then
  echoWithDate "error: an error occurred during mysqldump and 7zip backup"
  exit 1
fi

echoWithDate "mysqldump and 7zip completed successfully"

echoWithDate "Storing MD5 sum in ${RDP_MYSQLDUMP_FILE_PATH}.md5"
BACKUP_MD5=($(md5sum ${RDP_MYSQLDUMP_FILE_PATH}))
echo $BACKUP_MD5 > ${RDP_MYSQLDUMP_FILE_PATH}.md5
