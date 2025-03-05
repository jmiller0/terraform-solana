# Vault AppRole Management
# This state file manages AppRole authentication for minions

# Set Vault environment variables
set_vault_env:
  environ.setenv:
    - name: vault_env
    - value:
        VAULT_ADDR: "https://127.0.0.1:8200"
        VAULT_SKIP_VERIFY: "true"
    - update_minion: True

# Ensure Vault is unsealed before attempting to configure AppRole
check_vault_status_approle:
  cmd.run:
    - name: |
        VAULT_STATUS=$(vault status -format=json 2>/dev/null || echo '{"sealed": true}')
        if echo "$VAULT_STATUS" | grep -q '"sealed":true'; then
          echo "Vault is sealed. Cannot configure AppRole."
          exit 0
        fi
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}
    - require:
      - environ: set_vault_env

# Enable AppRole auth if not already enabled
enable_approle:
  cmd.run:
    - name: |
        vault auth enable approle
    - unless: vault auth list | grep -q '^approle/' || vault status -format=json 2>/dev/null | grep -q '"sealed":true'
    - require:
      - cmd: check_vault_status_approle
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}

# Configure AppRole for validators
configure_validator_approle:
  cmd.run:
    - name: |
        vault write auth/approle/role/validator \
          secret_id_ttl=0 \
          token_ttl=1h \
          token_max_ttl=4h \
          policies=validator-policy,salt_minion_base
    - unless: vault read auth/approle/role/validator | grep -q "salt_minion_base" || vault status -format=json 2>/dev/null | grep -q '"sealed":true'
    - require:
      - cmd: enable_approle
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }} 

# Configure AppRole for localhost (salt-master's local minion)
configure_localhost_approle:
  cmd.run:
    - name: |
        vault write auth/approle/role/localhost \
          secret_id_ttl=0 \
          secret_id_num_uses=0 \
          token_ttl=1h \
          token_max_ttl=4h \
          token_num_uses=0 \
          token_explicit_max_ttl=0 \
          policies=salt_minion_base
    - unless: vault read auth/approle/role/localhost | grep -q "salt_minion_base" || vault status -format=json 2>/dev/null | grep -q '"sealed":true'
    - require:
      - cmd: enable_approle
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}

# Generate and store AppRole credentials for validators
store_validator_approle_creds:
  cmd.run:
    - name: |
        ROLE_ID=$(vault read -field=role_id auth/approle/role/validator/role-id)
        SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/validator/secret-id)
        vault kv put secret/solana/approle \
          role_id=${ROLE_ID} \
          secret_id=${SECRET_ID}
    - unless: vault kv get secret/solana/approle | grep -q "role_id" || vault status -format=json 2>/dev/null | grep -q '"sealed":true'
    - require:
      - cmd: configure_validator_approle
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}

