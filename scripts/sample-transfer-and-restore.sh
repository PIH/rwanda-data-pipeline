


echoWithDate "Adding backup information to the database"
BACKUP_DATE=$(cat ${DOWNLOAD_DIR}/percona.7z.date)
CURRENT_DATE=$(date '+%Y-%m-%d-%H-%M-%S')
BACKUP_DATE_SQL="insert into global_property (property, property_value, uuid) values ('percona_backup_date', '${BACKUP_DATE}', uuid());"
RESTORE_DATE_SQL="insert into global_property (property, property_value, uuid) values ('percona_restore_date', '${CURRENT_DATE}', uuid());"
if [ -z "${MYSQL_DOCKER_CONTAINER}" ]; then
    mysql -uroot -p${MYSQL_ROOT_PW} -e "${BACKUP_DATE_SQL} ${RESTORE_DATE_SQL}" openmrs
else
    docker exec -i ${MYSQL_DOCKER_CONTAINER} mysql -u root -p${MYSQL_ROOT_PW} -e "${BACKUP_DATE_SQL} ${RESTORE_DATE_SQL}" openmrs
fi
if [ $? -eq 0 ]; then
    echoWithDate "Backup information added successfully"
else
  echoWithDate "An error occurred while adding backup information to the database"
  exit 1
fi

if [ -f "${PRESERVE_TABLES_SQL_FILE}" ]; then
  echoWithDate "Restoring previously dumped contents of ${PRESERVE_TABLES}"
  if [ -z "${MYSQL_DOCKER_CONTAINER}" ]; then
    for TABLE_NAME in ${PRESERVE_TABLES}; do
        echo "Deleting from ${TABLE_NAME}"
        mysql -u root -p${MYSQL_ROOT_PW} openmrs -e "delete from ${TABLE_NAME};"
    done
    mysql -uroot -p${MYSQL_ROOT_PW} openmrs < ${PRESERVE_TABLES_SQL_FILE}
  else
    for TABLE_NAME in ${PRESERVE_TABLES}; do
        echo "Deleting from ${TABLE_NAME}"
        docker exec -i ${MYSQL_DOCKER_CONTAINER} mysql -u root -p${MYSQL_ROOT_PW} openmrs -e "delete from ${TABLE_NAME};"
    done
    docker exec -i ${MYSQL_DOCKER_CONTAINER} mysql -uroot -p${MYSQL_ROOT_PW} openmrs < ${PRESERVE_TABLES_SQL_FILE}
  fi
else
  echoWithDate "No tables configured to preserve"
fi

if [ "${DEIDENTIFY}" == "true" ]; then
  echoWithDate "De-identifying the database"
  if [ -z "${MYSQL_DOCKER_CONTAINER}" ]; then
      echoWithDate "De-identifying the native MySQL installation"
      mysql -uroot -p${MYSQL_ROOT_PW} openmrs < ${PERCONA_RESTORE_DIR}/deidentify-db.sql
  else
      echoWithDate "De-identifying dockerized MySQL installation, container: ${MYSQL_DOCKER_CONTAINER}"
      docker exec -i ${MYSQL_DOCKER_CONTAINER} mysql -uroot -p${MYSQL_ROOT_PW} openmrs < ${PERCONA_RESTORE_DIR}/deidentify-db.sql
  fi
  if [ $? -eq 0 ]; then
      echoWithDate "De-identification successful"
  else
    echoWithDate "An error occurred during de-identification"
    exit 1
  fi
fi

if [ "${CREATE_PETL_USER}" == "true" ]; then
  echoWithDate "Creating PETL user"

  if [ -z "${PETL_MYSQL_USER}" ] || [ -z "${PETL_MYSQL_PASSWORD}" ] || [ -z "${PETL_OPENMRS_DB}" ]; then
    echoWithDate "You must have PETL_MYSQL_USER, PETL_MYSQL_PASSWORD, PETL_OPENMRS_DB environment variables defined to create petl user"
    exit 1
  fi

  SELECT_USER_SQL="select count(*) from mysql.user where user = '${PETL_MYSQL_USER}' and host = '%';"
  CREATE_USER_SQL="create user '${PETL_MYSQL_USER}'@'%' identified by '${PETL_MYSQL_PASSWORD}';";
  GRANT_USER_SQL="grant all privileges on ${PETL_OPENMRS_DB}.* to '${PETL_MYSQL_USER}'@'%';"

  if [ -z "$MYSQL_DOCKER_CONTAINER" ]; then
      echoWithDate "Creating PETL DB user is only currently supported in Docker, exiting"
      exit 1
  else
      echoWithDate "Ensuring MySQL user ${PETL_MYSQL_USER}'@'%' in container ${MYSQL_DOCKER_CONTAINER}"
      EXISTING_USERS=$(docker exec -i ${MYSQL_DOCKER_CONTAINER} mysql -u root -p${MYSQL_ROOT_PW} -N -e "${SELECT_USER_SQL}")
      if [ "${EXISTING_USERS}" -eq 0 ]; then
        echoWithDate "No user found, creating"
        docker exec -i ${MYSQL_DOCKER_CONTAINER} mysql -u root -p${MYSQL_ROOT_PW} -e "${CREATE_USER_SQL} ${GRANT_USER_SQL}"
        if [ $? -eq 0 ]; then
          echoWithDate "Create user successful"
        else
          echoWithDate "Create user failed, exiting"
          exit 1
        fi
      else
        echoWithDate "User already exists, not re-creating"
      fi
  fi

fi

if [ $? -eq 0 ]; then
  # If the script makes it here, copy the latest MD5 and date files into the status directory and delete downloaded files
  echoWithDate "Backup restoration successful, copying most recent backup date and md5 files into status directory"
  cp ${DOWNLOAD_DIR}/percona.7z.date ${STATUS_DATA_DIR}/
  cp ${DOWNLOAD_DIR}/percona.7z.md5 ${STATUS_DATA_DIR}/
  rm -fR ${DOWNLOAD_DIR}
  echoWithDate "Successfully completed"
else
  echoWithDate "Restoration failed"
  exit 1
fi

if [ "${RESTART_OPENMRS}" == "true" ]; then
  echoWithDate "Starting Tomcat"
  service tomcat9 start
fi
