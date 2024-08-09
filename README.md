Data pipeline to support Rwanda national warehouse initiative
=======================

# Backup Scripts

## backup.sh

This is intended to be an entrypoint for backups, where different backup methods can be toggled on or off as needed.
One can indicate which backups should be executed with the following variables:

```bash
export RDP_MYSQLDUMP_ENABLED=true
export RDP_PERCONA_BACKUP_ENABLED=true
```

Beyond these, any additional variable requirements are based on which of the methods are enabled.  See the specific methods documented below for what is required.
All of these variables are typically stored in an environment variable file that is passed as an argument to the backup.sh script:

```bash
sudo ./backup.sh -e ./backup.env.example
```

## backup-mysqldump.sh

This backs up a mysql database using mysqldump and outputs the resulting sql in a password-protected 7z archive.
This requires several variables that can either be set as environment variables or passed as input arguments:

| ENVIRONMENT_VARIABLE             | INPUT ARGUMENT     | Usage                                                    |
|:---------------------------------|:-------------------|:---------------------------------------------------------|
| RDP_MYSQLDUMP_USER               | mysqlUser          | The user to use to connect to MySQL.  Defaults to `root` |
| RDP_MYSQLDUMP_PASSWORD           | mysqlPassword      | The password to use to connect to MySQL.                 |
| RDP_MYSQLDUMP_DATABASE           | mysqlDatabase      | The name of the database to dump                         |
| RDP_MYSQLDUMP_CONTAINER_NAME     | mysqlContainerName | If MySQL is running in Docker, the name of the container |
| RDP_MYSQLDUMP_FILE_PASSWORD      | backupFilePassword | The password to use when 7zipping the backup file        |
| RDP_MYSQLDUMP_FILE_PATH          | backupFilePath     | The path to the backup file to output from 7zip          |

Running with input arguments can be done as follows:

```bash
sudo ./backup-mysqldump.sh \
  --mysqlUser=root \
  --mysqlPassword=root \
  --mysqlDatabase=openmrs \
  --mysqlContainerName=mysql8 \
  --backupFilePassword=Test1234 \
  --backupFilePath=/tmp/srcdb.sql.7z
```

Running with environment variables can be done directly, but is most typically done via an environment file.  See [backup.sh](./scripts/backup.sh) as an example.

## backup-xtrabackup.sh

This backs up a mysql database using the Percona xtrabackup utility and outputs the resulting data in a password-protected 7z archive.
This requires several variables that can either be set as environment variables or passed as input arguments:

| ENVIRONMENT_VARIABLE               | INPUT ARGUMENT     | Usage                                                                                                      |
|:-----------------------------------|:-------------------|:-----------------------------------------------------------------------------------------------------------|
| RDP_PERCONA_BACKUP_MYSQL_USER      | mysqlUser          | The user to use to connect to MySQL.  Defaults to `root`                                                   |
| RDP_PERCONA_BACKUP_MYSQL_PASSWORD  | mysqlPassword      | The password to use to connect to MySQL.                                                                   |
| RDP_PERCONA_BACKUP_MYSQL_DATA_DIR  | mysqlDataDir       | The path to the MySQL data directory.  Defaults to `/var/lib/mysql`                                        |
| RDP_PERCONA_BACKUP_MYSQL_RUN_DIR   | mysqlRunDir        | The path to the MySQL run directory.  Defaults to `/var/run/mysqld`                                        |
| RDP_PERCONA_BACKUP_TARGET_DATA_DIR | targetDataDir      | The directory in which the backup is prepared.  This must not already exist.  Defaults to a temp directory |
| RDP_PERCONA_BACKUP_FILE_PASSWORD   | backupFilePassword | The password to use when 7zipping the backup file                                                          |
| RDP_PERCONA_BACKUP_FILE_PATH       | backupFilePath     | The path to the backup file to output from 7zip                                                            |

Running with input arguments can be done as follows:

```bash
sudo ./backup-xtrabackup.sh \
  --mysqlUser=root \
  --mysqlPassword=root \
  --backupFilePassword=Test1234 \
  --backupFilePath=/tmp/srcdb.xtrabackup.7z
```
Running with environment variables can be done directly, but is most typically done via an environment file.  See [backup.sh](./scripts/backup.sh) as an example.

## backup-pgdump.sh

This backs up a postgres database using pg_dump and outputs the resulting sql in a password-protected 7z archive.
This requires several variables that can either be set as environment variables or passed as input arguments:

| ENVIRONMENT_VARIABLE      | INPUT ARGUMENT        | Usage                                                       |
|:--------------------------|:----------------------|:------------------------------------------------------------|
| RDP_PGDUMP_USER           | postgresUser          | The user to use to connect to Postgres                      |
| RDP_PGDUMP_DATABASE       | postgresDatabase      | The name of the database to dump                            |
| RDP_PGDUMP_CONTAINER_NAME | postgresContainerName | If Postgres is running in Docker, the name of the container |
| RDP_PGDUMP_FILE_PASSWORD  | backupFilePassword    | The password to use when 7zipping the backup file           |
| RDP_PGDUMP_FILE_PATH      | backupFilePath        | The path to the backup file to output from 7zip             |

Running with input arguments can be done as follows:

```bash
sudo ./backup-pgdump.sh \
  --postgresUser=dhis \
  --postgresDatabase=dhis \
  --postgresContainerName=postgres-dhis \
  --backupFilePassword=Test1234 \
  --backupFilePath=/tmp/postgres.pgdump.7z
```

Running with environment variables can be done directly, but is most typically done via an environment file.

# Transfer Scripts

## transfer-rsync.sh

This is just a thin wrapper around the rsync command, usage is as follows:

```bash
sudo ./transfer-rsync.sh --sourceFile=/tmp/srcdb.xtrabackup.7z --targetFile=username@remote_host:/tmp/srcdb.xtrabackup.7z
sudo ./transfer-rsync.sh --sourceFile=/tmp/srcdb/srcdb.xtrabackup.7z.md5 --targetFile=username@remote_host:/tmp/srcdb.xtrabackup.7z.md5
```

One could rsync the entire directory, but doing it file-by-file ensures that the backup file is copied over before the md5 file is copied over, which is the proper order to maintain.

# Restore Scripts

# restore-xtrabackup.sh

This restores a mysql database that was previously backed up using the [backup-xtrabackup.sh](./scripts/backup-xtrabackup.sh).
This restoration is done into a MySQL 8 instance.  If a container name is specified, this will create a new MySQL 8 docker container (and deleting any existing container) with this name.
A new MySQL data directory will be created based on the given input parameters and any existing directory at this path will be deleted.
This requires several variables that can either be set as environment variables or passed as input arguments:

| ENVIRONMENT_VARIABLE                         | INPUT ARGUMENT         | Usage                                                                                                                                           |
|:---------------------------------------------|:-----------------------|:------------------------------------------------------------------------------------------------------------------------------------------------|
| RDP_PERCONA_RESTORE_MYSQL_ROOT_PASSWORD      | mysqlRootPassword      | The root password of the MySQL DB to restore                                                                                                    |
| RDP_PERCONA_RESTORE_MYSQL_CONTAINER_NAME     | mysqlContainerName     | If restoring into a Docker container, this is the name of the container                                                                         |
| RDP_PERCONA_RESTORE_MYSQL_CONTAINER_PORT     | mysqlContainerPort     | If restoring into a Docker container, this is the port to listen on                                                                             |
| RDP_PERCONA_RESTORE_MYSQL_CONTAINER_TIMEZONE | mysqlContainerTimezone | If restoring into a Docker container, this is the timezone to set for MySQL                                                                     |
| RDP_PERCONA_RESTORE_MYSQL_DATA_DIR           | mysqlDataDir           | The path to the MySQL data directory. **This will be deleted and recreated, set with caution.**                                                 |
| RDP_PERCONA_RESTORE_MYSQL_RUN_DIR            | mysqlRunDir            | The path to the MySQL run directory. This will be created if it does not exist.  If it exists, it must have specific ownership and permissions. |
| RDP_PERCONA_RESTORE_FILE_PASSWORD            | restoreFilePassword    | The password to use when extraction the 7z backup file                                                                                          |
| RDP_PERCONA_RESTORE_FILE_PATH                | restoreFilePath        | The path to the backup file to restore. This is expected to be a 7z backup as created by the xtrabackup backup script.                          |
| RDP_PERCONA_RESTORE_MD5_FILE_PATH            | restoreMd5FilePath     | The path to the md5 file of backup file to restore. This is expected to be the md5 as created by the xtrabackup backup script.                  |
| RDP_PERCONA_RESTORE_LATEST_MD5_FILE_PATH     | latestMd5FilePath      | The path to store the md5 of the latest successful restoration. This is used to ensure the restore file is new before restoring.                |

```bash
 sudo ./restore-xtrabackup.sh \
  --mysqlRootPassword=root \
  --mysqlContainerName=rdp_openmrs_target \
  --mysqlContainerPort=3218 \
  --mysqlContainerTimezone=Africa/Kigali \
  --mysqlDataDir=/opt/rdp/databases/openmrs/data \
  --mysqlRunDir=/opt/rdp/databases/openmrs/run \
  --restoreFilePassword=Test1234 \
  --restoreFilePath=/opt/rdp/transfers/openmrs.xtrabackup.7z \
  --restoreMd5FilePath=/opt/rdp/transfers/openmrs.xtrabackup.7z.md5 \
  --latestMd5FilePath=/opt/rdp/databases/openmrs/latest.md5
```

# restore-pgdump.sh

This restores a postgres database that was previously backed up using the [backup-pgdump.sh](./scripts/backup-pgdump.sh).
This restoration is done into a postgres instance.  If a container name is specified, this will create a new postgres container (and deleting any existing container) with this name.
This requires several variables that can either be set as environment variables or passed as input arguments:

| ENVIRONMENT_VARIABLE                    | INPUT ARGUMENT         | Usage                                                                                                                                  |
|:----------------------------------------|:-----------------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| RDP_PGDUMP_RESTORE_USER                 | postgresUser           | The user to use to connect to postgres                                                                                                 |
| RDP_PGDUMP_RESTORE_PASSWORD             | postgresPassword       | The password of the user for postgres, used if creating a container                                                                    |
| RDP_PGDUMP_RESTORE_DATABASE             | postgresDatabase       | The database name to create in postgres.  This will be dropped it if already exists.                                                   |
| RDP_PGDUMP_RESTORE_CONTAINER_NAME       | postgresContainerName  | If restoring into a Docker container, this is the name of the container.If a container with the same name exists, it will be recreated |
| RDP_PGDUMP_RESTORE_CONTAINER_PORT       | postgresContainerPort  | If restoring into a Docker container, this is the port to expose                                                                       |
| RDP_PGDUMP_RESTORE_CONTAINER_IMAGE      | postgresContainerImage | If restoring into a Docker container, this is the Postgres image to use                                                                |
| RDP_PGDUMP_RESTORE_FILE_PASSWORD        | restoreFilePassword    | The password to use when extraction the 7z backup file                                                                                 |
| RDP_PGDUMP_RESTORE_FILE_PATH            | restoreFilePath        | The path to the backup file to restore. This is expected to be a 7z backup as created by the xtrabackup backup script.                 |
| RDP_PGDUMP_RESTORE_MD5_FILE_PATH        | restoreMd5FilePath     | The path to the md5 file of backup file to restore. This is expected to be the md5 as created by the xtrabackup backup script.         |
| RDP_PGDUMP_RESTORE_LATEST_MD5_FILE_PATH | latestMd5FilePath      | The path to store the md5 of the latest successful restoration. This is used to ensure the restore file is new before restoring.       |

```bash
sudo ./restore-pgdump.sh \
  --postgresUser=dhis \
  --postgresPassword=dhis \
  --postgresDatabase=dhis \
  --postgresContainerName=rdp_dhis_target \
  --postgresContainerPort=5432 \
  --postgresContainerImage=postgis/postgis:12-3.4 \
  --restoreFilePassword=Test1234 \
  --restoreFilePath=/opt/rdp/transfers/postgres.pgdump.7z \
  --restoreMd5FilePath=/opt/rdp/transfers/postgres.pgdump.7z.md5 \
  --latestMd5FilePath=/opt/rdp/databases/postgres/latest.md5
```
