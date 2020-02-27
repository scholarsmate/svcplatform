#!/usr/bin/env bash

if [[ -f ./setup.cfg ]]; then
  echo "Reading configuration from setup.cfg"
  source ./setup.cfg
fi

VAGRANT_VER=${VAGRANT_VER:-2.2.7}
SVC_PLATFORM=${SVC_PLATFORM:-platform}
SVC_REPO=${SVC_REPO:-https://github.com/scholarsmate/traefik2-docker-stack.git}
SVC_COUNTRY_CODE=${SVC_COUNTRY_CODE:-US}
SVC_STATE=${SVC_STATE:-Maryland}
SVC_ORGANIZATION=${SVC_ORGANIZATION:-Organization}
SVC_ORGANIZATIONAL_UNIT=${SVC_ORGANIZATIONAL_UNIT:-DevOps}
SVC_DOMAIN=${SVC_DOMAIN:-domain.com}

echo "Installing required packages for libvirt and vagrant ${VAGRANT_VER}..."

set -ex

# This is idempotent
sudo yum makecache
sudo yum install -y libvirt libvirt-devel ruby-devel gcc qemu-kvm haproxy openssl

# Generate TLS certificate (as required)
if [[ ! -f /etc/pki/tls/certs/svcplatform.crt ]]; then
  echo "Generating TLS certificate..."
  sudo mkdir -p /etc/pki/tls/{private,certs}
  sudo openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/svcplatform.key -out /etc/pki/tls/certs/svcplatform.crt -subj "/C=${SVC_COUNTRY_CODE}/ST=${SVC_STATE}/O=${SVC_ORGANIZATION}/OU=${SVC_ORGANIZATIONAL_UNIT}/CN=${SVC_DOMAIN}"
fi

# Setup haproxy
if [[ ! /etc/haproxy/haproxy.cfg ]]; then
  echo "Configuring HAProxy..."
  sudo cp -v conf/haproxy/haproxy.cfg /etc/haproxy/
fi
sudo setsebool -P haproxy_connect_any=1
sudo systemctl start haproxy
sudo systemctl enable haproxy

# Setup the firewall
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --reload

# If vagrant is installed, don't do anything, but if not, install the desired version
if [[ ! $( which vagrant ) ]]; then
  sudo yum install -y https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/vagrant_${VAGRANT_VER}_x86_64.rpm
fi

echo "Setting up the platform in ${SVC_PLATFORM}..."

cd "$SVC_PLATFORM"
mkdir -p "repo"
[[ -d "repo/svcrepo" ]] || git clone "$SVC_REPO" "repo/svcrepo"
vagrant up --provider=libvirt --no-parallel
vagrant status

echo "Halting machines to take pristine snapshots..."
vagrant halt
for vm_name in "${USER}-${SVC_PLATFORM}_nfs_storage" "${USER}-${SVC_PLATFORM}_docker_server_1" "${USER}-${SVC_PLATFORM}_docker_server_2" "${USER}-${SVC_PLATFORM}_docker_server_3"; do
  sudo virsh snapshot-create-as --domain "$vm_name" --name "pristine" --description "pristine snapshot";
  sudo virsh snapshot-list "$vm_name"
done

echo "Bringing machines back online..."
vagrant up --provider=libvirt --no-parallel
vagrant status
