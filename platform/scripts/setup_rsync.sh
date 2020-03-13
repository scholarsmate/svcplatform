#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run setup_rsync.sh script                       #'
echo '##########################################################################'

set -ex

# Only setup the rsync backups if both of these environment variables are populated
if [[ -n "${RSYNC_BACKUP_SERVER}" && -n "${RSYNC_BACKUP_USER}" ]]; then
    # install nfs server software
    yum install -y incron

    # setup incron table
    # NOTE: The vagrant public key must be authorized on this system for this user for the rsync to work
    echo "/nfs/export_rw/backups  IN_CLOSE_WRITE  rsync -a /nfs/export_rw/backups/ ${RSYNC_BACKUP_USER}@${RSYNC_BACKUP_SERVER}:/home/${RSYNC_BACKUP_USER}/backups" | tee -a /var/spool/incron/vagrant

    # enable and start the incrond service
    systemctl enable incrond
    systemctl start incrond

    # allow rsyncd traffic through the firewall
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --permanent --zone=public --add-service=rsyncd
    systemctl restart firewalld
fi
