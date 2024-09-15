Rwanda data pipeline
=======================

The goal of this project is to provide a mechanism to allow one to set up a "source" server that contains a particular database of interest,
to back this database up, transfer this backup to an archive location, restore this backup onto a separate data warehouse server, and then
execute a series of ETL scripts against this restored database to load data into a data warehouse database.

This is designed to allow for multiple "source" servers to be configured, that are running either MySQL or Postgres databases, in order to facilitate
setting up a central data warehouse that contains consolidated and transformed data from various OpenMRS, DHIS2, and Redcap instances, but is not limited
to these particular systems.

# Installation and Configuration

Installation of this system is documented and facilitated by an [Ansible deployment package](./readme/deployment.md)

# Utility scripts

The [scripts](./readme/scripts.md) included in this package are designed to be used by this project, but also be generally
usable and useful on their own as needed.

# Development / testing setup

To test out this system, you should follow the following steps:

### Identify the server into which you want to install the system

For development purposes, we recommend using the included [Vagrantfile](./deployment/Vagrantfile).  The steps for using this are:
* Create a new directory on your machine, eg: `mkdir -p ~/environments/rdp`
* Copy the Vagrantfile from the location in this source code into this directory
* Navigate to this directory, and start the VM by running `vagrant up`

If you use the Vagrant setup above, an appropriate entry in [hosts](./deployment/inventories/hosts) and [host_vars](./deployment/inventories/host_vars/192.168.33.101.yml) is already available.

If you are installing into a different test server, or a Virtual Machine with a different IP address, you will need to create a new entry in the hosts file, and a 
new configuration file under host_vars with your appropriate IP Address or Host Name.

The rest of these instructions will be written assuming the standard Vagrant setup defined above.