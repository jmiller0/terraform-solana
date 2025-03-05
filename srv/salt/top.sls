base:
  '*':
    - salt_init
    - vault_init
    - common
  'G@host:salt-master':
    - salt-master  # Includes Vault integration configuration
    - vault        # Vault server installation and configuration
    - vault.policies
    - vault.approles
  'aws-validator-gcp-0* or solana-validator-gcp-0*':
    - solana.validator
    - solana.firedancer
    - solana.vault_auth
  'aws-test-minion or gcp-test-minion':
    - vault_test
