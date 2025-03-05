# Vault Policy Management
# Set Vault environment variables

# Ensure Vault is unsealed before attempting to create policies
check_vault_status:
  cmd.run:
    - name: |
        VAULT_STATUS=$(vault status -format=json 2>/dev/null || echo '{"sealed": true}')
        if echo "$VAULT_STATUS" | grep -q '"sealed":true'; then
          echo "Vault is sealed. Cannot manage policies."
          exit 0
        fi
    - show_changes: False
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}

# Base policy for all Salt minions
create_salt_minion_base_policy:
  cmd.run:
    - name: |
        vault policy write salt_minion_base - << EOF
        # Base policy for all Salt minions
        path "auth/token/lookup-self" {
          capabilities = ["read"]
        }
        
        path "auth/token/renew-self" {
          capabilities = ["update"]
        }
        
        # Allow access to common secrets
        path "secret/data/common/*" {
          capabilities = ["read", "list"]
        }
        
        path "secret/metadata/common/*" {
          capabilities = ["read", "list"]
        }
        EOF
    - show_changes: False
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}
    - require:
      - cmd: check_vault_status

# Validator policy
create_validator_policy:
  cmd.run:
    - name: |
        vault policy write validator-policy - << 'EOF'
        # Policy for Solana validator nodes
        path "secret/metadata/solana/*" {
          capabilities = ["read", "list"]
        }

        path "secret/solana/*" {
          capabilities = ["read", "list"]
        }

        # Allow token lookup
        path "auth/token/lookup" {
          capabilities = ["read"]
        }

        path "auth/token/lookup-self" {
          capabilities = ["read"]
        }
        EOF
    - show_changes: False
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}
    - require:
      - cmd: check_vault_status

# Test minion policy
create_test_minion_policy:
  cmd.run:
    - name: |
        vault policy write test-minion-policy - << EOF
        # Policy for test minion nodes
        path "secret/data/test/*" {
          capabilities = ["read", "list"]
        }
        
        path "secret/metadata/test/*" {
          capabilities = ["read", "list"]
        }
        
        # Allow access to test secrets
        path "secret/test/*" {
          capabilities = ["read", "list"]
        }
        
        # Allow token lookup
        path "auth/token/lookup-self" {
          capabilities = ["read"]
        }
        EOF
    - show_changes: False
    - unless: vault policy read test-minion-policy | grep -q "secret/test" || vault status -format=json 2>/dev/null | grep -q '"sealed":true'
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}
    - require:
      - cmd: check_vault_status

# Create a test secret for validation
create_test_secret:
  cmd.run:
    - name: |
        vault kv put secret/test/simple_kv value="This is a test secret" timestamp="$(date)"
    - unless: vault kv get secret/test/simple_kv || vault status -format=json 2>/dev/null | grep -q '"sealed":true'
    - env:
        - VAULT_TOKEN: {{ pillar['vault']['token'] }}
    - require:
      - cmd: check_vault_status 