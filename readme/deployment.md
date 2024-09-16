Rwanda Data Pipeline Deployment
=====================================

The [deployment](../deployment) directory contains Ansible playbooks for installing the necessary scripts into a given server.

* Each [playbook](../deployment/playbooks) groups together a series of components, known as roles.
* We have playbooks for each primary use case
  * Setting up a "source" server, which is defined as a server that contains one or more source databases to backup and transfer to an external archive
  * Setting up a "warehouse" server, which is defined as a server that restores one or more databases and executes an ETL pipeline against them

* The [inventory](../deployment/inventories) defines the servers onto which one or more playbooks should be executed
* Each server should be added to the "hosts" file under either "source" or "warehouse"
* A file named "<host>.yml" should be added to the [host_vars](../deployment/inventories/host_vars) directory with the specific configurations for that server

# Source Server Install

To configure a "source" server, one would then run the following, assuming the user running the command has key-based SSH access to the given system:
```shell
ansible-playbook --ask-become-pass -i inventories/hosts -l <group or host> playbooks/install_on_source.yml
```

Once the server is prepared with the ansible script above, one needs to log into the server and specify the appropriate configuration:
```bash
sudo su - rdp
cd /home/rdp/env
```
For each file with an `.env.example` suffix under `/home/rdp/env`, you must copy this file to a file with the same name, but without the `.example` suffix.
For example:
```bash
cp myfile.env.example myfile.env
```
One then should edit the copied file and change any environment variables that should be configured differently for this particular server.

The reason for this approach is to keep any sensitive data out of the Ansible repository, and allow this to exist only on the server level.

# Warehouse Server Install

To configure a "warehouse" server, one would then run the following, assuming the user running the command has key-based SSH access to the given system:
```shell
ansible-playbook --ask-become-pass -i inventories/hosts -l <group or host> playbooks/install_on_warehouse.yml
```

Once the server is prepared with the ansible script above, one needs to log into the server and specify the appropriate configuration:
```bash
sudo su - rdp
cd /home/rdp/env
```
For each file with an `.env.example` suffix under `/home/rdp/env`, you must copy this file to a file with the same name, but without the `.example` suffix.
For example:
```bash
cp myfile.env.example myfile.env
```
One then should edit the copied file and change any environment variables that should be configured differently for this particular server.

One needs to follow this same approach for the petl application.yml file, by `cp /home/rdp/petl/application.yml.example /home/rdp/petl/application.yml`
and then editing the contents as appropriate.

The reason for this approach is to keep any sensitive data out of the Ansible repository, and allow this to exist only on the server level.


# MySQL Source FAQs

In order to execute the Percona Xtrabackup utility against MySQL, the user executing this must have appropriate privileges. 
The below represents the minimal configuration needed to be done for a given user with the username `test`:

```sql
GRANT BACKUP_ADMIN, PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'test'@'localhost';
GRANT SELECT ON performance_schema.log_status TO 'test'@'localhost';
GRANT SELECT ON performance_schema.keyring_component_status TO 'test'@'localhost';
GRANT SELECT ON performance_schema.replication_group_members TO 'test'@'localhost';
FLUSH PRIVILEGES;
```