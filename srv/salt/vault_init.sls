# Install Vault extension
vault_extension:
  pip.installed:
    - pkgs:
      - saltext-vault
    - reload_modules: true
    - upgrade: true

# Configure Vault for minion using AppRole auth
configure_vault_minion:
  file.managed:
    - name: /etc/salt/minion.d/vault.conf
    - contents: |
        vault:
          config_location: master
          verify: False
    - mode: '0640'
    - user: root
    - group: root
    - template: jinja
    - require:
      - pip: vault_extension

# Restart salt-minion service to apply Vault configuration
vault_init_minion_restart:
  service.running:
    - name: salt-minion
    - enable: True
    - watch:
      - file: configure_vault_minion
    - require:
      - pip: vault_extension

