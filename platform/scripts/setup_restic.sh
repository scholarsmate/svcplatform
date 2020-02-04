#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run setup_restic.sh script                      #'
echo '##########################################################################'

set -ex

# install restic
yum-config-manager --add-repo https://copr.fedorainfracloud.org/coprs/copart/restic/repo/epel-7/copart-restic-epel-7.repo
yum install -y restic

# TODO: Put this somewhere else
# install git
yum install -y git
