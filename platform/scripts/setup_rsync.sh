#!/usr/bin/env bash

RSYNC_BACKUP_SERVER=${RSYNC_BACKUP_SERVER:-192.168.1.45}
RSYNC_BACKUP_USER=${RSYNC_BACKUP_USER:-devops}

echo '##########################################################################'
echo '#               About to run setup_rsync.sh script                       #'
echo '##########################################################################'

set -ex

# install nfs server software
yum install -y incron

# setup incron table
# NOTE: The vagrant public key must be authorized on this system for this user for the rsync to work
echo "/nfs/export_rw/backups  IN_CLOSE_WRITE  rsync -a /nfs/export_rw/backups/ ${RSYNC_BACKUP_USER}@${RSYNC_BACKUP_SERVER}:/home/devops/backups" | tee -a /var/spool/incron/vagrant

# enable and start the incrond service
systemctl enable incrond
systemctl start incrond

# allow rsyncd traffic through the firewall
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --zone=public --add-service=rsyncd
systemctl restart firewalld

# create a shared directory for the vagrant user
mkdir -p /nfs/export_rw/vagrant
chown vagrant:vagrant /nfs/export_rw/vagrant

# confirm the exports
showmount -e localhost
