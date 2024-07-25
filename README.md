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
| RDP_MYSQLDUMP_FILE_SYMLINK       | backupFileSymlink  | Optional, allows creating a symlink to the backup fiLe   |

Running with input arguments can be done as follows:

```bash
sudo ./backup-mysqldump.sh \
  --mysqlUser=root \
  --mysqlPassword=root \
  --mysqlDatabase=openmrs \
  --mysqlContainerName=mysql8 \
  --backupFilePassword=Test1234 \
  --backupFilePath=/tmp/srcdb.sql.7z \
  --backupFileSymlink=/tmp/srcdb_latest.sql.7z
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
| RDP_PERCONA_BACKUP_FILE_SYMLINK    | backupFileSymlink  | Optional, allows creating a symlink to the backup fiLe                                                     |

Running with input arguments can be done as follows:

```bash
sudo ./backup-xtrabackup.sh \
  --mysqlUser=root \
  --mysqlPassword=root \
  --backupFilePassword=Test1234 \
  --backupFilePath=/tmp/srcdb.xtrabackup.7z \
  --backupFileSymlink=/tmp/srcdb_latest.xtrabackup.7z
```
Running with environment variables can be done directly, but is most typically done via an environment file.  See [backup.sh](./scripts/backup.sh) as an example.

## backup-pgdump.sh

TODO: Support backing up a Postgres DB with pg_dump

# Transfer Scripts

## transfer-rsync.sh

TODO: Support transferring files with rsync

## transfer-scp.sh

TODO: Support transferring files with scp

## transfer-azcopy.sh

TODO: Support transferring files with Azcopy

# Restore Scripts

# restore-xtrabackup.sh

TODO: Support restoring a MySQL backup via Percona XtraBackup
