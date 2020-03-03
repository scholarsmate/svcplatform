#!/usr/bin/env bash

# Change the PWD to the directory where this script resides
cd $(dirname $(readlink -e $0))

echo '##########################################################################'
echo '#               About to run setup_restic.sh script                      #'
echo '##########################################################################'

set -ex

mkdir -p /etc/restic
[[ -f /etc/restic/restic.env ]] || cat <<__EOF__ | tee /etc/restic/restic.env
RESTIC_REPOSITORY=rest:http://10.4.16.6:8000
RESTIC_PASSWORD=$(cat ../conf/restic/passwd)
# Snapshot prune rules
RESTIC_KEEP_DAILY=7
RESTIC_KEEP_WEEKLY=4
RESTIC_KEEP_MONTHLY=12
RESTIC_KEEP_YEARLY=3
# Run every day at 1am
CRON_SCHEDULE="0 1 * * *"
__EOF__

if [[ ${RESTIC_SERVER} ]]; then
    # install restic
    yum-config-manager --add-repo https://copr.fedorainfracloud.org/coprs/copart/restic/repo/epel-7/copart-restic-epel-7.repo
    yum install -y restic

    # Open up TCP port 8000 for the restic service
    firewall-cmd --permanent --zone=public --add-port=8000/tcp
    firewall-cmd --reload

    mkdir -p /backup/restic/devops

    # Run the restic service via docker-compose
    PATH=$PATH:/usr/local/bin docker-compose --file /vagrant/restic-service/docker-compose.yml up

fi
