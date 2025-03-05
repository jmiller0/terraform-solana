base:
  '*validator*':
    - approle
  'aws-test-minion or gcp-test-minion':
    - approle
  'salt-master':
    - vault.certs
    - vault.token
