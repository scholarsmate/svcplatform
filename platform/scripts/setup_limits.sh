#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run setup_limits.sh script                      #'
echo '##########################################################################'

set -ex

# Increase the max map count (for Elastic Search)
echo vm.max_map_count=262144 > /etc/sysctl.d/vm_max_map_count.conf
sysctl --system

