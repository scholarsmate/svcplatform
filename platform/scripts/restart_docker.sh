#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run restart_docker.sh script                    #'
echo '##########################################################################'

set -ex

# restart docker
systemctl daemon-reload
systemctl restart docker
