#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run setup_nfs_server.sh script                  #'
echo '##########################################################################'

set -ex

# install nfs server software
yum install -y nfs-utils policycoreutils-python

# make sure selinux is up and running
sed -i 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config
setenforce enforcing

# create 2 folders to be shared
mkdir -p /nfs/export_ro /nfs/export_rw

# Ref: selinx_nfs(8) man page
semanage fcontext -a -t public_content_t     '/nfs/export_ro(/.*)?'
semanage fcontext -a -t public_content_rw_t  '/nfs/export_rw(/.*)?'
# apply the label changes
restorecon -Rv /nfs

# add entries to /etc/exports (empty file by default), allowing clients on the 10.4.5.x network.
echo '/nfs/export_ro  10.4.16.0/24(sync)' > /etc/exports
echo '/nfs/export_rw  10.4.16.0/24(rw,no_root_squash)' >> /etc/exports

# startup the NFS server and have it startup on boot
systemctl start nfs-server
systemctl enable nfs-server

# allow nfs traffic through the firewall
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
systemctl restart firewalld

# create a shared directory for the vagrant user
mkdir -p /nfs/export_rw/vagrant
chown vagrant:vagrant /nfs/export_rw/vagrant

# confirm the exports
showmount -e localhost
