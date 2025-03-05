# Install Vault server dependencies
install_vault_dependencies:
  pkg.installed:
    - pkgs:
      - curl
      - unzip
      - gnupg
      - software-properties-common

add_vault_repo_gpg:
  cmd.run:
    - name: curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
    - unless: apt-key list | grep -q "HashiCorp"

add_vault_repo:
  cmd.run:
    - name: apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    - unless: grep -q "hashicorp" /etc/apt/sources.list /etc/apt/sources.list.d/*

install_vault:
  pkg.installed:
    - name: vault
    - require:
      - cmd: add_vault_repo
      - cmd: add_vault_repo_gpg

setup_vault_dirs:
  file.directory:
    - names:
      - /etc/vault.d
      - /opt/vault/data
      - /opt/vault/tls
    - user: vault
    - group: vault
    - mode: 755
    - makedirs: True
    - require:
      - pkg: install_vault

{% if pillar.get('vault', {}).get('tls', {}).get('cert') %}
deploy_vault_cert:
  file.managed:
    - name: /opt/vault/tls/tls.crt
    - contents: |
        {{ pillar['vault']['tls']['cert'] | indent(8) }}
    - user: vault
    - group: vault
    - mode: 644
    - require:
      - file: setup_vault_dirs
    - show_changes: False

deploy_vault_key:
  file.managed:
    - name: /opt/vault/tls/tls.key
    - contents: |
        {{ pillar['vault']['tls']['key'] | indent(8) }}
    - user: vault
    - group: vault
    - mode: 600
    - require:
      - file: setup_vault_dirs
    - show_changes: False
{% endif %}

configure_vault:
  file.managed:
    - name: /etc/vault.d/vault.hcl
    - source: salt://vault/config.hcl
    - user: root
    - group: vault
    - mode: 640
    - require:
      - file: setup_vault_dirs

vault_service:
  service.running:
    - name: vault
    - enable: True
    # - watch:
    #   - file: configure_vault
    #   {% if pillar.get('vault', {}).get('tls', {}).get('cert') %}
    #   - file: deploy_vault_cert
    #   - file: deploy_vault_key
    #   {% endif %}
