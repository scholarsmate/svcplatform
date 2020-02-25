#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run setup_nfs_client.sh script                  #'
echo '##########################################################################'

set -ex

# Install NFS client software and a filesystem cache to improve NFS performance
yum install -y nfs-utils cachefilesd

echo "RUN=yes" > /etc/default/cachefilesd
systemctl start cachefilesd
systemctl enable cachefilesd

mkdir -p /mnt/data /mnt/data_ro

echo '10.4.16.6:/nfs/export_ro   /mnt/data_ro   nfs   soft,timeo=100,_netdev,fsc,ro   0   0' >> /etc/fstab
echo '10.4.16.6:/nfs/export_rw   /mnt/data      nfs   soft,timeo=100,_netdev,fsc,rw   0   0' >> /etc/fstab

mount -a
