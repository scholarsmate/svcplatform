#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run join_swarm.sh script                        #'
echo '##########################################################################'

set -ex

# Allow docker swarm data through the firewall
sudo firewall-cmd --add-port=2376/tcp --zone=public --permanent
sudo firewall-cmd --add-port=2377/tcp --zone=public --permanent
sudo firewall-cmd --add-port=7946/tcp --zone=public --permanent
sudo firewall-cmd --add-port=7946/udp --zone=public --permanent
sudo firewall-cmd --add-port=4789/udp --zone=public --permanent
sudo firewall-cmd --add-port=2222/tcp --zone=public --permanent
sudo systemctl restart firewalld

# Join the swarm as both a manager and a worker.
docker swarm join --token `cat /mnt/data/vagrant/swarm_token.txt` 10.4.16.11:2377
