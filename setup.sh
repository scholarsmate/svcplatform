#!/usr/bin/env bash

VAGRANT_VER=${VAGRANT_VER:-2.2.7}
SVC_PLATFORM=${SVC_PLATFORM:-platform}

echo "Installing required packages for libvirt and vagrant ${VAGRANT_VER}..."

set -ex

# This is idempotent
sudo yum install -y libvirt libvirt-devel ruby-devel gcc qemu-kvm

# If vagrant is installed, don't do anything, but if not, install the desired version
if [[ ! $( which vagrant ) ]]; then
  sudo yum install -y https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/vagrant_${VAGRANT_VER}_x86_64.rpm
fi

echo "Setting up the platform in ${SVC_PLATFORM}..."

cd "$SVC_PLATFORM"
vagrant up --provider=libvirt --no-parallel
vagrant status

echo "Halting machines to take pristine snapshots..."
vagrant halt
for vm_name in "${USER}-${SVC_PLATFORM}_nfs_server" "${USER}-${SVC_PLATFORM}_docker_server"; do
  virsh snapshot-create-as --domain "$vm_name" --name "pristine" --description "pristine snapshot";
  virsh snapshot-list "$vm_name"
done

echo "Bringing machines back online..."
vagrant up --provider=libvirt --no-parallel
vagrant status
