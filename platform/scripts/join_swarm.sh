#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run join_swarm.sh script                        #'
echo '##########################################################################'

set -ex

# Allow docker swarm data through the firewall
sudo firewall-cmd --add-port=2376/tcp --permanent  
sudo firewall-cmd --add-port=2377/tcp --permanent  
sudo firewall-cmd --add-port=7946/tcp --permanent  
sudo firewall-cmd --add-port=7946/udp --permanent  
sudo firewall-cmd --add-port=4789/udp --permanent
sudo systemctl restart firewalld

# Join the swarm as both a manager and a worker.
docker swarm join --token `cat /mnt/data/vagrant/swarm_token.txt` 10.4.16.11:2377
