# Create a test directory
test_directory:
  file.directory:
    - name: /tmp/vault_test
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: True
    - require:
      - sls: vault_init

# Test if we can access vault configuration through pillar
test_vault_pillar:
  file.managed:
    - name: /tmp/vault_test/pillar_test.txt
    - contents: |
        Vault configuration test:
        Minion ID: {{ grains['id'] }}
        Auth method: approle
        Role ID: {{ pillar.get('vault', {}).get('approle', {}).get('role_id', 'NOT AVAILABLE') }}
    - user: root
    - group: root
    - mode: '0640'
    - template: jinja
    - require:
      - file: test_directory

# Test vault access using the vault.read_secret execution module function
test_vault_read_secret:
  file.managed:
    - name: /tmp/vault_test/read_secret_test.txt
    - contents: |
        Vault Secret Test Results:
        {%- set success = False %}
        {%- set error_message = "No error details available" %}
        {%- set vault_config = salt['config.get']('vault', {}) %}
        {%- if vault_config %}
          {%- set success = True %}
          Vault is configured on this minion.
          Configuration:
          - Auth Method: {{ vault_config.get('auth', {}).get('method', 'Not specified') }}
          - Role ID: {{ vault_config.get('auth', {}).get('role_id', 'Not specified') }}
          - Config Location: {{ vault_config.get('config_location', 'Not specified') }}
          - Verify SSL: {{ vault_config.get('verify', 'Not specified') }}
          Attempting to read secret from Vault:
          {%- set test_path = 'secret/test/simple_kv' %}
          {%- if salt['cmd.retcode']('salt-call vault.read_secret ' + test_path + ' --out=txt', python_shell=True) == 0 %}
          Secret access successful!
          The minion can successfully read from the Vault path: {{ test_path }}
          {%- else %}
          Secret access failed.
          {%- endif %}
        {%- else %}
          Vault is not configured on this minion.
          Please check:
          1. The vault.conf file exists in /etc/salt/minion.d/
          2. The Salt minion has been restarted after configuration
          3. The Vault server is accessible from this minion
        {%- endif %}
        Minion ID: {{ grains['id'] }}
    - user: root
    - group: root
    - mode: '0640'
    - template: jinja
    - require:
      - file: test_directory

# Create a simple test file that doesn't depend on Vault
test_basic_file:
  file.managed:
    - name: /tmp/vault_test/basic_test.txt
    - contents: |
        This is a basic test file that doesn't depend on Vault.
        Minion ID: {{ grains['id'] }}
        OS: {{ grains['os'] }}
        Salt version: {{ grains['saltversion'] }}
    - user: root
    - group: root
    - mode: '0640'
    - template: jinja
    - require:
      - file: test_directory