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

# Install Salt
# Ensure keyrings dir exists
mkdir -p /etc/apt/keyrings

# Download public key
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | tee /etc/apt/keyrings/salt-archive-keyring.pgp

# Create apt repo target configuration
curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | tee /etc/apt/sources.list.d/salt.sources

apt-get update
apt-get install -y salt-minion python3-pip awscli jq



# Write Salt minion configuration
cat > /etc/salt/minion << EOF
master: ${master}
id: ${minion_id}
random_id: false
hash_type: sha256
EOF

# Write minion_id file explicitly
echo "${minion_id}" > /etc/salt/minion_id

# Set aws_root_zone as a grain
cat > /etc/salt/grains << EOF
aws_root_zone: ${aws_root_zone}
EOF

#Write vault.conf
cat > /etc/salt/minion.d/vault.conf << EOF
vault:
  config_location: master
  verify: False
EOF

# Install Vault extension
/opt/saltstack/salt/bin/pip3 install saltext-vault
systemctl restart salt-minion
systemctl enable salt-minion 
# sleep 5
# salt-call state.highstate | tee /var/log/salt-highstate.log 2>&1
# echo "`date` Salt highstate completed" >> /var/log/salt-highstate.log
