Rwanda Data Pipeline Deployment
=====================================

This deployment project contains ansible playbooks for installing the necessary scripts into a given server.

To prepare a source system with a given playbook, you would take the following steps:

1. Add the host that you want to deploy to into the [hosts](./inventories/hosts) file, under the appropriate group name(s)
2. Add any variables that should be set differently on this host than are in the defaults for the playbook/role or group, into a new file under `host_vars`

You would then execute the playbook to run against the host(s) of interest from a terminal at this folder location using the syntax:
```shell
ansible-playbook --ask-become-pass -i inventories/hosts -l <group or host> playbooks/<playbook>.yml
```

For example, to run the playbook to back-up databases against the Vagrant VM (see Vagrantfile in this directory):
```shell
ansible-playbook --ask-become-pass -i inventories/hosts -l 192.168.33.101 playbooks/install_on_source.yml
```

And to run that same playbook against _all_ systems that are in the `[openmrs]` group, you would run:
```shell
ansible-playbook --ask-become-pass -i inventories/hosts -l openmrs playbooks/backup_mysql.yml
```

There are playbooks and groups for the distinct deployment models that have been developed.

Groups exist for `[openmrs]`, `[dhis2]`, `[redcap]`, `[warehouse]`.  Servers should be organized as appropriate under these groups within the hosts file.

Playbooks exist for `install_on_source`, `install_on_target`
