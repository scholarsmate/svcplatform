#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run start_swarm.sh script                       #'
echo '##########################################################################'

set -ex

# Allow docker swarm data through the firewall
sudo firewall-cmd --add-port=2376/tcp --permanent  
sudo firewall-cmd --add-port=2377/tcp --permanent  
sudo firewall-cmd --add-port=7946/tcp --permanent  
sudo firewall-cmd --add-port=7946/udp --permanent  
sudo firewall-cmd --add-port=4789/udp --permanent
sudo systemctl restart firewalld

# Start the storm cluster
docker swarm init --advertise-addr 10.4.16.11:2377

# Save the worker and manager tokens to file on shared storage
docker swarm join-token manager -q >/mnt/data/vagrant/swarm_token.txt
docker swarm join-token worker -q >/mnt/data/vagrant/swarm_worker_token.txt
