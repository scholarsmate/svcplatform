#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run setup_devops.sh script                      #'
echo '##########################################################################'

set -ex

# install git
yum install -y git

mkdir ~/git
cd ~/git
git clone https://github.com/scholarsmate/traefik2-docker-stack.git
cd traefik2-docker-stack
/bin/sh ./setup.sh
