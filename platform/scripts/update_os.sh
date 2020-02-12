#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run update_os.sh script                         #'
echo '##########################################################################'

set -ex
sudo yum makecache
sudo yum update -y
