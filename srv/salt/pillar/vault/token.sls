vault:
  token: {{ salt['file.read']('/etc/salt/vault_token') | default('', true) | replace('\n', '') | replace('\r', '') }}