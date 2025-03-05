#!/bin/bash

# Log all output
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Exit on error
set -e

# Set hostname
hostnamectl set-hostname salt-master
echo "salt-master" > /etc/hostname
echo "127.0.1.1 salt-master" >> /etc/hosts

# Install Salt master
mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | tee /etc/apt/keyrings/salt-archive-keyring.pgp
curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | tee /etc/apt/sources.list.d/salt.sources

# Install required packages
apt-get update
apt-get install -y salt-master salt-minion python3-pip python3-gnupg awscli jq unzip software-properties-common openssl

# Install Vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install -y vault

# Create required directories
mkdir -p /etc/salt/master.d
mkdir -p /etc/salt/gpgkeys
mkdir -p /srv/salt
mkdir -p /srv/salt/pillar
mkdir -p /opt/vault/data
mkdir -p /opt/vault/tls

# Set proper permissions (fix ownership)
chown -R root:root /etc/salt
chown -R root:salt /etc/salt/gpgkeys
chmod 700 /etc/salt/gpgkeys
chown -R vault:vault /opt/vault
chown -R root:salt /srv/salt
chmod 755 /srv/salt
chmod 750 /srv/salt/pillar

# Configure GPG for Salt master
cat > /etc/salt/master.d/gpg.conf << EOF
# GPG configuration for Salt master
gpg_keydir: /etc/salt/gpgkeys
EOF

# Set aws_root_zone as a grain
cat > /etc/salt/grains << EOF
aws_root_zone: ${aws_root_zone}
EOF

# Configure GPG renderer for pillar decryption
cat > /etc/salt/master.d/gpg_renderer.conf << EOF
# Enable GPG renderer for pillar decryption
decrypt_pillar_default: gpg
decrypt_pillar_renderers:
  - gpg
EOF

# Generate GPG key for Salt master
cat > /tmp/gpg_batch << EOF
%echo Generating GPG key for Salt Master
Key-Type: RSA
Key-Length: 2048
Name-Real: Salt Master
Name-Email: salt@localhost
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF

# Generate GPG key with proper ownership
gpg --batch --gen-key --homedir /etc/salt/gpgkeys /tmp/gpg_batch
rm /tmp/gpg_batch

# Fix GPG directory permissions after key generation
chown -R root:salt /etc/salt/gpgkeys
chmod -R 700 /etc/salt/gpgkeys

# Generate self-signed TLS cert for Vault
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/vault/tls/tls.key \
  -out /opt/vault/tls/tls.crt \
  -subj "/CN=salt-master.${aws_root_zone}/O=Salt Master/C=US" \
  -addext "subjectAltName = DNS:salt-master.${aws_root_zone},DNS:salt-master,DNS:localhost,IP:127.0.0.1"

chown vault:vault /opt/vault/tls/tls.*
chmod 600 /opt/vault/tls/tls.key
chmod 644 /opt/vault/tls/tls.crt

# Basic Salt master configuration
cat > /etc/salt/master << EOF
interface: 0.0.0.0
auto_accept: True
file_roots:
  base:
    - /srv/salt
pillar_roots:
  base:
    - /srv/salt/pillar
log_level: info
log_level_logfile: info
hash_type: sha256
worker_threads: 5
timeout: 60
job_cache: True
keep_jobs: 24
EOF

# Install Vault extension
/opt/saltstack/salt/bin/pip3 install saltext-vault

# Vault configuration with TLS
cat > /etc/vault.d/vault.hcl << EOF
storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/tls.crt"
  tls_key_file  = "/opt/vault/tls/tls.key"
}

disable_mlock = true
ui = true
api_addr = "https://0.0.0.0:8200"
EOF

# Configure Salt master to use Vault
cat > /etc/salt/master.d/vault.conf << EOF
vault:
  auth:
    method: token
    token_file: /etc/salt/vault_token
    token_backend: session
  server:
    url: https://127.0.0.1:8200
    verify: /opt/vault/tls/tls.crt
EOF

#Write minion vault.conf
cat > /etc/salt/minion.d/vault.conf << EOF
vault:
  config_location: master
  verify: /opt/vault/tls/tls.crt
EOF

# Write Salt minion configuration
cat > /etc/salt/minion << EOF
master: 127.0.0.1
id: salt-master
random_id: false
hash_type: sha256
EOF

# Write minion_id file explicitly
echo "salt-master" > /etc/salt/minion_id

# Start services
systemctl restart salt-master
systemctl enable salt-master
systemctl restart vault
systemctl enable vault

# Initialize Vault
sleep 5  # Wait for Vault to start

# POC configuration: Using single key for simplicity
# Production should use multiple keys (e.g., -key-shares=3 -key-threshold=2)
VAULT_ADDR='https://127.0.0.1:8200' VAULT_SKIP_VERIFY=true vault operator init -key-shares=1 -key-threshold=1 > /root/vault-init.txt

# Store initialization output securely
chmod 600 /root/vault-init.txt

# Extract root token and save it for Salt
grep 'Initial Root Token:' /root/vault-init.txt | awk '{print $NF}' > /etc/salt/vault_token
chmod 600 /etc/salt/vault_token
chown root:salt /etc/salt/vault_token

# Unseal Vault using the single key (POC only)
UNSEAL_KEY1=$(grep 'Unseal Key 1:' /root/vault-init.txt | awk '{print $NF}')
export VAULT_SKIP_VERIFY=true
VAULT_ADDR='https://127.0.0.1:8200' vault operator unseal $UNSEAL_KEY1

export VAULT_TOKEN=$(cat /etc/salt/vault_token)
export VAULT_ADDR='https://127.0.0.1:8200'

# Enable AppRole auth method
vault auth enable approle

# Create AppRole for validators
vault write auth/approle/role/validator \
  secret_id_ttl=0 \
  token_ttl=1h \
  token_max_ttl=4h \
  policies=validator-policy,salt_minion_base

# Create AppRole for test minions
vault write auth/approle/role/gcp-test-minion \
  secret_id_ttl=0 \
  token_ttl=24h \
  token_max_ttl=48h \
  policies=test-minion-policy,salt_minion_base

# Generate AppRole credentials
vault read -field=role_id auth/approle/role/validator/role-id > /tmp/role_id.txt
vault write -f -field=secret_id auth/approle/role/validator/secret-id > /tmp/secret_id.txt

# Encrypt AppRole credentials with GPG
gpg --homedir /etc/salt/gpgkeys --trust-model always --armor --batch --yes --encrypt --recipient "Salt Master" --output /tmp/role_id.gpg /tmp/role_id.txt
gpg --homedir /etc/salt/gpgkeys --trust-model always --armor --batch --yes --encrypt --recipient "Salt Master" --output /tmp/secret_id.gpg /tmp/secret_id.txt

# Update approle.sls with encrypted credentials
cat > /srv/salt/pillar/approle.sls << EOF
#!yaml|gpg

vault:
  approle:
    role_id: |
$(cat /tmp/role_id.gpg | sed 's/^/      /')
    secret_id: |
$(cat /tmp/secret_id.gpg | sed 's/^/      /')
EOF

# Set proper permissions on pillar files
chmod 640 /srv/salt/pillar/approle.sls
chown root:salt /srv/salt/pillar/approle.sls

# Add Vault environment variables to /etc/environment for persistence
cat >> /etc/environment << EOF
VAULT_ADDR="https://127.0.0.1:8200"
VAULT_SKIP_VERIFY=true
EOF

# Enable KV secrets engine
vault secrets enable -version=2 kv
vault secrets enable -path=secret kv

# Create pillar directory with proper permissions
mkdir -p /srv/salt/pillar/vault
chown root:salt /srv/salt/pillar/vault
chmod 750 /srv/salt/pillar/vault

# Now encrypt the certificates and token
CERT=$(cat /opt/vault/tls/tls.crt)
KEY=$(cat /opt/vault/tls/tls.key)
TOKEN=$(cat /etc/salt/vault_token)

# Create temporary files with proper permissions
install -m 600 /dev/null /tmp/cert.txt
install -m 600 /dev/null /tmp/key.txt
install -m 600 /dev/null /tmp/token.txt

echo "$CERT" > /tmp/cert.txt
echo "$KEY" > /tmp/key.txt
echo "$TOKEN" > /tmp/token.txt

# Encrypt files with GPG
gpg --homedir /etc/salt/gpgkeys --trust-model always --armor --batch --yes --encrypt --recipient "Salt Master" --output /tmp/cert.gpg /tmp/cert.txt
gpg --homedir /etc/salt/gpgkeys --trust-model always --armor --batch --yes --encrypt --recipient "Salt Master" --output /tmp/key.gpg /tmp/key.txt
gpg --homedir /etc/salt/gpgkeys --trust-model always --armor --batch --yes --encrypt --recipient "Salt Master" --output /tmp/token.gpg /tmp/token.txt

# Create pillar file with encrypted values
cat > /srv/salt/pillar/vault/certs.sls << EOF
#!yaml|gpg

vault:
  tls:
    cert: |
$(cat /tmp/cert.gpg | sed 's/^/      /')
    key: |
$(cat /tmp/key.gpg | sed 's/^/      /')
EOF

# Create token pillar file
cat > /srv/salt/pillar/vault/token.sls << EOF
vault:
  token: {{ salt['file.read']('/etc/salt/vault_token') | default('', true) | replace('\n', '') | replace('\r', '') }}
EOF

# Set proper permissions on pillar files
chmod 640 /srv/salt/pillar/vault/certs.sls
chmod 640 /srv/salt/pillar/vault/token.sls
chown root:salt /srv/salt/pillar/vault/certs.sls
chown root:salt /srv/salt/pillar/vault/token.sls

# Clean up temporary files securely
#shred -u /tmp/cert.txt /tmp/key.txt /tmp/token.txt /tmp/cert.gpg /tmp/key.gpg /tmp/token.gpg

# Final validation
if ! gpg --list-keys --homedir /etc/salt/gpgkeys | grep -q "Salt Master"; then
    echo "ERROR: GPG key setup failed"
    exit 1
fi

if ! VAULT_SKIP_VERIFY=true vault status | grep -q "Sealed.*false"; then
    echo "ERROR: Vault is not properly unsealed"
    exit 1
fi

if ! systemctl is-active --quiet salt-master; then
    echo "ERROR: Salt master is not running"
    exit 1
fi

echo "Salt master and Vault initialization complete. IMPORTANT: Save /root/vault-init.txt securely!"
