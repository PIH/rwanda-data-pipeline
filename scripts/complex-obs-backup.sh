#!/bin/bash
#
# Backup OpenMRS complex obs directory
# Requires:  7zip
#
echoWithDate() {
  echo "$(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

COMPLEX_OBS_DIR="/home/mseaton/openmrs/humci/complex_obs"
BACKUP_FILE_PASSWORD=Test123
BACKUP_DIR=/tmp/rwanda-data-pipeline/backups
BACKUP_FILE_PREFIX=openmrs

CURRENT_DATE=$(date '+%Y-%m-%d-%H-%M-%S')

BACKUP_FILE=${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_${CURRENT_DATE}.complex_obs.7z
LATEST_BACKUP_FILE=${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_latest.complex_obs.7z

7za a ${BACKUP_FILE} -p${BACKUP_FILE_PASSWORD} -y -w${COMPLEX_OBS_DIR} ${COMPLEX_OBS_DIR}/*

echoWithDate "Storing MD5 sum in ${BACKUP_FILE}.md5"
BACKUP_MD5=($(md5sum ${BACKUP_FILE}))
echo $BACKUP_MD5 > ${BACKUP_FILE}.md5

echoWithDate "mysqldump and 7zip completed successfully, linking as latest"
rm -f ${LATEST_BACKUP_FILE} && ln -s ${BACKUP_FILE} ${LATEST_BACKUP_FILE}
rm -f ${LATEST_BACKUP_FILE}.md5 && ln -s ${BACKUP_FILE}.md5 ${LATEST_BACKUP_FILE}.md5