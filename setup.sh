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
vagrant up --no-parallel
vagrant status

