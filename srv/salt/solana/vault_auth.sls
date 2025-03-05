# Install dependencies
install_dependencies:
  pkg.installed:
    - pkgs:
      - python3-pip
      - jq

# Create directories for validator keys
create_validator_key_directories:
  file.directory:
    - names:
      - /mnt/solana
    - user: solana
    - group: solana
    - mode: '0700'
    - makedirs: True

# Fetch all validator keypairs from Vault and write them to files
# Each keypair is written with restricted permissions (0600) and owned by solana
# The secrets are read once and reused for all keypairs to minimize Vault API calls
# The show_changes: False prevents sensitive data from appearing in logs
# Example Vault command to store keypairs: vault kv put secret/solana/validator authorized-withdrawer=@authorized-withdrawer-keypair.json stake=@stake-keypair.json validator=@validator-keypair.json vote-account=@vote-account-keypair.json
{% if salt['pillar.get']('vault:approle:role_id') %}
{% set validator_secrets = salt['vault.read_secret']('secret/solana/validator', default={}) %}
{% for key_name in ['authorized-withdrawer', 'stake', 'validator', 'vote-account'] %}
fetch_{{ key_name }}_keypair:
  file.managed:
    - name: /mnt/solana/{{ key_name }}-keypair.json
    - contents: |
        {{ validator_secrets.get(key_name, '') }}
    - user: solana
    - group: solana
    - mode: '0600'
    - template: jinja
    - allow_empty: True
    - show_changes: False
    - require:
      - file: create_validator_key_directories
{% endfor %}
{% endif %}