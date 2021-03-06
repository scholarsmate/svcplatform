#!/usr/bin/env bash

# Make sure password less sudo is enabled
sudo -v || ( echo "Please setup password-less sudo first" >&2 && exit 1 )

# Change the PWD to the directory where this script resides
cd $(dirname $(readlink -e $0))

if [[ -f ./setup.cfg ]]; then
  echo "Reading configuration from setup.cfg"
  source ./setup.cfg
fi

VAGRANT_VER=${VAGRANT_VER:-2.2.7}
SVC_PLATFORM=${SVC_PLATFORM:-platform}
SVC_REPO=${SVC_REPO:-https://github.com/scholarsmate/traefik2-docker-stack.git}
SVC_CERT_KEY_SIZE=${SVC_CERT_KEY_SIZE:-2048}
SVC_COUNTRY_CODE=${SVC_COUNTRY_CODE:-US}
SVC_STATE=${SVC_STATE:-Maryland}
SVC_ORGANIZATION=${SVC_ORGANIZATION:-Organization}
SVC_ORGANIZATIONAL_UNIT=${SVC_ORGANIZATIONAL_UNIT:-DevOps}
SVC_DOMAIN=${SVC_DOMAIN:-domain.com}
SVC_TIMEZONE=${SVC_TIMEZONE:-$(date +"%Z")}
RSYNC_BACKUP_SERVER=${RSYNC_BACKUP_SERVER:-}
RSYNC_BACKUP_USER=${RSYNC_BACKUP_USER:-devops}

cat << __EOF__ | tee ./setup.sav
##############################################################################
# Settings: $(date)
##############################################################################
VAGRANT_VER="${VAGRANT_VER}"
SVC_PLATFORM="${SVC_PLATFORM}"
SVC_REPO="${SVC_REPO}"
SVC_CERT_KEY_SIZE="${SVC_CERT_KEY_SIZE}"
SVC_COUNTRY_CODE="${SVC_COUNTRY_CODE}"
SVC_STATE="${SVC_STATE}"
SVC_ORGANIZATION="${SVC_ORGANIZATION}"
SVC_ORGANIZATIONAL_UNIT="${SVC_ORGANIZATIONAL_UNIT}"
SVC_DOMAIN="${SVC_DOMAIN}"
SVC_TIMEZONE="${SVC_TIMEZONE}"
RSYNC_BACKUP_SERVER="${RSYNC_BACKUP_SERVER}"
RSYNC_BACKUP_USER="${RSYNC_BACKUP_USER}"
##############################################################################
__EOF__

echo "Installing required packages for libvirt and vagrant ${VAGRANT_VER}..."

set -ex

# This is idempotent
sudo yum makecache
sudo yum install -y libvirt libvirt-devel ruby-devel gcc qemu-kvm haproxy openssl

# Generate TLS certificate (as required)
if [[ ! -f /etc/pki/tls/certs/svcplatform.pem ]]; then
  echo "Generating TLS certificate..."
  sudo mkdir -p /etc/pki/tls/certs
  key_temp=$(mktemp /tmp/openssl.XXXXXX)
  crt_temp=$(mktemp /tmp/openssl.XXXXXX)
  openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:${SVC_CERT_KEY_SIZE} -keyout ${key_temp} -out ${crt_temp} -subj "/C=${SVC_COUNTRY_CODE}/ST=${SVC_STATE}/O=${SVC_ORGANIZATION}/OU=${SVC_ORGANIZATIONAL_UNIT}/CN=${SVC_DOMAIN}" -addext "subjectAltName = DNS:*.${SVC_DOMAIN}"
  echo "" >> ${key_temp}
  cat ${crt_temp} >> ${key_temp}
  sudo mv ${key_temp} /etc/pki/tls/certs/svcplatform.pem
  sudo chown root:haproxy /etc/pki/tls/certs/svcplatform.pem
  sudo chmod 440 /etc/pki/tls/certs/svcplatform.pem
  rm -f ${crt_temp}
  # Generate Strong Diffie-Hellman group
  sudo openssl dhparam -out /etc/pki/tls/certs/dhparams.pem ${SVC_CERT_KEY_SIZE}
fi

# Setup the firewall
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Setup haproxy
sudo setsebool -P haproxy_connect_any=1
sudo systemctl enable haproxy
if [[ ! -f /etc/rsyslog.d/haproxy.conf ]]; then
  echo "Configuring rsyslog for HAProxy logs..."
  sudo cp -v conf/rsyslog.d/haproxy.conf /etc/rsyslog.d/
  sudo systemctl restart rsyslog
fi
sudo systemctl start haproxy
if [[ ! -f /etc/haproxy/haproxy.cfg ]]; then
  echo "Configuring HAProxy..."
  sudo cp -v conf/haproxy/haproxy.cfg /etc/haproxy/
  sudo systemctl reload haproxy
  # Allow port 8404 (HAProxy stats) through the firewall
  # URL is http://<server_ip>:8404/stats
  sudo firewall-cmd --permanent --zone=public --add-port=8404/tcp
fi

# Allow HTTP and HTTPS through the firewall
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

# If vagrant is installed, don't do anything, but if not, install the desired version
if [[ ! $( which vagrant ) ]]; then
  sudo yum install -y https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/vagrant_${VAGRANT_VER}_x86_64.rpm
fi

echo "Setting up the platform in ${SVC_PLATFORM}..."

cd "${SVC_PLATFORM}"
mkdir -p "repo"
[[ -d "repo/svcrepo" ]] || git clone "${SVC_REPO}" "repo/svcrepo"
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
