#!/bin/bash
set -xe
OS_VERSION=$1

ls -l /home

# Clean the yum cache
yum -y clean all
yum -y clean expire-cache

# First, install all the needed packages.
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION}.noarch.rpm
yum clean all
yum -y install ansible redhat-lsb-core
cd /ansible-cortex
printf '[defaults]\nroles_path = ../' > ansible.cfg
ansible-playbook -i tests/inventory --syntax-check tests/test.yml
ansible-playbook -i tests/inventory --connection=local --become tests/test.yml
