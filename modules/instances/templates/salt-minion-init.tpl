#!/bin/bash

# Log all output
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Exit on error
set -e

# Set hostname immediately at boot time
hostnamectl set-hostname ${minion_id}
echo "${minion_id}" > /etc/hostname
echo "127.0.1.1 ${minion_id}" >> /etc/hosts

# Log hostname setting
mkdir -p /var/log
echo "$(date '+%Y-%m-%d %H:%M:%S') - Setting hostname to ${minion_id} at boot time" >> /var/log/hostname_setup.log

mkdir -p /etc/salt/minion.d
# Write Salt minion configuration
cat > /etc/salt/minion << EOF
master: ${master}
id: ${minion_id}
random_id: false
hash_type: sha256
log_level: debug
EOF

# Write minion_id file explicitly
echo "${minion_id}" > /etc/salt/minion_id

# Install Salt
# Ensure keyrings dir exists
mkdir -p /etc/apt/keyrings
# Download public key
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | tee /etc/apt/keyrings/salt-archive-keyring.pgp
# Create apt repo target configuration
curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | tee /etc/apt/sources.list.d/salt.sources

apt-get update
apt-get install -y python3-pip awscli jq
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" -y --no-install-recommends install salt-minion

# Install Vault extension
/opt/saltstack/salt/bin/pip3 install saltext-vault
sleep 30
systemctl restart salt-minion