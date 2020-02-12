#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run setup_svc.sh script                         #'
echo '##########################################################################'

set -ex

[[ -f /vagrant/svcrepo/setup.sh ]] && cd /vagrant/svcrepo && /bin/sh ./setup.sh
